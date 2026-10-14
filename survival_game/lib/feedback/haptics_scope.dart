import 'package:flutter/material.dart';
import 'haptics_controller.dart';

class HapticsScope extends InheritedNotifier<HapticsController> {
  const HapticsScope({
    super.key,
    required HapticsController? controller,
    required super.child,
  }) : super(notifier: controller);
  static HapticsController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HapticsScope>()?.notifier;
}

class HapticControls extends StatelessWidget {
  const HapticControls({super.key});
  @override
  Widget build(BuildContext context) {
    final haptics = HapticsScope.of(context);
    if (haptics == null) return const SizedBox.shrink();
    return SwitchListTile.adaptive(
      key: const ValueKey('haptics-enabled'),
      contentPadding: EdgeInsets.zero,
      title: const Text('Haptic feedback'),
      subtitle: const Text('Actions and minigame feedback'),
      secondary: const Icon(Icons.vibration_rounded),
      value: haptics.enabled,
      onChanged: haptics.setEnabled,
    );
  }
}
