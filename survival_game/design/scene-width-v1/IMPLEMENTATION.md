# Portrait background width and edge fade — 2026-10-13

All full-screen artwork now shares SceneArtwork: camp and its day/night/storm variants, CanopyBackdrop scenes (events, expeditions, fishing, workshop, map, rescue and loading) and gathering minigames.

Portrait and square viewports use fitWidth. The full source width remains visible and scales uniformly; tall phone screens no longer enlarge a 9:16 scene until its sides are cropped. If the artwork is taller than the viewport, vertical cropping is allowed. Landscape keeps cover.

Exposed top/bottom image edges fade over at most 48 logical pixels into CanopyColors.background. The alpha mask uses the decoded image's real dimensions, fitted destination rectangle and alignment; it follows the image edges rather than the screen edges. The center stays opaque, and UI is outside the mask. Existing night multiply tint and ambient scene transitions remain. No raster asset was modified.

The hunting boar and target use the original hunting scene's 941×1672 coordinate space, scaled to the fitted portrait width and shifted by the image's vertical position. Landscape registration remains unchanged.

Validation: 319 repository tests pass, analyzer clean. New tests check actual decoded source and painted dimensions on 320×568, 375×812, 390×844, 430×932 and 768×1024, unchanged landscape coverage, hunting sprite/target alignment and exported pixel alpha at both image edges and its opaque center. Physical-device visual confirmation is still separate from this automated validation.

[Actual mobile screenshots](../../screenshots/scene-width-v1/index.html). Re-export:

```sh
LOST_CANOPY_CAPTURE_SCENE_WIDTH=1 python3 screenshots/tools/capture_unified_ui.py
```
