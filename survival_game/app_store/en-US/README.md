# Lost Canopy — English App Store screenshots

2026-10-16. Six promotional screenshots, each with an English headline, subtitle and genuine in-game capture. [View all six](00-overview.png).

## Upload files

- `iphone-large/`: six RGB JPEGs, **1320×2868** pixels each.
- `iphone-medium/`: six RGB JPEGs, **1206×2622** pixels each.
- [Downloadable ZIP](lost-canopy-iphone-screenshots.zip): both size sets and the English copy.

Both dimensions are listed in [Apple’s screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications), checked 2026-10-16. The JPEGs have no alpha channel. These are iPhone sets; an iPad set is not included. `00-overview.png` is a review contact sheet, not an upload screenshot.

| Order | Headline | Subtitle |
|---|---|---|
| 1 | Survive the Jungle | Manage your supplies. Make every day count. |
| 2 | Explore the Unknown | Choose your route. Bring your supplies home. |
| 3 | Craft Your Way Forward | Make useful tools. Build a stronger refuge. |
| 4 | Face the Wild | Meet the jungle’s dangers. Choose how you respond. |
| 5 | Master the Catch | Time the hook. Keep the fish in the green. |
| 6 | Build Your Escape | Recover the missing parts. Send a signal for rescue. |

## Capture and composition

`raw/` contains fresh captures of the actual Flutter game UI, rendered at 390×932 logical pixels / 3× resolution. The scenes use staged, valid game states to show the existing features: camp, world map, workshop, jaguar encounter, active fishing and the assembled rescue beacon. The fishing image captures an actual running session. This is not a claim that the six screens came from a single uninterrupted playthrough.

The entire screenshot is preserved inside its frame, with no replacement HUD, fabricated gameplay or obscured controls. The separate title/subtitle and forest backdrop are composed with native Flutter widgets using existing game artwork. No new AI imagery was used for this screenshot pack. `copy.json` contains the English text.

Reproduce from the Flutter project directory, sequentially:

```sh
LOST_CANOPY_CAPTURE_STORE_RAW=1 LOST_CANOPY_CAPTURE_PIXEL_RATIO=3 LOST_CANOPY_CAPTURE_OUTPUT=app_store/en-US/raw python3 screenshots/tools/capture_unified_ui.py
python3 app_store/en-US/render.py
```

The poster renderer exports native PNG intermediates under `.dart_tool/app-store-export/`, then uses macOS `sips` to encode the final high-quality, opaque JPEGs. All twelve final file dimensions and RGB modes were verified. Both native rendering passes completed without layout errors; Dart analyzer is clean. App Store Connect upload/review has not been performed.
