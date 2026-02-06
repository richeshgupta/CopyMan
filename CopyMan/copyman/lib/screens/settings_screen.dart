import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show ConflictAlgorithm;

import '../services/app_detection_service.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  final String currentThemeMode; // 'system', 'light', 'dark'
  final ValueChanged<String> onThemeModeChanged;

  const SettingsScreen({
    super.key,
    required this.currentThemeMode,
    required this.onThemeModeChanged,
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

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
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

    if (mounted) {
      setState(() {
        _historyLimit = limit;
        _ttlEnabled = ttlEnabled == 'true';
        _ttlHours = int.tryParse(ttlHours ?? '') ?? 72;
        _exclusions = exclusions;
        _foregroundApp = fg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 420,
        height: 460,
        child: Column(
          children: [
            // Title bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Text('Settings',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabCtrl,
              labelStyle: const TextStyle(fontSize: 13),
              tabs: const [
                Tab(text: 'General'),
                Tab(text: 'Auto-Clear'),
                Tab(text: 'Exclusions'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildGeneralTab(theme),
                  _buildTtlTab(theme),
                  _buildExclusionsTab(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── General tab ──────────────────────────────────────────────

  Widget _buildGeneralTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // History size
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

        // Theme selector
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

  // ── Exclusions tab ───────────────────────────────────────────

  Widget _buildExclusionsTab(ThemeData theme) {
    return Column(
      children: [
        // Add new exclusion
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
        // List
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
                                // Re-add as unblocked for toggle
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
}
