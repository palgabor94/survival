import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'analytics_controller.dart';

class FirebaseAnalyticsSink implements AnalyticsSink {
  FirebaseAnalytics? _analytics;
  Future<FirebaseAnalytics> _get() async {
    if (Firebase.apps.isEmpty) {
      final config =
          jsonDecode(await rootBundle.loadString('assets/config/firebase.json'))
              as Map;
      final platform = defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : 'android';
      final values = config[platform];
      if (config['configured'] != true || values is! Map) {
        throw StateError('Firebase project not configured');
      }
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: values['apiKey'] as String,
          appId: values['appId'] as String,
          messagingSenderId: values['messagingSenderId'] as String,
          projectId: values['projectId'] as String,
          iosBundleId: values['iosBundleId'] as String?,
          storageBucket: values['storageBucket'] as String?,
        ),
      );
    }
    return _analytics ??= FirebaseAnalytics.instance;
  }

  @override
  Future<void> configure(bool enabled, String? playerId) async {
    final sdk = await _get();
    await sdk.setConsent(
      analyticsStorageConsentGranted: enabled,
      adStorageConsentGranted: false,
      adUserDataConsentGranted: false,
      adPersonalizationSignalsConsentGranted: false,
    );
    await sdk.setUserId(id: enabled ? playerId : null);
    await sdk.setAnalyticsCollectionEnabled(enabled);
  }

  @override
  Future<void> send(String name, Map<String, Object> parameters) async =>
      (await _get()).logEvent(name: name, parameters: parameters);
  @override
  Future<void> reset() async => (await _get()).resetAnalyticsData();
}
