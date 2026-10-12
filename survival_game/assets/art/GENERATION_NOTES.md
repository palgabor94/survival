# Reference-aligned HUD and night camp

Generated with the built-in image_gen tool. The original daytime camp is the accepted starter-kit master. Original generated outputs are preserved; these copies are project assets.

## starter_camp_night.png

Input: assets/art/starter_camp.png, used as an edit target.

Prompt:
Edit this exact Lost Canopy camp image into NIGHT. Preserve every object, exact camera, framing, aspect ratio, geometry, character pose, shelter, bedroll, crate, logs, lantern, campfire, rocks, leaves, river and waterfall and their precise positions and sizes. Change ONLY time of day and lighting. Deep navy teal moonlit sky and foliage, cool blue moonlight edging leaves and waterfall, warm amber campfire and lantern light naturally illuminating nearby ground, survivor and shelter, clearly readable mobile gameplay clearing. Keep original simplified low-poly 2D flat-shaded illustration style. No new objects, no moon disc, no stars required, no text, no interface. Same scene exactly, only nighttime.

## hud_atlas.png

Transparent 4-column, 3-row atlas. Cells are selected at runtime without changing the source image.

Prompt:
Generate one production sprite atlas for Lost Canopy mobile jungle survival HUD, TRANSPARENT background. Strict 4 columns by 3 rows, 12 equal square cells, center each icon inside its cell with generous 20% clear gutters, no element crossing cells. Row1: red heart, bright cyan water droplet, roasted chicken drumstick, purple brain. Row2: short brown timber log, faceted gray stone, pair green fiber leaves, golden sunshine weather icon. Row3: small primitive leaf shelter objective icon, amber leather backpack inventory icon, folded parchment map with turquoise river and red pin, pale blue crescent moon. Style match low-poly-looking 2D casual survival game: chunky simple silhouettes, subtle bevel highlights, soft flat shading, warm ochre wood and jungle greens, no black outlines, minimal textures, high readability at 24 pixels, polished illustrated UI objects. Isolated icons only, no lettering, no labels, no tile backgrounds, no numbers. Wide 4:3 aspect canvas.


## card_art_atlas.png

Beépített image_gen eszköz. Valódi átlátszó 4×4 atlasz; külön generált tárgyillusztrációk az egységes kártyákhoz. A projektben megőrzött eredeti, a cellákat a Flutter UI választja ki.

```text
Use case: stylized-concept. Asset type: production transparent icon sprite atlas for the Lost Canopy mobile survival card UI. EXACTLY 4 columns by 4 rows, 16 equal square cells on a genuinely transparent canvas, square overall aspect ratio. No grid lines, backgrounds, scene art, text, labels, numbers, borders or shadows outside object. Each single icon centered inside its cell with 18% empty padding on ALL sides, nothing can cross a cell boundary. Flat-shaded low-poly isometric object illustrations, chunky recognizable silhouettes, clean edges, warm jungle greens/earth brown/turquoise/gold accents. Match the supplied game's UI concept illustrations; don't use Material glyphs, emoji or photorealism. EXACT ORDER left-to-right top-to-bottom: row1 berries with leaves; stone axe with wooden handle; simple wooden fishing rod with red-white bobber coiled compactly; burning wooden torch. row2 stone knife; short stone spear arranged diagonally entirely within cell; thick golden curved back arrow; winding jungle trail mini icon made of path and leaves with no rectangular background. row3 small blue fish; pair of red curled bait worms; medicinal green herb sprig; piece of raw red meat. row4 simple water filter bark funnel; blue rain collector barrel with leaf funnel; wooden fish drying rack; brown survival journal book. Icons must have consistent scale, viewpoint and 3-5 large flat-shaded facets per major surface. The fish should be low-poly, NOT realistic scales. True alpha transparency around every object.
```

## Egységes UI — további assetek

A javított tárgyatlasz, kiegészítő táborikonok, műhely, folyópart és jaguáros jelenet pontos promptjai: [UNIFIED_UI_PROMPTS.md](UNIFIED_UI_PROMPTS.md).
