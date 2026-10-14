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
    if (music == null) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile.adaptive(
          key: const ValueKey('music-enabled'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Music'),
          subtitle: Text(
            music.available
                ? 'Jungle soundtrack'
                : 'Audio currently unavailable',
          ),
          secondary: Icon(
            music.enabled ? Icons.music_note_rounded : Icons.music_off_rounded,
          ),
          value: music.enabled,
          onChanged: music.setEnabled,
        ),
        Row(
          children: [
            const Icon(Icons.volume_down_rounded),
            Expanded(
              child: Slider(
                key: const ValueKey('music-volume'),
                label: '${(music.volume * 100).round()}%',
                value: music.volume,
                divisions: 20,
                onChanged: music.enabled ? music.setVolume : null,
              ),
            ),
            SizedBox(
              width: 42,
              child: Text('${(music.volume * 100).round()}%'),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
