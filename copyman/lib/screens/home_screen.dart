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
import '../services/hotkey_config_service.dart';
import '../services/hotkey_service.dart';
import '../services/sequence_service.dart';
import '../services/storage_service.dart';
import '../widgets/clipboard_item_tile.dart';
import '../widgets/group_filter_chips.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WindowListener {
  // ── focus & controllers ───────────────────────────────────────
  final FocusNode _searchFocus = FocusNode();
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  // ── services ──────────────────────────────────────────────────
  late final HotkeyService _hotkeyService;
  final ClipboardService _clipService = ClipboardService();
  StreamSubscription<int>? _clipSub;
  final _config = HotkeyConfigService.instance;

  // ── state ─────────────────────────────────────────────────────
  List<ClipboardItem> _allItems = [];
  List<FuzzyMatch> _matches = [];
  int _selectedIndex = 0;
  // ignore: unused_field
  bool _hotkeyOk = false;
  bool _hiding = false;
  bool _inSettings = false;

  // ── groups ────────────────────────────────────────────────────
  List<Group> _groups = [];
  int? _selectedGroupId;

  // ── multi-select & sequence ───────────────────────────────────
  List<bool> _itemSelected = [];
  final SequenceService _sequenceService = SequenceService();

  // ── preview overlay ───────────────────────────────────────────
  bool _previewVisible = false;
  OverlayEntry? _previewOverlay;

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
    _removePreviewOverlay();
    HardwareKeyboard.instance.removeHandler(_onKey);
    _clipSub?.cancel();
    _clipService.dispose();
    _hotkeyService.dispose();
    windowManager.removeListener(this);
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── keyboard ──────────────────────────────────────────────────

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (!_searchFocus.hasFocus) return false;

    // Ctrl+V while in sequence mode: Advance to next item
    if (_config.matches(AppAction.copyAndPaste, event) &&
        _sequenceService.isActive) {
      // Special: in sequence mode, Ctrl+V advances
      _advanceSequence();
      return true;
    }

    // Space key: toggle preview only if search is empty or cursor at end
    if (_config.matches(AppAction.togglePreview, event)) {
      final text = _searchCtrl.text;
      final sel = _searchCtrl.selection;
      if (text.isEmpty || (sel.isValid && sel.baseOffset >= text.length)) {
        _togglePreview();
        return true;
      }
      return false; // Let space type normally
    }

    if (_config.matches(AppAction.selectAll, event)) {
      setState(() {
        final allSelected = _itemSelected.every((x) => x);
        for (int i = 0; i < _itemSelected.length; i++) {
          _itemSelected[i] = !allSelected;
        }
      });
      return true;
    }

    if (_config.matches(AppAction.startSequence, event)) {
      _startSequence();
      return true;
    }

    if (_config.matches(AppAction.moveDown, event)) {
      _removePreviewOverlay();
      setState(() {
        if (_selectedIndex < _matches.length - 1) _selectedIndex++;
      });
      _scrollToSelected();
      return true;
    }

    if (_config.matches(AppAction.moveUp, event)) {
      _removePreviewOverlay();
      setState(() {
        if (_selectedIndex > 0) _selectedIndex--;
      });
      _scrollToSelected();
      return true;
    }

    if (_config.matches(AppAction.pastePlain, event)) {
      if (_selectedIndex >= 0 && _selectedIndex < _matches.length) {
        _pasteAsPlain(_matches[_selectedIndex].item);
      }
      return true;
    }

    if (_config.matches(AppAction.copyAndPaste, event)) {
      if (_selectedIndex >= 0 && _selectedIndex < _matches.length) {
        _copyAndPaste(_matches[_selectedIndex].item);
      }
      return true;
    }

    if (_config.matches(AppAction.copy, event)) {
      if (_selectedIndex >= 0 && _selectedIndex < _matches.length) {
        _copyItem(_matches[_selectedIndex].item);
      }
      return true;
    }

    if (_config.matches(AppAction.close, event)) {
      if (_previewVisible) {
        _removePreviewOverlay();
        return true;
      }
      if (_sequenceService.isActive) {
        setState(() => _sequenceService.cancel());
      } else {
        _hideWindow();
      }
      return true;
    }

    if (_config.matches(AppAction.togglePin, event)) {
      if (_selectedIndex >= 0 && _selectedIndex < _matches.length) {
        _togglePin(_matches[_selectedIndex].item);
      }
      return true;
    }

    if (_config.matches(AppAction.deleteItem, event)) {
      if (_selectedIndex >= 0 && _selectedIndex < _matches.length) {
        _deleteItem(_matches[_selectedIndex].item);
      }
      return true;
    }

    if (_config.matches(AppAction.openSettings, event)) {
      _openSettings();
      return true;
    }

    return false;
  }

  void _scrollToSelected() {
    // Approximate item height ~30px
    final targetOffset = _selectedIndex * 30.0;
    if (_scrollCtrl.hasClients) {
      final viewportHeight = _scrollCtrl.position.viewportDimension;
      final currentOffset = _scrollCtrl.offset;
      if (targetOffset < currentOffset) {
        _scrollCtrl.jumpTo(targetOffset);
      } else if (targetOffset > currentOffset + viewportHeight - 30) {
        _scrollCtrl.jumpTo(targetOffset - viewportHeight + 30);
      }
    }
  }

  // ── preview overlay ─────────────────────────────────────────

  void _togglePreview() {
    if (_previewVisible) {
      _removePreviewOverlay();
    } else {
      _showPreviewOverlay();
    }
  }

  void _showPreviewOverlay() {
    if (_matches.isEmpty || _selectedIndex >= _matches.length) return;
    _removePreviewOverlay();

    final item = _matches[_selectedIndex].item;
    final overlay = Overlay.of(context);

    _previewOverlay = OverlayEntry(
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Positioned(
          left: 40,
          right: 40,
          top: 100,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            color: theme.colorScheme.surface,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item.content.length} chars',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      Text(
                        item.relativeTime,
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(
                        item.content,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_previewOverlay!);
    setState(() => _previewVisible = true);
  }

  void _removePreviewOverlay() {
    _previewOverlay?.remove();
    _previewOverlay = null;
    if (_previewVisible && mounted) {
      setState(() => _previewVisible = false);
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
    await windowManager.show();

    if (Platform.isLinux) {
      await windowManager.setAlwaysOnTop(true);
      await Future.delayed(const Duration(milliseconds: 50));
      await windowManager.focus();
      await Future.delayed(const Duration(milliseconds: 50));
      await windowManager.setAlwaysOnTop(false);
    } else {
      await windowManager.focus();
    }

    _loadItems();

    await Future.delayed(const Duration(milliseconds: 30));
    _searchCtrl.clear();
    _searchFocus.unfocus();
    _searchFocus.requestFocus();
  }

  Future<void> _hideWindow() async {
    if (_hiding) return;
    _hiding = true;
    _removePreviewOverlay();
    _searchFocus.unfocus();
    _searchCtrl.clear();
    if (mounted) setState(() => _selectedIndex = 0);
    await windowManager.hide();
    _hiding = false;
  }

  @override
  Future<void> onWindowEvent(String eventName) async {
    if (eventName == 'blur' && !_inSettings) {
      _hideWindow();
    }
  }

  // ── data ──────────────────────────────────────────────────────

  Future<void> _loadGroups() async {
    final groups = await GroupService.instance.fetchAllGroups();
    if (mounted) {
      setState(() {
        _groups = groups;
      });
    }
  }

  Future<void> _loadItems() async {
    final q = _searchCtrl.text.trim();

    List<ClipboardItem> items;
    if (_selectedGroupId == null) {
      items = await StorageService.instance.fetchItems();
    } else {
      items = await GroupService.instance.fetchItemsInGroup(_selectedGroupId!);
    }

    if (mounted) {
      setState(() {
        _allItems = items;
        _matches = q.isEmpty
            ? items
                .map((item) =>
                    FuzzyMatch(item: item, score: 0, matchIndices: []))
                .toList()
            : FuzzySearch.search(q, items);
        if (_selectedIndex >= _matches.length) _selectedIndex = 0;
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
    await Future.delayed(const Duration(milliseconds: 80));
    try {
      if (Platform.isLinux) {
        await Process.run('xdotool', ['key', 'ctrl+v']);
      }
    } catch (_) {}
  }

  Future<void> _pasteAsPlain(ClipboardItem item) async {
    _clipService.setLastContent(item.content);
    await Clipboard.setData(ClipboardData(text: item.content));
    await _hideWindow();
    await Future.delayed(const Duration(milliseconds: 80));
    try {
      if (Platform.isLinux) {
        await Process.run('xdotool', ['key', 'ctrl+shift+v']);
      }
    } catch (_) {}
  }

  Future<void> _togglePin(ClipboardItem item) async {
    await StorageService.instance.togglePin(item.id);
    await _loadItems();
  }

  Future<void> _deleteItem(ClipboardItem item) async {
    await StorageService.instance.deleteItem(item.id);
    await _loadItems();
  }

  // ── groups ─────────────────────────────────────────────────────

  Future<void> _onGroupSelected(int? groupId) async {
    setState(() => _selectedGroupId = groupId);
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
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
    controller.dispose();
  }

  Future<void> _onGroupRenamed(Group group) async {
    try {
      await GroupService.instance.updateGroup(group.id, name: group.name);
      await _loadGroups();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _onGroupDeleted(Group group) async {
    try {
      await GroupService.instance.deleteGroup(group.id, moveToGroupId: 1);
      await _loadGroups();
      await _loadItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _onGroupColorChanged(Group group, String color) async {
    try {
      await GroupService.instance.updateGroup(group.id, color: color);
      await _loadGroups();
    } catch (_) {}
  }

  Future<void> _openSettings() async {
    _inSettings = true;
    await Navigator.pushNamed(context, '/settings');
    _inSettings = false;
    // Reload in case hotkey changed
    await _hotkeyService.reregister().then((ok) {
      if (mounted) setState(() => _hotkeyOk = ok);
    });
    _searchFocus.requestFocus();
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
      setState(() {});
    } else {
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
    final showChips = _groups.length > 1;
    final hasPinned = _matches.any((m) => m.item.pinned);

    // Split into pinned and unpinned
    final pinnedMatches = _matches.where((m) => m.item.pinned).toList();
    // unpinnedMatches used implicitly via _matches ordering

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── search bar ──────────────────────────────────────
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 18, color: theme.colorScheme.secondary),
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
                      hintText: 'Search clipboard...',
                      hintStyle: TextStyle(color: theme.colorScheme.secondary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      isDense: true,
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close, size: 14, color: theme.colorScheme.secondary),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _searchCtrl.clear(),
                            )
                          : null,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.settings_outlined, size: 16,
                      color: theme.colorScheme.secondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _openSettings,
                  tooltip: 'Settings',
                ),
              ],
            ),
          ),

          // ── group filter chips ──────────────────────────────
          if (showChips)
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(bottom: BorderSide(color: theme.dividerColor)),
              ),
              child: GroupFilterChips(
                groups: _groups,
                selectedGroupId: _selectedGroupId,
                onGroupSelected: _onGroupSelected,
                onNewGroup: _onGroupCreated,
                onGroupRenamed: _onGroupRenamed,
                onGroupDeleted: _onGroupDeleted,
                onGroupColorChanged: _onGroupColorChanged,
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
                    controller: _scrollCtrl,
                    itemCount: _matches.length + (hasPinned ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      // Insert divider between pinned and unpinned
                      if (hasPinned && i == pinnedMatches.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          child: Row(
                            children: List.generate(
                              20,
                              (_) => Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  height: 1,
                                  color: theme.dividerColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      final matchIdx = hasPinned && i > pinnedMatches.length
                          ? i - 1
                          : i;
                      if (matchIdx >= _matches.length) return const SizedBox();

                      final match = _matches[matchIdx];
                      final isInMultiSelectMode = _itemSelected.any((x) => x);

                      return GestureDetector(
                        onLongPress: () {
                          setState(() {
                            _itemSelected[matchIdx] = !_itemSelected[matchIdx];
                          });
                        },
                        child: ClipboardItemTile(
                          item: match.item,
                          isSelected: matchIdx == _selectedIndex,
                          matchIndices: match.matchIndices,
                          isMultiSelectMode: isInMultiSelectMode,
                          isCheckboxChecked: _itemSelected[matchIdx],
                          onCheckboxChanged: (checked) {
                            setState(() => _itemSelected[matchIdx] = checked);
                          },
                          onTap: () {
                            if (isInMultiSelectMode) {
                              setState(() => _itemSelected[matchIdx] = !_itemSelected[matchIdx]);
                            } else {
                              setState(() => _selectedIndex = matchIdx);
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

          // ── status bar ──────────────────────────────────────
          if (_allItems.isNotEmpty || _sequenceService.isActive)
            Container(
              height: 20,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_allItems.length} item${_allItems.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  if (_sequenceService.isActive)
                    Row(
                      children: [
                        Text(
                          'Seq ${_sequenceService.progress}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => setState(() => _sequenceService.cancel()),
                          child: Icon(Icons.close, size: 12,
                              color: theme.colorScheme.secondary),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
