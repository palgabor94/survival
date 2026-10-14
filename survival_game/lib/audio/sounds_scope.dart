import 'package:flutter/material.dart';
import 'sounds_controller.dart';

class SoundsScope extends InheritedNotifier<SoundsController> {
  const SoundsScope({
    super.key,
    required SoundsController? controller,
    required super.child,
  }) : super(notifier: controller);
  static SoundsController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SoundsScope>()?.notifier;
}

class SoundControls extends StatelessWidget {
  const SoundControls({super.key});
  @override
  Widget build(BuildContext context) {
    final sounds = SoundsScope.of(context);
    if (sounds == null) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile.adaptive(
          key: const ValueKey('sounds-enabled'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Sound effects'),
          subtitle: Text(
            sounds.available
                ? 'Jungle ambience and actions'
                : 'Sounds currently unavailable',
          ),
          secondary: Icon(
            sounds.enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          ),
          value: sounds.enabled,
          onChanged: sounds.setEnabled,
        ),
        Row(
          children: [
            const Icon(Icons.volume_down_rounded),
            Expanded(
              child: Slider(
                key: const ValueKey('sounds-volume'),
                label: '${(sounds.volume * 100).round()}%',
                value: sounds.volume,
                divisions: 20,
                onChanged: sounds.enabled ? sounds.setVolume : null,
              ),
            ),
            SizedBox(
              width: 42,
              child: Text('${(sounds.volume * 100).round()}%'),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
