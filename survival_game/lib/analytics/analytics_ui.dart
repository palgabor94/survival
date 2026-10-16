import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ui/canopy_components.dart';
import '../ui/parchment_components.dart';
import 'analytics_controller.dart';

class AnalyticsScope extends InheritedNotifier<AnalyticsController> {
  const AnalyticsScope({
    super.key,
    required AnalyticsController? controller,
    required super.child,
  }) : super(notifier: controller);
  static AnalyticsController? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AnalyticsScope>()?.notifier;
}

/// Passive listener: does not enter the gesture arena or alter button behavior.
class AnalyticsTarget extends StatelessWidget {
  const AnalyticsTarget(this.id, {super.key, required this.child});
  final String id;
  final Widget child;
  @override
  Widget build(BuildContext context) => Listener(
    onPointerUp: (_) => AnalyticsGestures._of(context)?.target = id,
    child: child,
  );
}

class AnalyticsGestures extends StatefulWidget {
  const AnalyticsGestures({
    super.key,
    required this.controller,
    required this.child,
  });
  final AnalyticsController? controller;
  final Widget child;
  static _AnalyticsGesturesState? _of(BuildContext context) =>
      context.findAncestorStateOfType<_AnalyticsGesturesState>();
  @override
  State<AnalyticsGestures> createState() => _AnalyticsGesturesState();
}

class _AnalyticsGesturesState extends State<AnalyticsGestures> {
  String? target;
  final _starts = <int, Offset>{};
  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (e) {
      _starts[e.pointer] = e.position;
      target = null;
    },
    onPointerCancel: (e) => _starts.remove(e.pointer),
    onPointerUp: (e) {
      final start = _starts.remove(e.pointer);
      final size = MediaQuery.sizeOf(context);
      final id = target ?? 'surface';
      if (start == null) return;
      widget.controller?.interact(
        id,
        x: size.width == 0
            ? 0
            : (100 * e.position.dx / size.width).round().clamp(0, 100),
        y: size.height == 0
            ? 0
            : (100 * e.position.dy / size.height).round().clamp(0, 100),
        gesture: (e.position - start).distance > 16 ? 'swipe' : 'tap',
      );
    },
    child: widget.child,
  );
}

class AnalyticsNavigationObserver extends NavigatorObserver {
  AnalyticsNavigationObserver(this.controller, {required this.home});
  AnalyticsController? controller;
  final String home;
  final _routes = <Route<dynamic>>[];
  void _update() {
    final route = _routes.lastOrNull;
    controller?.showScreen(
      route?.settings.name == '/'
          ? home
          : route?.settings.name ?? (route is PopupRoute ? 'popup' : 'screen'),
    );
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
    _update();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _update();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _update();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _routes.indexOf(oldRoute);
    if (i >= 0) {
      if (newRoute == null) {
        _routes.removeAt(i);
      } else {
        _routes[i] = newRoute;
      }
    }
    _update();
  }
}

Future<void> offerAnalytics(BuildContext context) async {
  final analytics = AnalyticsScope.of(context);
  if (analytics == null || analytics.consent != null) return;
  final accepted = await showDialog<bool>(
    context: context,
    routeSettings: const RouteSettings(name: 'analytics_choice'),
    builder: (dialogContext) => CanopyDialog(
      title: 'Help improve Lost Canopy',
      art: 'journal',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ParchmentLabel(
            'Share anonymous gameplay analytics: choices, taps, screen time and run results. No name, email or advertising ID. You can change this in Settings.',
          ),
          const SizedBox(height: 16),
          parchmentButton(
            'SHARE GAMEPLAY DATA',
            () => Navigator.pop(dialogContext, true),
          ),
          parchmentButton(
            'NO THANKS',
            () => Navigator.pop(dialogContext, false),
            secondary: true,
          ),
        ],
      ),
    ),
  );
  await analytics.setConsent(accepted == true);
}

class AnalyticsControls extends StatelessWidget {
  const AnalyticsControls({super.key});
  @override
  Widget build(BuildContext context) {
    final analytics = AnalyticsScope.of(context);
    if (analytics == null) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile.adaptive(
          key: const ValueKey('analytics-enabled'),
          contentPadding: EdgeInsets.zero,
          title: const ParchmentLabel('Gameplay analytics'),
          subtitle: const ParchmentLabel(
            'Anonymous choices, taps and play time.',
            size: 11,
          ),
          value: analytics.enabled,
          onChanged: (value) => unawaited(analytics.setConsent(value)),
        ),
        if (analytics.enabled) ...[
          parchmentButton('COPY DIAGNOSTIC DATA', () async {
            await Clipboard.setData(
              ClipboardData(text: analytics.exportJsonLines()),
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gameplay diagnostics copied.')),
              );
            }
          }, secondary: true),
          parchmentButton(
            'TURN OFF & CLEAR DEVICE DATA',
            () => unawaited(analytics.eraseLocalData()),
            secondary: true,
          ),
        ],
      ],
    );
  }
}
