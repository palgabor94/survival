import '../ui/parchment_components.dart';
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
    return ParchmentSetting(
      title: 'Haptic feedback',
      enabled: haptics?.enabled ?? false,
      onEnabled: haptics?.setEnabled,
      switchKey: const ValueKey('haptics-enabled'),
    );
  }
}
