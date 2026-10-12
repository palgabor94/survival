import 'dart:io';

import 'package:flutter/services.dart';

/// `flutter test` renders every glyph with the Ahem test font. Captures load
/// the real Arial (the theme font) and Material icons so text is legible.
Future<void> loadCaptureFonts() async {
  final arial = FontLoader('Arial');
  for (final file in ['Arial.ttf', 'Arial Bold.ttf']) {
    arial.addFont(_load('/System/Library/Fonts/Supplemental/$file'));
  }
  await arial.load();

  final icons = FontLoader('MaterialIcons')
    ..addFont(
      _load(
        '${_flutterRoot()}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ),
    );
  await icons.load();
}

Future<ByteData> _load(String path) async =>
    ByteData.sublistView(await File(path).readAsBytes());

/// The test runner (`flutter_tester`) lives under `<flutter>/bin/cache/`.
String _flutterRoot() {
  final fromEnv = Platform.environment['FLUTTER_ROOT'];
  if (fromEnv != null) return fromEnv;
  var dir = File(Platform.resolvedExecutable).parent;
  while (dir.parent.path != dir.path) {
    if (dir.path.endsWith('/bin/cache')) return dir.parent.parent.path;
    dir = dir.parent;
  }
  throw StateError('Flutter SDK not found from ${Platform.resolvedExecutable}');
}
