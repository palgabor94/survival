import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/ui/action_card.dart';
import 'package:survival_game/ui/canopy_theme.dart';
import 'package:survival_game/ui/card_art.dart';
import 'package:survival_game/ui/card_illustration.dart';
import 'package:survival_game/ui/item_icon.dart';

void main() {
  test(
    'rescue item icons contain real transparency and visible objects',
    () async {
      for (final id in itemIconSubjects) {
        final codec = await ui.instantiateImageCodec(
          File(itemIconFor(id)!).readAsBytesSync(),
        );
        final frame = await codec.getNextFrame();
        final image = frame.image;
        try {
          final pixels = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          final count = image.width * image.height;
          var transparent = 0;
          var opaque = 0;
          for (var pixel = 0; pixel < count; pixel++) {
            final alpha = pixels.getUint8(pixel * 4 + 3);
            if (alpha == 0) transparent++;
            if (alpha >= 240) opaque++;
          }
          for (final corner in [
            0,
            image.width - 1,
            (image.height - 1) * image.width,
            count - 1,
          ]) {
            expect(
              pixels.getUint8(corner * 4 + 3),
              lessThanOrEqualTo(2),
              reason: '$id background corner',
            );
          }
          expect(
            transparent,
            greaterThan(count * .1),
            reason: '$id alpha background',
          );
          expect(
            opaque,
            greaterThan(count * .05),
            reason: '$id visible object',
          );
        } finally {
          image.dispose();
          codec.dispose();
        }
      }
    },
  );

  testWidgets(
    'small rescue item art uses alpha icons while action cards retain scenes',
    (tester) async {
      for (final id in itemIconSubjects) {
        await tester.pumpWidget(
          MaterialApp(
            theme: canopyTheme,
            home: Scaffold(
              body: Column(
                children: [
                  CardArt(id, key: const ValueKey('small-item'), size: 28),
                  ActionCard(title: id, art: id, onTap: () {}),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final small = tester.widget<Image>(
          find.descendant(
            of: find.byKey(const ValueKey('small-item')),
            matching: find.byType(Image),
          ),
        );
        String assetName(Image widget) {
          final provider = widget.image is ResizeImage
              ? (widget.image as ResizeImage).imageProvider
              : widget.image;
          return (provider as AssetImage).assetName;
        }

        expect(assetName(small), itemIconFor(id));
        final scene = find.descendant(
          of: find.byType(ActionCard),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Image && assetName(widget) == cardIllustrationFor(id),
          ),
        );
        expect(scene, findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

  for (final carousel in [false, true]) {
    for (final (size, scale) in [
      (const Size(375, 667), 1.0),
      (const Size(844, 390), 1.0),
      (const Size(768, 1024), 1.3),
    ]) {
      testWidgets(
        '${carousel ? 'carousel' : 'deck'} cards fill the tallest card at $size, text x$scale',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          List<Widget> cards() => [
            ActionCard(
              key: const ValueKey('short-card'),
              title: 'Return to camp',
              description: 'Keep carried loot.',
              art: 'shelter',
              tag: 'SAFE',
              compact: true,
              onTap: () {},
            ),
            ActionCard(
              key: const ValueKey('tall-card'),
              title: 'Go deeper',
              description: 'Better loot · danger rises',
              art: 'trail',
              tag: '40% DANGER',
              lines: const [
                CardLine('−1 time · −4 water · −3 food'),
                CardLine('Requires daylight'),
              ],
              compact: true,
              onTap: () {},
            ),
            const ActionCard(
              key: ValueKey('locked-card'),
              title: 'Use spear',
              art: 'stone_spear',
              description: 'Missing Stone Spear',
              compact: true,
            ),
          ];

          Future<void> mount(Widget child) async {
            await tester.pumpWidget(
              MaterialApp(
                theme: canopyTheme,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: child,
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
          }

          Finder surface(String key) => find.descendant(
            of: find.byKey(ValueKey(key)),
            matching: find.byType(Material),
          );

          await mount(
            carousel ? CardCarousel(cards: cards()) : CardDeck(cards: cards()),
          );
          final bounds = [
            for (final key in ['short-card', 'tall-card', 'locked-card'])
              tester.getRect(surface(key)),
          ];
          for (final rect in bounds) {
            expect(rect.width, closeTo(112 * scale - 4, .01));
            expect(rect.height, closeTo(bounds[1].height, .01));
            if (carousel) {
              expect(rect.top, closeTo(bounds[1].top, .01));
              expect(rect.bottom, closeTo(bounds[1].bottom, .01));
            }
          }
          final imageSizes = [
            for (final key in ['short-card', 'tall-card', 'locked-card'])
              tester.getSize(
                find.descendant(
                  of: find.byKey(ValueKey(key)),
                  matching: find.byType(AspectRatio),
                ),
              ),
          ];
          for (final image in imageSizes) {
            expect(image, imageSizes.first);
            expect(image.aspectRatio, closeTo(1.5, .001));
          }
          expect(tester.takeException(), isNull);

          // Equal height must come from the natural tallest card, with no
          // clipping, shrinking its text, or adding an arbitrary fixed size.
          await mount(
            Center(
              child: SizedBox(width: bounds[1].width, child: cards()[1]),
            ),
          );
          expect(
            tester.getSize(surface('tall-card')).height,
            closeTo(bounds[1].height, .01),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  test(
    'every registered card illustration exists and has the same 3:2 aspect',
    () {
      for (final subject in cardIllustrationSubjects) {
        final file = File(cardIllustrationFor(subject)!);
        expect(file.existsSync(), isTrue, reason: subject);
        final data = ByteData.sublistView(file.readAsBytesSync());
        final width = data.getUint32(16);
        final height = data.getUint32(20);
        expect(width * 2, height * 3, reason: subject);
      }
      expect(cardIllustrationFor('wood'), cardIllustrationFor('firewood'));
      for (final atlas in [
        'card_art_atlas_v2.png',
        'hud_atlas.png',
        'camp_objects_atlas.png',
      ]) {
        expect(File('assets/art/$atlas').existsSync(), isTrue);
      }
    },
  );

  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets(
      'single portrait card keeps its cap and image ratio at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: canopyTheme,
            home: Scaffold(
              body: Center(
                child: Row(
                  children: [
                    Expanded(
                      child: ActionCard(
                        title: 'Forage',
                        art: 'forage',
                        description: '1 time',
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final card = find.byType(ActionCard);
        final surface = tester.getSize(
          find.descendant(of: card, matching: find.byType(Material)),
        );
        final image = tester.getSize(
          find.descendant(of: card, matching: find.byType(AspectRatio)),
        );
        expect(surface.width, 108);
        expect(image.aspectRatio, closeTo(1.5, .001));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('standalone HUD art remains an icon, not a card background', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CardArt('water', size: 24))),
    );
    await tester.pumpAndSettle();
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, 'assets/art/hud_atlas.png');
    expect(tester.getSize(find.byType(CardArt)), const Size(24, 24));
  });
}
