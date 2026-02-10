import 'package:flutter/material.dart';

import '../services/hotkey_config_service.dart';

class ShortcutsHelpOverlay extends StatelessWidget {
  final VoidCallback onClose;

  const ShortcutsHelpOverlay({super.key, required this.onClose});

  static const _categories = {
    'Global': [AppAction.toggleWindow],
    'Navigation': [AppAction.moveUp, AppAction.moveDown, AppAction.togglePreview],
    'Actions': [
      AppAction.copy,
      AppAction.copyAndPaste,
      AppAction.pastePlain,
      AppAction.deleteItem,
      AppAction.togglePin,
    ],
    'Advanced': [
      AppAction.selectAll,
      AppAction.startSequence,
      AppAction.openSettings,
      AppAction.close,
    ],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = HotkeyConfigService.instance;

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent tap-through
            child: Material(
              elevation: 16,
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surface,
              child: Container(
                width: 320,
                constraints: const BoxConstraints(maxHeight: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Keyboard Shortcuts',
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: onClose,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shrinkWrap: true,
                        children: _categories.entries.map((category) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 4),
                                child: Text(
                                  category.key,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              ...category.value.map((action) {
                                final binding = config.getBinding(action);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 3),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          HotkeyConfigService.actionDisplayName(
                                              action),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surface,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color: theme.dividerColor),
                                        ),
                                        child: Text(
                                          binding.describe(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                            color:
                                                theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
