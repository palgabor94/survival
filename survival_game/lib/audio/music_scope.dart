import '../ui/parchment_components.dart';
import 'package:flutter/material.dart';
import 'music_controller.dart';

class MusicScope extends InheritedNotifier<MusicController> {
  const MusicScope({
    super.key,
    required MusicController? controller,
    required super.child,
  }) : super(notifier: controller);
  static MusicController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MusicScope>()?.notifier;
}

/// Dialogs preserve the underlying page's music. Browsing the map uses main.
class MusicNavigationObserver extends NavigatorObserver {
  MusicNavigationObserver(this.music, {this.onMapOpen});
  final MusicController? music;
  final void Function(bool)? onMapOpen;
  final _pages = <Route<dynamic>>[];
  void _update() {
    final mapOpen = _pages.lastOrNull?.settings.name == 'map';
    music?.setMapOpen(mapOpen);
    onMapOpen?.call(mapOpen);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) {
      _pages.add(route);
      _update();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pages.remove(route);
    _update();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pages.remove(route);
    _update();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = _pages.indexWhere((route) => route == oldRoute);
    if (index >= 0) {
      if (newRoute is PageRoute) {
        _pages[index] = newRoute;
      } else {
        _pages.removeAt(index);
      }
    }
    _update();
  }
}

class MusicControls extends StatelessWidget {
  const MusicControls({super.key});
  @override
  Widget build(BuildContext context) {
    final music = MusicScope.of(context);
    return ParchmentSetting(
      title: 'Music',
      enabled: music?.enabled ?? false,
      onEnabled: music?.setEnabled,
      switchKey: const ValueKey('music-enabled'),
      value: music?.volume ?? .35,
      onVolume: music?.setVolume,
      sliderKey: const ValueKey('music-volume'),
    );
  }
}
