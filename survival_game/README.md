# Lost Canopy

Flutter jungle survival game based on `../LOST_CANOPY_MVP_STARTER_KIT`.

## Current game

Camp day/night cycle, four survival stats, six daylight units, Forage/Explore/Rest, crafting, three camp upgrade tiers, inventory, fishing, multi-stop expeditions and automatic save/resume are implemented. The content catalog contains **28 events and 7 map locations**. Plane Wreck is playable from camp tier 1; Ancient Ruins remains future content. New routes are Bamboo Grove and Mangrove Shallows; new encounters are crocodiles, hornets and raiding monkeys.

The shared card UI uses **35 individually generated illustrations with their own backgrounds**, centered foreground subjects and a consistent **3:2 image window**. Cards in each deck/carousel row share the natural height of the tallest card. Portrait cards are capped at 160 logical pixels; horizontal popup cards at 320. Standalone HUD/icon atlases remain in use. Event choices hide rewards and odds; the actual outcome appears after choosing, including fatal outcomes.

## Play

1. Explore → Riverbank → collect supplies.
2. Craft → Basic Rod, Stone Knife or Stone Axe; build Basic Refuge when ready.
3. Map → Fishing Pond → cast, hook and reel; eat fish from Inventory → Food.
4. Visit Bamboo Grove, Mangrove Shallows or Plane Wreck; choose to return with your haul or push deeper.
5. Resolve the night event, sleep and continue. Runs automatically resume after restarting the app.

Travel/actions consume 4 Water and 3 Food per time unit. Empty supplies damage health. Fishing uses 2 daylight per trip and 1 bait per cast, with one cast per visit. Good catches give 1 Small Fish; perfect catches give 2. Reading choices/results consumes no time. Leaving fishing and backgrounding the app pause its clock.

Run `flutter run` from this directory with an existing Flutter SDK.

## Code and content

- `lib/game/game_engine.dart`: transactions, travel, crafting, expeditions, outcomes and day transitions.
- `lib/game/fishing_session.dart`: frame-rate-independent fishing simulation.
- `lib/game/run_storage.dart`: persistent run storage.
- `assets/data/events.json`, `locations.json`, `recipes.json`: game content.
- `lib/ui/action_card.dart`, `card_illustration.dart`: shared cards and production artwork registry.
- `screenshots/tools/capture_unified_ui.py`: native screenshot exporter.

## Verification and galleries

**185 tests passed, 0 failed/skipped; analyzer: No issues found.** The sandbox blocks the normal test launcher's localhost socket, so the repository's actual test declarations ran through `test_api` LiveTest and Flutter's native engine using `python3 screenshots/tools/run_native_tests.py`. The seeded stress test ran 200 games, 37,502 transactions and 2,288 save/restores, reaching all 28 events. Device builds and physical-device checks were not performed in this round.

- [Latest card height validation](design/unified-card-ui/CARD_HEIGHT_VALIDATION_2026_10_12.md)
- [MVP requirement audit](MVP_AUDIT_2026_10_12.md)
- [Detailed validation report](design/unified-card-ui/VALIDATION_2026_10_12.md)
- [35 card illustrations](screenshots/card-illustrations-v1/index.html)
- [30 refreshed mobile screens](screenshots/unified-ui-v1/index.html)
- [10 new expedition/encounter screenshots](screenshots/expansion-v1/index.html)
- [Current status and Hungarian roadmap](PROJECT_STATUS_AND_ROADMAP.md)

The playable survival loop is ready; rescue/beacon progression, playable ruins and a successful ending remain future milestones.
