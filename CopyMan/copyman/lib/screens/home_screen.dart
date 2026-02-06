import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../models/clipboard_item.dart';
import '../models/group.dart';
import '../services/clipboard_service.dart';
import '../services/fuzzy_search.dart';
import '../services/group_service.dart';
import '../services/hotkey_service.dart';
import '../services/sequence_service.dart';
import '../services/storage_service.dart';
import '../app.dart';
import '../screens/settings_screen.dart';
import '../widgets/clipboard_item_tile.dart';
import '../widgets/groups_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WindowListener {
  // ── focus & controllers ───────────────────────────────────────
  final FocusNode _searchFocus = FocusNode();
  final TextEditingController _searchCtrl = TextEditingController();

  // ── services ──────────────────────────────────────────────────
  late final HotkeyService _hotkeyService;
  final ClipboardService _clipService = ClipboardService();
  StreamSubscription<int>? _clipSub;

  // ── state ─────────────────────────────────────────────────────
  List<ClipboardItem> _allItems = [];
  List<FuzzyMatch> _matches = [];
  int _selectedIndex = 0;
  bool _hotkeyOk = false;
  bool _hiding = false; // guard against re-entrant hide calls

  // ── groups ────────────────────────────────────────────────────
  List<Group> _groups = [];
  int? _selectedGroupId; // null = "All Items"
  Map<int, int> _groupCounts = {}; // group id -> item count
  bool _sidebarVisible = true; // collapsible sidebar

  // ── multi-select & sequence ───────────────────────────────────
  List<bool> _itemSelected = []; // Track which items are selected
  final SequenceService _sequenceService = SequenceService();

  @override
  void initState() {
    super.initState();

    _hotkeyService = HotkeyService(onPressed: _toggleWindow);
    _hotkeyService.register().then((ok) {
      if (mounted) setState(() => _hotkeyOk = ok);
    });

    windowManager.addListener(this);

    _clipService.startMonitoring();
    _clipSub = _clipService.onNewItem.stream.listen((_) {
      if (mounted) _loadItems();
    });

    _searchCtrl.addListener(_loadItems);
    HardwareKeyboard.instance.addHandler(_onKey);

    _loadGroups();
    _loadItems();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _clipSub?.cancel();
    _clipService.dispose();
    _hotkeyService.dispose();
    windowManager.removeListener(this);
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── keyboard ──────────────────────────────────────────────────

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (!_searchFocus.hasFocus) return false;

    final isCtrl = HardwareKeyboard.instance.isControlPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    // Ctrl+A: Toggle select all
    if (event.logicalKey == LogicalKeyboardKey.keyA && isCtrl && !isShift) {
      setState(() {
        final allSelected = _itemSelected.every((x) => x);
        for (int i = 0; i < _itemSelected.length; i++) {
          _itemSelected[i] = !allSelected;
        }
      });
      return true;
    }

    // Ctrl+Shift+S: Start sequence
    if (event.logicalKey == LogicalKeyboardKey.keyS && isCtrl && isShift) {
      _startSequence();
      return true;
    }

    // Ctrl+V while in sequence mode: Advance to next item
    if (event.logicalKey == LogicalKeyboardKey.keyV &&
        isCtrl &&
        _sequenceService.isActive) {
      _advanceSequence();
      return true;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        setState(() {
          if (_selectedIndex < _matches.length - 1) _selectedIndex++;
        });
        return true;

      case LogicalKeyboardKey.arrowUp:
        setState(() {
          if (_selectedIndex > 0) _selectedIndex--;
        });
        return true;

      case LogicalKeyboardKey.enter:
        if (_selectedIndex >= 0 && _selectedIndex < _matches.length) {
          if (isCtrl && isShift) {
            _pasteAsPlain(_matches[_selectedIndex].item);
          } else if (isCtrl) {
            _copyAndPaste(_matches[_selectedIndex].item);
          } else {
            _copyItem(_matches[_selectedIndex].item);
          }
        }
        return true;

      case LogicalKeyboardKey.escape:
        if (_sequenceService.isActive) {
          setState(() => _sequenceService.cancel());
        } else {
          _hideWindow();
        }
        return true;

      default:
        return false;
    }
  }

  // ── window show / hide ────────────────────────────────────────

  Future<void> _toggleWindow() async {
    final visible = await windowManager.isVisible();
    if (visible) {
      _hideWindow();
    } else {
      _showWindow();
    }
  }

  Future<void> _showWindow() async {
    // Show window
    await windowManager.show();

    // X11-specific: Force window to front using always-on-top toggle
    // This bypasses many WM focus policies more reliably than direct focus calls
    if (Platform.isLinux) {
      await windowManager.setAlwaysOnTop(true);
      await Future.delayed(const Duration(milliseconds: 50));
      await windowManager.focus();
      await Future.delayed(const Duration(milliseconds: 50));
      // Release always-on-top after gaining focus
      await windowManager.setAlwaysOnTop(false);
    } else {
      // macOS / Windows
      await windowManager.focus();
    }

    // Load clipboard history
    _loadItems();

    // Focus the search field for keyboard input
    await Future.delayed(const Duration(milliseconds: 30));
    _searchCtrl.clear();
    _searchFocus.unfocus();
    _searchFocus.requestFocus();
  }

  Future<void> _hideWindow() async {
    if (_hiding) return;
    _hiding = true;
    _searchFocus.unfocus();
    _searchCtrl.clear();
    if (mounted) setState(() => _selectedIndex = 0);
    await windowManager.hide();
    _hiding = false;
  }

  @override
  Future<void> onWindowEvent(String eventName) async {
    if (eventName == 'blur') {
      _hideWindow();
    }
  }

  // ── data ──────────────────────────────────────────────────────

  Future<void> _loadGroups() async {
    final groups = await GroupService.instance.fetchAllGroups();
    final counts = <int, int>{};
    for (final group in groups) {
      counts[group.id] = await GroupService.instance.getGroupItemCount(group.id);
    }

    if (mounted) {
      setState(() {
        _groups = groups;
        _groupCounts = counts;
        _itemSelected = List.filled(_matches.length, false);
      });
    }
  }

  Future<void> _loadItems() async {
    final q = _searchCtrl.text.trim();

    // Fetch items: all if no group selected, or specific group
    List<ClipboardItem> items;
    if (_selectedGroupId == null) {
      // All items
      items = await StorageService.instance.fetchItems();
    } else {
      // Items in selected group
      items = await GroupService.instance.fetchItemsInGroup(_selectedGroupId!);
    }

    if (mounted) {
      setState(() {
        _allItems = items;
        // Apply fuzzy search
        _matches = q.isEmpty
            ? items
                .map((item) =>
                    FuzzyMatch(item: item, score: 0, matchIndices: []))
                .toList()
            : FuzzySearch.search(q, items);
        if (_selectedIndex >= _matches.length) _selectedIndex = 0;
        // Reset multi-select on reload
        _itemSelected = List.filled(_matches.length, false);
      });
    }
  }

  // ── actions ───────────────────────────────────────────────────

  Future<void> _copyItem(ClipboardItem item) async {
    _clipService.setLastContent(item.content);
    await Clipboard.setData(ClipboardData(text: item.content));
    _hideWindow();
  }

  Future<void> _copyAndPaste(ClipboardItem item) async {
    _clipService.setLastContent(item.content);
    await Clipboard.setData(ClipboardData(text: item.content));
    await _hideWindow();
    // Give the OS a moment to restore focus to the previous window.
    await Future.delayed(const Duration(milliseconds: 80));
    try {
      if (Platform.isLinux) {
        await Process.run('xdotool', ['key', 'ctrl+v']);
      }
      // Windows / macOS paste simulation — TODO
    } catch (_) {
      // xdotool not available; clipboard is set, user can Ctrl+V manually.
    }
  }

  Future<void> _pasteAsPlain(ClipboardItem item) async {
    _clipService.setLastContent(item.content);
    await Clipboard.setData(ClipboardData(text: item.content));
    await _hideWindow();
    // Give the OS a moment to restore focus to the previous window.
    await Future.delayed(const Duration(milliseconds: 80));
    try {
      if (Platform.isLinux) {
        await Process.run('xdotool', ['key', 'ctrl+shift+v']);
      }
      // Windows / macOS paste simulation — TODO
    } catch (_) {
      // xdotool not available; clipboard is set, user can Ctrl+V manually.
    }
  }

  Future<void> _togglePin(ClipboardItem item) async {
    await StorageService.instance.togglePin(item.id);
    await _loadItems();
  }

  Future<void> _deleteItem(ClipboardItem item) async {
    await StorageService.instance.deleteItem(item.id);
    await _loadItems();
  }

  Future<void> _deleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all history?'),
        content: const Text(
            'This permanently removes every item, including pinned ones.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await StorageService.instance.deleteAll();
      _loadItems();
    }
  }

  // ── groups ─────────────────────────────────────────────────────

  Future<void> _onGroupSelected(int? groupId) async {
    setState(() {
      _selectedGroupId = groupId;
    });
    await _loadItems();
  }

  Future<void> _onGroupCreated() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Group'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Group name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      try {
        await GroupService.instance.createGroup(name);
        await _loadGroups();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group created: $name')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
    controller.dispose();
  }

  Future<void> _onGroupRenamed(Group group) async {
    try {
      await GroupService.instance.updateGroup(group.id, name: group.name);
      await _loadGroups();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Group renamed: ${group.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _onGroupDeleted(Group group) async {
    try {
      await GroupService.instance.deleteGroup(group.id, moveToGroupId: 1);
      await _loadGroups();
      await _loadItems();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Group deleted: ${group.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _onGroupColorChanged(Group group, String color) async {
    try {
      await GroupService.instance.updateGroup(group.id, color: color);
      await _loadGroups();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _openSettings() async {
    final appState = context.findAncestorStateOfType<CopyManAppState>();
    await showDialog(
      context: context,
      builder: (ctx) => SettingsScreen(
        currentThemeMode: appState?.themeModeString ?? 'system',
        onThemeModeChanged: (mode) {
          appState?.setThemeMode(mode);
        },
      ),
    );
  }

  Future<void> _onMoveToGroup(ClipboardItem item) async {
    final selectedGroup = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Move to Group'),
        children: _groups
            .map(
              (group) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, group.id),
                child: Text(group.name),
              ),
            )
            .toList(),
      ),
    );

    if (selectedGroup != null) {
      await GroupService.instance.moveItemToGroup(item.id, selectedGroup);
      await _loadGroups();
      await _loadItems();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item moved')),
      );
    }
  }

  // ── multi-select & sequence ────────────────────────────────────

  Future<void> _startSequence() async {
    final selectedItems = <ClipboardItem>[];
    for (int i = 0; i < _matches.length; i++) {
      if (_itemSelected[i]) {
        selectedItems.add(_matches[i].item);
      }
    }

    if (selectedItems.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least 2 items to start sequence'),
        ),
      );
      return;
    }

    setState(() {
      _sequenceService.startSequence(selectedItems);
      _itemSelected = List.filled(_matches.length, false);
      // Set clipboard to first item
      _clipService.setLastContent(selectedItems[0].content);
      Clipboard.setData(ClipboardData(text: selectedItems[0].content));
    });
  }

  Future<void> _advanceSequence() async {
    _sequenceService.advance();

    final item = _sequenceService.getCurrentItem();
    if (item != null) {
      _clipService.setLastContent(item.content);
      await Clipboard.setData(ClipboardData(text: item.content));
      setState(() {}); // Refresh UI to show new progress
    } else {
      // Sequence complete
      setState(() => _sequenceService.cancel());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sequence complete')),
        );
      }
    }
  }

  // ── build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pinnedCount = _allItems.where((i) => i.pinned).length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          // ── groups sidebar (collapsible) ─────────────────────
          if (_sidebarVisible && _groups.isNotEmpty)
            SizedBox(
              width: 140,
              child: GroupsPanel(
                groups: _groups,
                selectedGroupId: _selectedGroupId,
                onGroupSelected: _onGroupSelected,
                onNewGroup: _onGroupCreated,
                onGroupRenamed: _onGroupRenamed,
                onGroupDeleted: _onGroupDeleted,
                onGroupColorChanged: _onGroupColorChanged,
                groupCounts: _groupCounts,
              ),
            ),

          // ── main content ────────────────────────────────────
          Expanded(
            child: Column(
              children: [
          // ── search bar + sidebar toggle ─────────────────────
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                if (_groups.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      _sidebarVisible ? Icons.menu_open : Icons.menu,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => _sidebarVisible = !_sidebarVisible),
                    tooltip: 'Toggle sidebar',
                  ),
                IconButton(
                  icon: Icon(Icons.settings_outlined, size: 18,
                      color: theme.colorScheme.secondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _openSettings,
                  tooltip: 'Settings',
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
              focusNode: _searchFocus,
              controller: _searchCtrl,
              autofocus: false,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search clipboard…',
                hintStyle: TextStyle(color: theme.colorScheme.secondary),
                prefixIcon:
                    Icon(Icons.search, size: 18, color: theme.colorScheme.secondary),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, size: 16, color: theme.colorScheme.secondary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _searchCtrl.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
                  ),
                ),
              ],
            ),
          ),

          // ── sequence mode indicator (if active) ────────────
          if (_sequenceService.isActive)
            Container(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sequence Mode: ${_sequenceService.progress}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() => _sequenceService.cancel());
                    },
                  ),
                ],
              ),
            ),

          // ── info & multi-select strip ──────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            color: theme.colorScheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _itemSelected.any((x) => x)
                        ? '${_itemSelected.where((x) => x).length} selected'
                        : '${_allItems.length} item${_allItems.length != 1 ? 's' : ''}'
                            '${pinnedCount > 0 ? ' · $pinnedCount pinned' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
                if (_itemSelected.any((x) => x) && !_sequenceService.isActive)
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _startSequence,
                        icon: const Icon(Icons.repeat, size: 14),
                        label: const Text('Sequence'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _itemSelected = List.filled(_matches.length, false);
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Clear'),
                      ),
                    ],
                  )
                else if (!_hotkeyOk)
                  Text(
                    'Hotkey not registered',
                    style:
                        TextStyle(fontSize: 11, color: theme.colorScheme.error),
                  ),
              ],
            ),
          ),

          // ── item list ───────────────────────────────────────
          Expanded(
            child: _matches.isEmpty
                ? Center(
                    child: Text(
                      _searchCtrl.text.isEmpty
                          ? 'Clipboard history is empty.\nCopy something to get started.'
                          : 'No matches.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontSize: 13,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _matches.length,
                    itemBuilder: (ctx, i) {
                      final match = _matches[i];
                      final isInMultiSelectMode = _itemSelected.any((x) => x);

                      // Multi-select via Ctrl+Click
                      return GestureDetector(
                        onLongPress: () {
                          setState(() {
                            _itemSelected[i] = !_itemSelected[i];
                          });
                        },
                        child: ClipboardItemTile(
                          item: match.item,
                          isSelected: i == _selectedIndex,
                          matchIndices: match.matchIndices,
                          isMultiSelectMode: isInMultiSelectMode,
                          isCheckboxChecked: _itemSelected[i],
                          onCheckboxChanged: (checked) {
                            setState(() => _itemSelected[i] = checked);
                          },
                          onTap: () {
                            if (isInMultiSelectMode) {
                              setState(() => _itemSelected[i] = !_itemSelected[i]);
                            } else {
                              setState(() => _selectedIndex = i);
                              _copyItem(match.item);
                            }
                          },
                          onDoubleTap: () => _copyAndPaste(match.item),
                          onPin: () => _togglePin(match.item),
                          onDelete: () => _deleteItem(match.item),
                          onPasteAsPlain: () => _pasteAsPlain(match.item),
                          onMoveToGroup: _onMoveToGroup,
                        ),
                      );
                    },
                  ),
          ),

          // ── preview pane ─────────────────────────────────────
          if (_matches.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              constraints: const BoxConstraints(maxHeight: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text(
                      'Preview',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Text(
                          _matches[_selectedIndex].item.content,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── bottom bar ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Enter copy · Ctrl+Shift+Enter plain · Ctrl+Enter paste · Esc close',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 16,
                      color: theme.colorScheme.secondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _deleteAll,
                  tooltip: 'Clear all',
                ),
              ],
            ),
          ),
              ], // Close children list of Column
            ), // Close Column
          ), // Close Expanded (main content)
        ],
      ),
    );
  }
}
