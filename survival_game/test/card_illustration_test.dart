import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survival_game/ui/action_card.dart';
import 'package:survival_game/ui/canopy_theme.dart';
import 'package:survival_game/ui/card_art.dart';
import 'package:survival_game/ui/card_illustration.dart';

void main() {
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
            expect(rect.width, lessThanOrEqualTo(160));
            expect(rect.height, closeTo(bounds[1].height, .01));
            expect(rect.top, closeTo(bounds[1].top, .01));
            expect(rect.bottom, closeTo(bounds[1].bottom, .01));
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
        expect(surface.width, 160);
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
