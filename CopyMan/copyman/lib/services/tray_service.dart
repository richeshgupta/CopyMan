import 'dart:io';

import 'package:tray_manager/tray_manager.dart';

typedef VoidCallback = void Function();

class TrayService with TrayListener {
  final VoidCallback onShow;
  final VoidCallback onExit;

  TrayService({
    required this.onShow,
    required this.onExit,
  });

  Future<void> init() async {
    await trayManager.setIcon(
      Platform.isLinux
          ? 'assets/icons/tray_icon.png'
          : 'assets/icons/tray_icon.png',
    );

    final menu = Menu(
      items: [
        MenuItem(
          label: 'Show CopyMan',
          onClick: (_) => onShow(),
        ),
        MenuItem.separator(),
        MenuItem(
          label: 'Settings',
          onClick: (_) {
            // TODO: Settings dialog in Phase 2
          },
        ),
        MenuItem.separator(),
        MenuItem(
          label: 'Exit',
          onClick: (_) => onExit(),
        ),
      ],
    );

    await trayManager.setContextMenu(menu);
    trayManager.addListener(this);
  }

  @override
  void onTrayIconMouseDown() {
    // Show window on left-click
    onShow();
  }

  @override
  void onTrayIconRightMouseDown() {
    // Context menu handled by trayManager
  }

  void destroy() {
    trayManager.removeListener(this);
  }
}
