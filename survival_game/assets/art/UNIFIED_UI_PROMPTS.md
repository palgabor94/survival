# Lost Canopy — egységes UI: produkciós illusztrációk

Beépített image_gen eszközzel készültek, a jóváhagyott v1 látványtervek alapján. A képek felirat és beégetett UI nélküli assetek.

## workshop_scene.png

```text
Use case: stylized-concept. Asset type: production portrait game background for Lost Canopy Workshop. Input image is a STYLE AND COMPOSITION REFERENCE: the LEFT craft screen on the approved two-screen concept board. Create ONLY its clean workshop scene as a full single portrait image, with absolutely NO UI, text, HUD, cards, buttons, logos or borders. Match its illustrated jungle workbench: survivor seen from behind in tan shirt and green trousers with a brown backpack, working at a chunky wooden bench, stone axe, simple hand tools hanging from a plank wall, lantern, timber and leaves, jungle canopy. Faithfully follow the concept scene, not the right-side upgraded shelter. Warm daylight, flat-shaded low-poly 2D mobile game illustration, rich greens and ochre, no realism or busy texture. Place survivor/workbench in central middle-lower region; top quarter leaves and soft jungle for an overlaid HUD, bottom fifth logs and ground for runtime action cards. Portrait mobile aspect around 9:16. No interface anywhere.
```

## camp_objects_atlas.png

```text
Use case: stylized-concept. Asset type: supplementary transparent Lost Canopy object atlas. Input is style reference only. Exactly 2 columns by 2 rows, four equal square cells on a transparent square canvas. Each object entirely inside its cell, centered at consistent scale, 22 percent clear padding on ALL four sides. Row1 left: bundle of dark hardwood logs tied with vines, visibly darker timber and cut grain. Row1 right: a small pile of bent gray metal scrap plates, short wire and bolts, no sharp weapons. Row2 left: leaf bed, low wooden rectangle frame with thick broad green leaves and simple rolled leaf pillow. Row2 right: tied bundle of warm brown firewood logs. Match supplied flat-shaded painted low-poly survival icons, thick silhouettes, few clean facets, golden rim highlights, jungle greens and ochre. Genuinely transparent alpha around each object; no background, no tile, no grid, no lettering, no labels, no numbers, no scene and no borders.
```

## riverbank_scene.png

```text
Use case: stylized-concept. Asset type: Lost Canopy production portrait Riverbank expedition background. Input is a STYLE/COMPOSITION reference, use ONLY the LEFT daytime riverbank screen on the concept board. Create a full single clean portrait 9:16 game scene: tan-shirt survivor with brown backpack and green trousers seen from behind beside a turquoise winding stream, jungle leaves frame the edges, gray boulders, distant waterfalls and green cliffs. Match the approved scene closely in simple painted low-poly 2D flat shading, rich jungle green, cyan river, warm ochre ground, no realistic textures. Character and riverbank centered in the middle of the image so actual UI at top and bottom will leave them visible. The upper 20 percent is jungle foliage and cliffs; bottom 20 percent foreground leaves/ground. No night scene. ABSOLUTELY NO UI, text, panels, numbers, icons, cards, borders or logo.
```

## jaguar_encounter_scene.png

```text
Use case: stylized-concept. Asset type: Lost Canopy production portrait jaguar encounter background. Input is a STYLE/COMPOSITION reference, use ONLY the RIGHT jaguar encounter screen on the concept board. Full single clean portrait 9:16 illustration with tan-shirt survivor, green trousers and brown backpack seen from behind on a jungle trail, facing a yellow spotted jaguar in defensive crouch. Mossy ruined stone wall to left, turquoise river and distant waterfall to right, jungle foliage framing edges. Match approved art with simple flat-shaded low-poly-looking 2D mobile game illustration. Keep jaguar and survivor clearly visible in middle 50 percent of the canvas; upper 20 percent jungle canopy/cliffs and lower 20 percent path/foreground leaves for separately rendered interface. No blood. ABSOLUTELY NO UI, text, labels, panels, cards, numbers, icons, borders or logo.
```

## card_art_atlas_v2.png

A korábbi atlasz javított, szélesebb átlátszó közökkel készült változata. A kód ezt használja; az eredeti megmaradt.

```text
Use case: precise-object-edit. Asset type: corrected transparent 4 by 4 Lost Canopy icon atlas. EDIT TARGET is supplied atlas. Preserve the SAME 16 icon subjects, order, design, palette and rendering style exactly. Change ONLY each object's size and placement: make EACH object 60 percent as large as it currently is, and center it precisely at the center of its own cell. Strict evenly sized 4 columns by 4 rows on square canvas. Thus each icon must fit ENTIRELY inside the central 60 percent square of its own cell, with at least 20 percent empty transparent padding on ALL sides. Individual objects must never cross boundaries or touch objects in any adjacent cells. Most importantly row4 filter/barrel/rack/book must move DOWN to the centers of row4 cells; row3 bait worms/herb/meat stay centered row3. Row1 berries/axe/rod/torch. Row2 knife/spear/back arrow/trail. Row3 fish/bait/herb/meat. Row4 filter/rain collector/drying rack/journal. No new icons or changed illustration style. No labels, grid lines, text, backgrounds or frames. Genuine alpha transparency throughout the gutters. This will be sliced into equal cells at runtime: empty gutters are essential.
```

## Izometrikus jelenetjavítás

A folyópart és a jaguáros találkozás aktív háttere a `riverbank_isometric.png` és `jaguar_encounter_isometric.png`. A régi változatok megmaradtak. [A javítás pontos promptjai és referenciái](ISOMETRIC_SCENE_PROMPTS.md).
