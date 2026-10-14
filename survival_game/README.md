# Lost Canopy

Flutter jungle survival game based on ../LOST_CANOPY_MVP_STARTER_KIT.

## Current game

The game now has a playable rescue ending: Plane Wreck salvage → Machete and camp tier 2 → Ancient Ruins stone puzzle → Beacon Core → Rescue Base → Emergency Beacon → signal → next dawn's three storm challenges → RESCUED.

Camp day/night, four survival stats, six daylight units, crafting, three upgrades, inventory, fishing, multi-stop expeditions and automatic resume are implemented. Content: **37 events, 7 playable map locations, 14 recipes (11 items + 3 camp upgrades), 42 card illustrations**. The five beacon components are Battery, Wire, Metal Parts, Radio Module and Beacon Core.

Portrait scene backgrounds fit the screen width without cropping either side. Exposed upper/lower artwork edges fade into the dark backing color; landscape still fills the viewport. Hunting overlays stay aligned with the fitted scene. [Rules and validation](design/scene-width-v1/IMPLEMENTATION.md).

Cards use centered 3:2 scene illustrations, one pale outer rim, equal heights within each row, and a portrait width cap of 160 logical pixels. Small item icons use separate transparent PNGs. All tiers 0–3 use the supplied character-free backgrounds with five separate character poses: warming hands, carrying wood, ground crafting, sitting on a low crate/stump and inspecting the shelter with hands on hips. Only the character fades. Pose-specific scaling keeps the seated figure proportional; positions are tuned per tier to avoid misplaced overlaps with vegetation and props. The visible idle day camp cycles every 30 seconds with a 650 ms fade; popups, night, rescue storm, app background and reduced motion suspend changes. Choices reveal their outcome only in the result popup, including fatal choices.

The six animal encounters and seven world/crafting/rescue backgrounds now use the approved simple camp style, with the new jaguar image as the camera reference and the canonical explorer sheet. Locations have distinct vegetation and scenery; the fishing background remains unchanged. Source files and exact generation prompts are retained.

Wood chopping, foraging and hunting are playable through **Menu → Gather around camp** and seven forest event choices. START charges once; active attempts pause on background/restore, preserve completed progress on confirmed exit, and resolve rewards once in the result popup. Axes and spears wear and can be repaired in the workshop. See [integration rules](design/minigames-v1/IMPLEMENTATION.md).

Fishing starts with a three-step guide and replayable free practice. The white marker follows a moving fish zone using hold/release controls; real bites allow 2 seconds to hook. Practice does not spend extra bait or daylight. [Controls and validation](design/fishing-tutorial-v1/IMPLEMENTATION.md).

Three supplied music tracks are integrated with looping, scene-based selection and soft fades: camp, main/exploration and action. **Camp → Menu** contains saved music/mute and volume controls. Music pauses when the app leaves the foreground. [Music rules and Pixabay SFX keywords](AUDIO_INTEGRATION.md).

All seven supplied sound recordings are integrated: jungle/night/river/rain loops, a campfire layer, three wood-chop variants and four footstep variants. **Camp → Menu → Sound effects** has independent saved mute/volume controls. Short action cues only follow accepted actions and are never replayed from saves. The prepared assets total 3.65 MiB; originals remain in `../sounds/`.

Haptic feedback is integrated with Flutter's built-in platform API. **Camp → Menu → Haptic feedback** saves its own on/off setting. Actions, timing, fishing bites, damage and outcomes give distinct feedback; muted/backgrounded actions and restored reports do not replay vibrations. [Full gameplay and balance audit](design/balance-audit-v1/REPORT.md).

## Play

1. Gather food, water and materials; build tools and Basic Refuge.
2. Recover four working components at the Plane Wreck. Missing parts receive priority and can be recovered again after losing a pack.
3. Build Established Camp and a Machete. Bring at least 4 daylight to the Ancient Ruins: 3 for travel, 1 for submitting the seal.
4. Rotate the three discs to match Sun, Water, Leaf. Turns are free. Failed submissions cost 1 daylight; you can leave and return.
5. Bring the Beacon Core home, build Rescue Base, and assemble the Emergency Beacon from the five components and 2 Metal Scrap.
6. Send the signal for 1 daylight. Prepare food, water and shelter before sleeping.
7. Survive three storm choices, each costing 2 daylight. Each offers a free fallback. Rescue preserves a run summary until you confirm a new run.

Travel consumes 4 Water and 3 Food per time unit; empty supplies damage health. Fishing uses 2 daylight and 1 bait per visit. Reading scenes and outcomes consumes no time. Runs resume mid-choice, report, expedition, stone puzzle, rescue storm or saved victory.

Run flutter run from this directory with an existing Flutter SDK.

For an iOS/Xcode build, run `flutter pub get` and then `pod install` inside `ios/` after adding native plugins. Open **ios/Runner.xcworkspace** so Xcode builds the CocoaPods dependencies too. The iOS minimum is 13.0; `ios/Podfile.lock` pins the installed native plugins, including `audio_session` and `just_audio`.

## Verification and artifacts

All **322 repository tests pass**, and Flutter analyze reports no issues. The repository tests run in Flutter's native engine through screenshots/tools/run_native_tests.py because this sandbox blocks the normal launcher's localhost socket. Two fresh-game simulations reach rescue through earned resources with repeated save/restores. Responsive checks include small phones, landscape, tablets and 2× text. Physical-device builds, performance and a measured 30–60-minute session remain to be checked.

- [Balance stage 1: consistent tool wear, skill rewards and the repeated 1000-run comparison](design/balance-stage1/REPORT.md)
- [Haptics, 1000 fresh-run balance probes and 12,000 isolated minigame probes](design/balance-audit-v1/REPORT.md)
- [Portrait background width and edge-fade screenshots](screenshots/scene-width-v1/index.html)
- [Fishing tutorial, practice and touch gameplay screenshots](screenshots/fishing-tutorial-v1/index.html)
- [20 minigame gameplay screenshots](screenshots/minigames-v1/index.html)
- [13 unified scene backgrounds](design/world-camp-style-v1/index.html)
- [17 mobile screenshots with the new backgrounds](screenshots/camp-style-refresh-v1/index.html)
- [Artwork prompts and integration](design/world-camp-style-v1/README.md)
- [Layered Tier 0–3: five poses and night at two phone sizes, 48 screenshots](screenshots/camp-layers-all-tiers-v1/index.html)
- [Camp sprite assets, prompts, scale and integration](design/camp-layers-all-tiers-v1/IMPLEMENTATION.md)
- [Nine camp variants](screenshots/camp-variants-v2/index.html)
- [Camp art and switching rules](design/camp-variants/DESIGN.md)
- [Rescue UI design](design/rescue-milestone/DESIGN.md)
- [32 ordered rescue screenshots](screenshots/rescue-milestone-v1/index.html)
- [Milestone validation](design/rescue-milestone/VALIDATION.md)
- [Card illustrations](screenshots/card-illustrations-v1/index.html)
- [Current MVP gaps](MVP_AUDIT_2026_10_12.md)
- [Hungarian status and roadmap](PROJECT_STATUS_AND_ROADMAP.md)
- [Exact artwork prompts](assets/art/RESCUE_MILESTONE_PROMPTS.md)

The remaining MVP work includes advanced tools and fish, timed status effects, inventory/storage capacity, tutorial and meta progression.
