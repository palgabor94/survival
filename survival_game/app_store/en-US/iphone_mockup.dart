import 'dart:io';
import 'package:flutter/material.dart';

/// A full screenshot, uniformly scaled, inside a modern iPhone silhouette.
/// The capture reserves 44 / 24 logical pixels for system chrome, so the
/// Dynamic Island and home indicator never obscure the game's controls.
class IPhoneMockup extends StatelessWidget {
  const IPhoneMockup({super.key, required this.screenshot});
  final File screenshot;
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 446 / 948,
    child: LayoutBuilder(
      builder: (context, box) {
        final scale = box.maxWidth / 446;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final (right, top, height) in [
              (false, 148.0, 30.0),
              (false, 205.0, 55.0),
              (false, 274.0, 55.0),
              (true, 228.0, 88.0),
            ])
              Positioned(
                left: right ? null : -2 * scale,
                right: right ? -2 * scale : null,
                top: top * scale,
                width: 3 * scale,
                height: height * scale,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF969A98),
                    borderRadius: BorderRadius.circular(2 * scale),
                  ),
                ),
              ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(51 * scale),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFB8BCB9),
                      Color(0xFF363B39),
                      Color(0xFF818784),
                      Color(0xFF252A28),
                    ],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xB3000000),
                      blurRadius: 24,
                      offset: Offset(0, 9),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(2 * scale),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF050806),
                    borderRadius: BorderRadius.circular(49 * scale),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(6 * scale),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(42 * scale),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            screenshot,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                          Positioned(
                            top: 11 * scale,
                            left: 159 * scale,
                            width: 112 * scale,
                            height: 26 * scale,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFF020403),
                                borderRadius: BorderRadius.circular(16 * scale),
                              ),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: EdgeInsets.only(right: 9 * scale),
                                  child: Container(
                                    width: 7 * scale,
                                    height: 7 * scale,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF10202B),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 14 * scale,
                            left: 25 * scale,
                            child: Text(
                              '9:41',
                              style: TextStyle(
                                fontSize: 13 * scale,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFFFF0CC),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 15 * scale,
                            right: 22 * scale,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.signal_cellular_alt_rounded,
                                  size: 15 * scale,
                                  color: const Color(0xFFFFF0CC),
                                ),
                                SizedBox(width: 3 * scale),
                                Icon(
                                  Icons.wifi_rounded,
                                  size: 15 * scale,
                                  color: const Color(0xFFFFF0CC),
                                ),
                                SizedBox(width: 3 * scale),
                                Icon(
                                  Icons.battery_full_rounded,
                                  size: 17 * scale,
                                  color: const Color(0xFFFFF0CC),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 8 * scale,
                            left: 150 * scale,
                            width: 130 * scale,
                            height: 4 * scale,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0CC),
                                borderRadius: BorderRadius.circular(3 * scale),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
