import '../ui/parchment_components.dart';
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
    return ParchmentSetting(
      title: 'Sound effects',
      enabled: sounds?.enabled ?? false,
      onEnabled: sounds?.setEnabled,
      switchKey: const ValueKey('sounds-enabled'),
      value: sounds?.volume ?? .7,
      onVolume: sounds?.setVolume,
      sliderKey: const ValueKey('sounds-volume'),
    );
  }
}
