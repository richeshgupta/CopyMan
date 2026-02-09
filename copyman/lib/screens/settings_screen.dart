import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show ConflictAlgorithm;

import '../services/app_detection_service.dart';
import '../services/hotkey_config_service.dart';
import '../services/hotkey_service.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  final String currentThemeMode;
  final ValueChanged<String> onThemeModeChanged;
  final HotkeyService? hotkeyService;

  const SettingsScreen({
    super.key,
    required this.currentThemeMode,
    required this.onThemeModeChanged,
    this.hotkeyService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // History
  int _historyLimit = 500;

  // TTL
  bool _ttlEnabled = false;
  int _ttlHours = 72;

  // Exclusions
  List<Map<String, dynamic>> _exclusions = [];
  final _newAppCtrl = TextEditingController();
  String? _foregroundApp;
  bool _autoExcludeSensitive = false;
  bool _skipImages = false;
  bool _skipLargeImages = false;
  double _maxImageSizeMB = 5.0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _newAppCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final storage = StorageService.instance;
    final limit = await storage.getHistoryLimit();
    final ttlEnabled = await storage.getSetting('ttl_enabled');
    final ttlHours = await storage.getSetting('ttl_hours');
    final exclusions = await storage.fetchExclusions();
    final fg = await AppDetectionService.getForegroundApp();
    final autoExcl = await storage.getSetting('auto_exclude_sensitive');
    final skipImg = await storage.getSetting('skip_images');
    final skipLargeImg = await storage.getSetting('skip_large_images');
    final maxImgSize = await storage.getSetting('max_image_size_mb');

    if (mounted) {
      setState(() {
        _historyLimit = limit;
        _ttlEnabled = ttlEnabled == 'true';
        _ttlHours = int.tryParse(ttlHours ?? '') ?? 72;
        _exclusions = exclusions;
        _foregroundApp = fg;
        _autoExcludeSensitive = autoExcl == 'true';
        _skipImages = skipImg == 'true';
        _skipLargeImages = skipLargeImg == 'true';
        _maxImageSizeMB = double.tryParse(maxImgSize ?? '') ?? 5.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings', style: TextStyle(fontSize: 16)),
        titleSpacing: 0,
        toolbarHeight: 44,
        bottom: TabBar(
          controller: _tabCtrl,
          labelStyle: const TextStyle(fontSize: 12),
          tabs: const [
            Tab(text: 'General'),
            Tab(text: 'Auto-Clear'),
            Tab(text: 'Exclusions'),
            Tab(text: 'Shortcuts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildGeneralTab(theme),
          _buildTtlTab(theme),
          _buildExclusionsTab(theme),
          _buildShortcutsTab(theme),
        ],
      ),
    );
  }

  // ── General tab ──────────────────────────────────────────────

  Widget _buildGeneralTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('History limit', style: theme.textTheme.bodySmall),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _historyLimit.toDouble(),
                min: 50,
                max: 2000,
                divisions: 39,
                label: '$_historyLimit',
                onChanged: (v) => setState(() => _historyLimit = v.round()),
                onChangeEnd: (v) {
                  StorageService.instance.setHistoryLimit(v.round());
                },
              ),
            ),
            SizedBox(
              width: 48,
              child: Text('$_historyLimit',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Theme', style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'system', label: Text('System')),
            ButtonSegment(value: 'light', label: Text('Light')),
            ButtonSegment(value: 'dark', label: Text('Dark')),
          ],
          selected: {widget.currentThemeMode},
          onSelectionChanged: (s) {
            widget.onThemeModeChanged(s.first);
          },
        ),
      ],
    );
  }

  // ── TTL tab ──────────────────────────────────────────────────

  Widget _buildTtlTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Auto-clear old items'),
          subtitle: const Text('Delete non-pinned items after a time limit'),
          value: _ttlEnabled,
          onChanged: (v) {
            setState(() => _ttlEnabled = v);
            StorageService.instance.setSetting('ttl_enabled', v.toString());
          },
        ),
        if (_ttlEnabled) ...[
          const SizedBox(height: 12),
          Text('Delete items older than $_ttlHours hours',
              style: theme.textTheme.bodySmall),
          Slider(
            value: _ttlHours.toDouble(),
            min: 1,
            max: 720,
            divisions: 719,
            label: _ttlHours <= 48
                ? '$_ttlHours h'
                : '${(_ttlHours / 24).toStringAsFixed(0)} days',
            onChanged: (v) => setState(() => _ttlHours = v.round()),
            onChangeEnd: (v) {
              StorageService.instance
                  .setSetting('ttl_hours', v.round().toString());
            },
          ),
          Text(
            _ttlHours <= 48
                ? '$_ttlHours hours'
                : '${(_ttlHours / 24).toStringAsFixed(1)} days',
            style: TextStyle(fontSize: 12, color: theme.colorScheme.secondary),
          ),
        ],
      ],
    );
  }

  // ── Exclusions tab ─────────────────────────────────────────

  Widget _buildExclusionsTab(ThemeData theme) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Auto-exclude sensitive content'),
          subtitle: const Text('Skip passwords, API keys, tokens, etc.'),
          value: _autoExcludeSensitive,
          onChanged: (v) {
            setState(() => _autoExcludeSensitive = v);
            StorageService.instance
                .setSetting('auto_exclude_sensitive', v.toString());
          },
        ),
        const Divider(height: 1),
        SwitchListTile(
          title: const Text('Skip all images'),
          subtitle: const Text('Do not capture image clipboard content'),
          value: _skipImages,
          onChanged: (v) {
            setState(() => _skipImages = v);
            StorageService.instance.setSetting('skip_images', v.toString());
          },
        ),
        if (!_skipImages) ...[
          SwitchListTile(
            title: const Text('Skip large images'),
            subtitle: Text(
                'Skip images larger than ${_maxImageSizeMB.toStringAsFixed(1)} MB'),
            value: _skipLargeImages,
            onChanged: (v) {
              setState(() => _skipLargeImages = v);
              StorageService.instance
                  .setSetting('skip_large_images', v.toString());
            },
          ),
          if (_skipLargeImages)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Max size:', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: _maxImageSizeMB,
                      min: 0.5,
                      max: 20.0,
                      divisions: 39,
                      label: '${_maxImageSizeMB.toStringAsFixed(1)} MB',
                      onChanged: (v) =>
                          setState(() => _maxImageSizeMB = v),
                      onChangeEnd: (v) {
                        StorageService.instance.setSetting(
                            'max_image_size_mb', v.toStringAsFixed(1));
                      },
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text('${_maxImageSizeMB.toStringAsFixed(1)} MB',
                        style: const TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
        ],
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newAppCtrl,
                  decoration: InputDecoration(
                    hintText: 'App class name',
                    helperText: _foregroundApp != null
                        ? 'Current app: $_foregroundApp'
                        : null,
                    isDense: true,
                    border: const OutlineInputBorder(),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () async {
                  final name = _newAppCtrl.text.trim();
                  if (name.isEmpty) return;
                  await StorageService.instance.setExclusion(name, true);
                  _newAppCtrl.clear();
                  await _loadSettings();
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _exclusions.isEmpty
              ? Center(
                  child: Text('No exclusions',
                      style: TextStyle(
                          color: theme.colorScheme.secondary, fontSize: 13)))
              : ListView.builder(
                  itemCount: _exclusions.length,
                  itemBuilder: (ctx, i) {
                    final excl = _exclusions[i];
                    final name = excl['app_name'] as String;
                    final blocked = (excl['blocked'] as int) == 1;
                    return ListTile(
                      dense: true,
                      title: Text(name, style: const TextStyle(fontSize: 13)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: blocked,
                            onChanged: (v) async {
                              if (v) {
                                await StorageService.instance
                                    .setExclusion(name, true);
                              } else {
                                await StorageService.instance
                                    .setExclusion(name, false);
                                await StorageService.instance.db.insert(
                                  'app_exclusions',
                                  {'app_name': name, 'blocked': 0},
                                  conflictAlgorithm: ConflictAlgorithm.replace,
                                );
                              }
                              await _loadSettings();
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline,
                                size: 16, color: theme.colorScheme.error),
                            onPressed: () async {
                              await StorageService.instance
                                  .setExclusion(name, false);
                              await _loadSettings();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── Shortcuts tab ──────────────────────────────────────────

  Widget _buildShortcutsTab(ThemeData theme) {
    final config = HotkeyConfigService.instance;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: AppAction.values.map((action) {
              final binding = config.getBinding(action);
              return ListTile(
                dense: true,
                title: Text(
                  HotkeyConfigService.actionDisplayName(action),
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Text(
                        binding.describe(),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        padding: EdgeInsets.zero,
                        onPressed: () => _editShortcut(action),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextButton(
            onPressed: () async {
              await config.resetAllToDefaults();
              if (widget.hotkeyService != null) {
                await widget.hotkeyService!.reregister();
              }
              setState(() {});
            },
            child: const Text('Reset All to Defaults'),
          ),
        ),
      ],
    );
  }

  Future<void> _editShortcut(AppAction action) async {
    final config = HotkeyConfigService.instance;

    final result = await showDialog<HotkeyBinding>(
      context: context,
      builder: (ctx) => _ShortcutCaptureDialog(
        actionName: HotkeyConfigService.actionDisplayName(action),
        currentBinding: config.getBinding(action),
      ),
    );

    if (result != null) {
      final conflict = config.findConflict(action, result);
      if (conflict != null && mounted) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Shortcut Conflict'),
            content: Text(
              '"${result.describe()}" is already used by '
              '"${HotkeyConfigService.actionDisplayName(conflict)}".\n\n'
              'Overwrite?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Overwrite'),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }

      await config.setBinding(action, result);
      if (action == AppAction.toggleWindow && widget.hotkeyService != null) {
        await widget.hotkeyService!.reregister();
      }
      setState(() {});
    }
  }
}

class _ShortcutCaptureDialog extends StatefulWidget {
  final String actionName;
  final HotkeyBinding currentBinding;

  const _ShortcutCaptureDialog({
    required this.actionName,
    required this.currentBinding,
  });

  @override
  State<_ShortcutCaptureDialog> createState() => _ShortcutCaptureDialogState();
}

class _ShortcutCaptureDialogState extends State<_ShortcutCaptureDialog> {
  HotkeyBinding? _captured;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool _isModifierKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight ||
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('Edit: ${widget.actionName}',
          style: const TextStyle(fontSize: 15)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Current: ${widget.currentBinding.describe()}',
            style: TextStyle(fontSize: 12, color: theme.colorScheme.secondary),
          ),
          const SizedBox(height: 16),
          KeyboardListener(
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: (event) {
              if (event is! KeyDownEvent) return;
              if (_isModifierKey(event.logicalKey)) return;

              setState(() {
                _captured = HotkeyBinding(
                  key: event.logicalKey,
                  ctrl: HardwareKeyboard.instance.isControlPressed,
                  shift: HardwareKeyboard.instance.isShiftPressed,
                  alt: HardwareKeyboard.instance.isAltPressed,
                );
              });
            },
            child: Container(
              width: 200,
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.primary),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                _captured?.describe() ?? 'Press a key combo...',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                  color: _captured != null
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.secondary,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _captured != null
              ? () => Navigator.pop(context, _captured)
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
