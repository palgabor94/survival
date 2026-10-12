# Lost Canopy — encounter stílusegységesítés v2

2026-10-12 · Beépített imagegen, öt külön generálási hívás. A jaguáros referenciakép változatlan.

Referencia: `assets/art/jaguar_encounter_isometric.png`. Mind az öt kép csak ezt az egy képet kapta stílusreferenciaként. Az előző encounterrajzokat nem használtuk referenciaforrásnak.

Az alábbi közös promptot minden hívásnál változatlanul küldtük be, majd hozzáfűztük a megfelelő `New encounter scene: ...` részt. A képek átlátszatlan, álló PNG-k; az új változatok `_v2.png` fájlokba kerülnek, a korábbi képek megmaradnak.

## Közös prompt — pontos szöveg

```text
Use case: stylized-concept. Asset type: full-screen portrait 9:16 encounter background for Lost Canopy, opaque PNG.
Input image 1 is the STRICT APPROVED STYLE REFERENCE (jaguar encounter), not a subject to copy. Match this exact simple faceted game-art language, palette, character proportions and high isometric camera. Draw the new scene with the SAME simplicity as image 1: LARGE angular leaf shapes, broad flat color planes, chunky rocks with very few faces, solid clean shadows, restrained surface detail, no fine-grained textures, no realistic rendering, no tiny foliage clutter. Keep the same dark-haired adult explorer in a cream rolled-sleeve shirt, green trousers and brown boots/backpack, full-body at the same visible scale as the reference (about 16% of image height), viewed from above and behind. The explorer and threat form the clear central focus in the middle 35-65% of the canvas height, within x25-75%; leave upper and lower parts environmental for HUD and cards. Bright warm yellow sandy path, emerald/lime broad jungle leaves, simple turquoise water and slate grey polygon rocks. Fixed high-angle overhead isometric view, NO horizon, no eye-level cinematic angle. Scene reads as a clean casual low-poly game illustration, like a screenshot from the SAME game as the reference. No UI, text, borders, labels, extra people, jaguar, intricate textures, realistic anatomy details, fuzzy lighting, depth-of-field or detailed scales/fur. Whole bodies visible and unclipped. Portrait 9:16, ideally 1008x1792.
```

## crocodile_encounter_isometric_v2.png

Esemény: `crocodile_shallows`.

```text
New encounter scene: The explorer stands on a dry sandy bank facing one olive-green crocodile emerging from a small shallow turquoise creek. The crocodile is a simple blocky low-poly animal built from a few broad polygon planes, a long wedge snout, four clear feet and a tapering tail curving inward to fit; only a few large dorsal plates, absolutely no rows of tiny scales. Head near the center; entire animal visible. A few broad mangrove roots, very simple broad leaves and two or three large rocks frame the bank. Keep the reference's uncluttered sandy central clearing and generous spacing.
```

## hornet_encounter_isometric_v2.png

Esemény: `hornet_nest`.

```text
New encounter scene: The explorer cautiously raises one empty hand toward a hanging tan hornet nest on a simple low branch. The round paper nest has only a handful of broad flat polygon bands, not detailed honeycomb or tiny facets. Three bold yellow-and-black hornets, each simple angular body and two flat pale wings, hover between explorer and nest. The nest and insects read clearly at the same focal scale as the jaguar reference. Frame the sandy clearing with a few chunky bamboo stems and broad angular leaves; sparse rocks. No many insects, no fine vegetation.
```

## monkey_encounter_isometric_v2.png

Esemény: `monkey_raiders`.

```text
New encounter scene: Two simple chunky brown low-poly monkeys try to steal the explorer's brown backpack: one stands facing him on the path and grips a strap while the explorer holds the other side; the second monkey sits on one simple low fallen branch just behind. Keep arms and straps readable and anatomically clear. The explorer's upper back is visible, no second backpack worn while he is holding his backpack. Monkeys use broad flat shaded planes, rounded angular heads and a single curved tail each, no fur texture. Sandy jungle clearing with broad leaves, a couple of large rocks and a simple narrow turquoise stream along the side. Sparse clean composition, action in central 35-65%.
```

## snake_encounter_isometric_v2.png

Esemény: `snake_thicket`.

```text
New encounter scene: The explorer stops on a sandy jungle trail, facing one coiled green-and-gold snake with a raised head. Snake coil clearly visible among three or four broad leaves at the edge of the path; stylized chunky low-poly tube made of broad flat color bands, simple angular head, no intricate individual scales. Make the coil big enough to read at phone size but smaller than the human in believable game-art proportions. Explorer at same scale as reference, snake near center-right. Broad leaf clusters and a few chunky rocks frame an uncluttered warm sandy path, a simple creek glimpsed in the upper right.
```

## boar_encounter_isometric_v2.png

Esemény: `boar_charge`.

```text
New encounter scene: The explorer braces on a sandy jungle trail facing one wild boar charging out of broad jungle leaves. Boar has a chunky brown low-poly body, large wedge snout, two ivory tusks, four short visible legs, and a few broad angular dark back planes; absolutely no detailed hairs or fur texture. Same approximate focal animal scale and placement as the jaguar reference, with the explorer at lower-left center and the boar at upper-right center. Broad tropical leaves and a few chunky slate rocks frame the clear sandy central action, simple narrow turquoise creek at the right edge. No debris cloud or busy motion effects.
```

[Új hátterek és tényleges mobilképernyők](../../screenshots/encounter-style-v2/index.html).


A darázsos v2 képet a játékban a [v3 változat](HORNET_ENCOUNTER_V3_PROMPT.md) váltotta fel; a fenti v2 prompt az eredeti generálás dokumentációja.
