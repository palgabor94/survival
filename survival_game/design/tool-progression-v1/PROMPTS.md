# Tárgyatlasz generálás

Built-in imagegen, 2026-10-15. Stílusreferencia: `assets/art/card_stone_axe_scene_v1.png`. Új kép, nem a meglévő art felülírása. Nincs karakter.

```
Use case: stylized-concept
Asset type: Lost Canopy mobile survival game item illustration atlas.
Generate a NEW landscape 1536x1024 image, exact 3-column by 3-row equal grid, each cell is a complete 3:2 landscape illustration. No gaps, no borders, no text, no UI. Reference image is STYLE ONLY: preserve the simple angular low-poly painted shapes, forest green foliage and warm orange wood, soft shadows and clear centered item silhouettes. Every object fully contained with generous 12% safe margins, centered at consistent visual scale, diagonal bottom-left to top-right orientation for axes and spears. Backgrounds slightly darker and quieter than bright subject; distinct fitting jungle/workbench settings, no people.
Top row, left to right: primitive STONE AXE with chunky grey stone head vine bound to short wooden handle over stump clearing; REINFORCED AXE still stone head but larger sharpened head, cross binding, reinforced hardwood handle over bamboo work surface; SALVAGE AXE recognizable broad forged grey steel axe head on strong brown wooden handle with cloth grip over salvage workshop bench.
Middle row: STONE SPEAR long wooden shaft and rough grey stone spear tip rope-bound, jungle leaf ground; HUNTING SPEAR hardwood shaft and narrow elongated polished stone tip with stronger cross bindings, fern clearing; SALVAGE SPEAR hardwood shaft and broad leaf-shaped salvaged steel spearhead with dark collar and wrapped grip, ruined stone jungle ground. Each spear complete, no cropped shafts, no metal fantasy ornaments.
Bottom row: grey sharpening stone with simple water cup and tool maintenance cloth on workbench; tidy coil of plant fiber rope with two short hardwood pieces on jungle ground; two irregular scrap steel pieces on workshop bench. All 9 cells with self-contained backgrounds, no cell bleed. Same moderately elevated three-quarter view for all illustrations. Simple mobile game painted low-poly aesthetic, not realistic photography, not outlines, no yellow glow, no logos.
```

Forrás: `/Users/palgabor/.codex/generated_images/01a12f08-1744-79c2-a79d-a201298416d9/exec-48387658-7340-4e0d-9557-f9c45407b4a7.png`.

A 3×3 cellás atlasz képei 3:2 ablakba kerülnek, középre igazítva. Az első hat cella a három balta és három lándzsa, az utolsó három a javítási kellékek. A látványtervek a meglévő Flutter pergamenkomponensekből készülnek, nem generált szöveget tartalmazó UI-képek. Az implementáláskor a kis ikonokhoz külön átlátszó tárgyképek szükségesek.
