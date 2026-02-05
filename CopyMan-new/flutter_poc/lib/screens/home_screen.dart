import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../models/clipboard_item.dart';
import '../services/clipboard_service.dart';
import '../services/fuzzy_search.dart';
import '../services/hotkey_service.dart';
import '../services/storage_service.dart';
import '../widgets/clipboard_item_tile.dart';

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
          final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
          final isControlPressed = HardwareKeyboard.instance.isControlPressed;
          if (isControlPressed && isShiftPressed) {
            _pasteAsPlain(_matches[_selectedIndex].item);
          } else if (isControlPressed) {
            _copyAndPaste(_matches[_selectedIndex].item);
          } else {
            _copyItem(_matches[_selectedIndex].item);
          }
        }
        return true;

      case LogicalKeyboardKey.escape:
        _hideWindow();
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

  Future<void> _loadItems() async {
    final q = _searchCtrl.text.trim();
    // Always fetch all items for fuzzy search
    final items = await StorageService.instance.fetchItems();
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

  // ── build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pinnedCount = _allItems.where((i) => i.pinned).length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── search bar ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
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

          // ── info strip ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            color: theme.colorScheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_allItems.length} item${_allItems.length != 1 ? 's' : ''}'
                  '${pinnedCount > 0 ? ' · $pinnedCount pinned' : ''}',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                if (!_hotkeyOk)
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
                      return ClipboardItemTile(
                        item: match.item,
                        isSelected: i == _selectedIndex,
                        matchIndices: match.matchIndices,
                        onTap: () {
                          setState(() => _selectedIndex = i);
                          _copyItem(match.item);
                        },
                        onDoubleTap: () => _copyAndPaste(match.item),
                        onPin: () => _togglePin(match.item),
                        onDelete: () => _deleteItem(match.item),
                        onPasteAsPlain: () => _pasteAsPlain(match.item),
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
        ],
      ),
    );
  }
}
