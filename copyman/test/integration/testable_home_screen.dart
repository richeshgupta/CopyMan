/// A testable variant of HomeScreen that avoids window_manager / hotkey_manager
/// native plugin calls. It re-implements the same UI and keyboard handling
/// but skips register/unregister and window show/hide.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:copyman/models/clipboard_item.dart';
import 'package:copyman/models/group.dart';
import 'package:copyman/services/clipboard_service.dart';
import 'package:copyman/services/fuzzy_search.dart';
import 'package:copyman/services/group_service.dart';
import 'package:copyman/services/hotkey_config_service.dart';
import 'package:copyman/services/sequence_service.dart';
import 'package:copyman/services/storage_service.dart';
import 'package:copyman/widgets/clipboard_item_tile.dart';
import 'package:copyman/widgets/group_filter_chips.dart';
import 'package:copyman/widgets/shortcuts_help_overlay.dart';

/// Externally accessible state for testing.
class TestableHomeScreen extends StatefulWidget {
  const TestableHomeScreen({super.key});

  @override
  TestableHomeScreenState createState() => TestableHomeScreenState();
}

class TestableHomeScreenState extends State<TestableHomeScreen> {
  final FocusNode searchFocus = FocusNode();
  final TextEditingController searchCtrl = TextEditingController();
  final ScrollController scrollCtrl = ScrollController();

  final _config = HotkeyConfigService.instance;

  List<ClipboardItem> allItems = [];
  List<FuzzyMatch> matches = [];
  int selectedIndex = 0;
  bool inSettings = false;

  List<Group> groups = [];
  int? selectedGroupId;

  List<bool> itemSelected = [];
  final SequenceService sequenceService = SequenceService();

  bool previewVisible = false;
  OverlayEntry? previewOverlay;

  bool helpVisible = false;
  OverlayEntry? helpOverlay;

  @override
  void initState() {
    super.initState();
    searchCtrl.addListener(loadItems);
    HardwareKeyboard.instance.addHandler(_onKey);
    loadGroups();
    loadItems();
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    helpOverlay?.remove();
    helpOverlay = null;
    previewOverlay?.remove();
    previewOverlay = null;
    HardwareKeyboard.instance.removeHandler(_onKey);
    searchCtrl.removeListener(loadItems);
    searchCtrl.dispose();
    searchFocus.dispose();
    scrollCtrl.dispose();
    super.dispose();
  }

  // ── keyboard ──────────────────────────────────────────────────

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (!searchFocus.hasFocus) return false;

    // Shift+/ (?) toggles shortcuts help overlay
    if (event.logicalKey == LogicalKeyboardKey.slash &&
        HardwareKeyboard.instance.isShiftPressed &&
        !HardwareKeyboard.instance.isControlPressed &&
        !HardwareKeyboard.instance.isAltPressed &&
        searchCtrl.text.isEmpty) {
      _toggleHelpOverlay();
      return true;
    }

    if (_config.matches(AppAction.moveDown, event)) {
      _removePreviewOverlay();
      setState(() {
        if (selectedIndex < matches.length - 1) selectedIndex++;
      });
      return true;
    }

    if (_config.matches(AppAction.moveUp, event)) {
      _removePreviewOverlay();
      setState(() {
        if (selectedIndex > 0) selectedIndex--;
      });
      return true;
    }

    if (_config.matches(AppAction.togglePreview, event)) {
      final text = searchCtrl.text;
      final sel = searchCtrl.selection;
      if (text.isEmpty || (sel.isValid && sel.baseOffset >= text.length)) {
        _togglePreview();
        return true;
      }
      return false;
    }

    if (_config.matches(AppAction.copy, event)) {
      if (selectedIndex >= 0 && selectedIndex < matches.length) {
        _copyItem(matches[selectedIndex].item);
      }
      return true;
    }

    if (_config.matches(AppAction.deleteItem, event)) {
      if (selectedIndex >= 0 && selectedIndex < matches.length) {
        _deleteItem(matches[selectedIndex].item);
      }
      return true;
    }

    if (_config.matches(AppAction.togglePin, event)) {
      if (selectedIndex >= 0 && selectedIndex < matches.length) {
        _togglePin(matches[selectedIndex].item);
      }
      return true;
    }

    if (_config.matches(AppAction.selectAll, event)) {
      setState(() {
        final allSelected = itemSelected.every((x) => x);
        for (int i = 0; i < itemSelected.length; i++) {
          itemSelected[i] = !allSelected;
        }
      });
      return true;
    }

    if (_config.matches(AppAction.openSettings, event)) {
      _openSettings();
      return true;
    }

    if (_config.matches(AppAction.close, event)) {
      if (previewVisible) {
        _removePreviewOverlay();
        return true;
      }
      if (sequenceService.isActive) {
        setState(() => sequenceService.cancel());
      }
      return true;
    }

    return false;
  }

  // ── preview overlay ─────────────────────────────────────────

  void _togglePreview() {
    if (previewVisible) {
      _removePreviewOverlay();
    } else {
      _showPreviewOverlay();
    }
  }

  void _showPreviewOverlay() {
    if (matches.isEmpty || selectedIndex >= matches.length) return;
    _removePreviewOverlay();

    final item = matches[selectedIndex].item;
    final overlay = Overlay.of(context);

    previewOverlay = OverlayEntry(
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
              child: Text(
                item.content,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(previewOverlay!);
    setState(() => previewVisible = true);
  }

  void _removePreviewOverlay() {
    previewOverlay?.remove();
    previewOverlay = null;
    previewVisible = false;
    if (mounted) {
      setState(() {});
    }
  }

  // ── shortcuts help overlay ──────────────────────────────────

  void _toggleHelpOverlay() {
    if (helpVisible) {
      _removeHelpOverlay();
    } else {
      _showHelpOverlay();
    }
  }

  void _showHelpOverlay() {
    _removeHelpOverlay();
    final overlay = Overlay.of(context);

    helpOverlay = OverlayEntry(
      builder: (_) => ShortcutsHelpOverlay(onClose: _removeHelpOverlay),
    );

    overlay.insert(helpOverlay!);
    setState(() => helpVisible = true);
  }

  void _removeHelpOverlay() {
    helpOverlay?.remove();
    helpOverlay = null;
    helpVisible = false;
    if (mounted) {
      setState(() {});
    }
  }

  // ── data ──────────────────────────────────────────────────────

  Future<void> loadGroups() async {
    final g = await GroupService.instance.fetchAllGroups();
    if (mounted) {
      setState(() => groups = g);
    }
  }

  Future<void> loadItems() async {
    if (_disposed || !mounted) return;
    final q = searchCtrl.text.trim();

    List<ClipboardItem> items;
    if (selectedGroupId == null) {
      items = await StorageService.instance.fetchItems();
    } else {
      items = await GroupService.instance.fetchItemsInGroup(selectedGroupId!);
    }

    if (mounted) {
      setState(() {
        allItems = items;
        matches = q.isEmpty
            ? items
                .map((item) =>
                    FuzzyMatch(item: item, score: 0, matchIndices: []))
                .toList()
            : FuzzySearch.search(q, items);
        if (selectedIndex >= matches.length) selectedIndex = 0;
        itemSelected = List.filled(matches.length, false);
      });
    }
  }

  // ── actions ───────────────────────────────────────────────────

  Future<void> _copyItem(ClipboardItem item) async {
    await Clipboard.setData(ClipboardData(text: item.content));
  }

  Future<void> _togglePin(ClipboardItem item) async {
    await StorageService.instance.togglePin(item.id);
    await loadItems();
  }

  Future<void> _deleteItem(ClipboardItem item) async {
    await StorageService.instance.deleteItem(item.id);
    await loadItems();
  }

  Future<void> _openSettings() async {
    inSettings = true;
    await Navigator.pushNamed(context, '/settings');
    inSettings = false;
    searchFocus.requestFocus();
  }

  Future<void> onGroupSelected(int? groupId) async {
    setState(() => selectedGroupId = groupId);
    await loadItems();
  }

  Future<void> onGroupCreated() async {
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
      await GroupService.instance.createGroup(name);
      await loadGroups();
    }
    controller.dispose();
  }

  Future<void> onMoveToGroup(ClipboardItem item) async {
    final selectedGroup = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Move to Group'),
        children: groups
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
      await loadGroups();
      await loadItems();
    }
  }

  // ── build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showChips = groups.length > 1;
    final hasPinned = matches.any((m) => m.item.pinned);
    final pinnedMatches = matches.where((m) => m.item.pinned).toList();

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
                    focusNode: searchFocus,
                    controller: searchCtrl,
                    autofocus: true,
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
                      suffixIcon: searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close,
                                  size: 14, color: theme.colorScheme.secondary),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => searchCtrl.clear(),
                            )
                          : null,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.settings_outlined,
                      size: 16, color: theme.colorScheme.secondary),
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
                border:
                    Border(bottom: BorderSide(color: theme.dividerColor)),
              ),
              child: GroupFilterChips(
                groups: groups,
                selectedGroupId: selectedGroupId,
                onGroupSelected: onGroupSelected,
                onNewGroup: onGroupCreated,
                onGroupRenamed: (_) {},
                onGroupDeleted: (_) {},
                onGroupColorChanged: (_, __) {},
              ),
            ),

          // ── item list ───────────────────────────────────────
          Expanded(
            child: matches.isEmpty
                ? Center(
                    child: Text(
                      searchCtrl.text.isEmpty
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
                    controller: scrollCtrl,
                    itemCount: matches.length + (hasPinned ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (hasPinned && i == pinnedMatches.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 2),
                          child: Row(
                            children: List.generate(
                              20,
                              (_) => Expanded(
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 1),
                                  height: 1,
                                  color: theme.dividerColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      final matchIdx =
                          hasPinned && i > pinnedMatches.length ? i - 1 : i;
                      if (matchIdx >= matches.length) return const SizedBox();

                      final match = matches[matchIdx];
                      final isInMultiSelectMode = itemSelected.any((x) => x);

                      return ClipboardItemTile(
                        item: match.item,
                        isSelected: matchIdx == selectedIndex,
                        matchIndices: match.matchIndices,
                        isMultiSelectMode: isInMultiSelectMode,
                        isCheckboxChecked: itemSelected[matchIdx],
                        onCheckboxChanged: (checked) {
                          setState(() => itemSelected[matchIdx] = checked);
                        },
                        onTap: () {
                          if (isInMultiSelectMode) {
                            setState(() =>
                                itemSelected[matchIdx] = !itemSelected[matchIdx]);
                          } else {
                            setState(() => selectedIndex = matchIdx);
                            _copyItem(match.item);
                          }
                        },
                        onDoubleTap: () => _copyItem(match.item),
                        onPin: () => _togglePin(match.item),
                        onDelete: () => _deleteItem(match.item),
                        onPasteAsPlain: () {},
                        onMoveToGroup: onMoveToGroup,
                      );
                    },
                  ),
          ),

          // ── status bar ──────────────────────────────────────
          if (allItems.isNotEmpty || sequenceService.isActive)
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
                    '${allItems.length} item${allItems.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
