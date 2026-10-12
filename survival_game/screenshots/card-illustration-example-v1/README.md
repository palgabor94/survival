# Fáklyás kártyaminta

2026-10-12 · Egyetlen illusztráció a teljes készlet előtti jóváhagyáshoz.

- [Nagyított, valódi Flutter-kártya](01-torch-card-example.png): 114 × 152 logikai pixel, 2,4-szeres nagyítás a szemrevételezéshez.
- [Valós méret és maximális szélesség](02-single-card-max-width.png): 390 logikai pixeles kijelzőn egyetlen kártya teljes szélességű helyen is csak 160 logikai pixel széles.
- [Generált képfájl](../../assets/art/card_torch_scene_preview_v1.png): 1536 × 1024, 3:2, saját dzsungelháttérrel.
- [Pontos prompt és generálás](../../assets/art/CARD_ILLUSTRATION_EXAMPLE_PROMPT.md): beépített imagegen eszköz.

A két screenshot natív Flutter-widgetexport, 2× pixelsűrűséggel. Az exportban megmért tényleges kártyaszélesség 160, a képi felület 160 × 106,67 logikai pixel, azaz 3:2. A nagyított kép kizárólag a grafika áttekintésére szolgál.

Az álló kártyák közös maximális szélessége 160 logikai pixel, a képi felület aránya mindig 3:2. A vízszintes popupkártyák szélességének felső határa 320 pixel. Az eredeti különálló ikonok és atlaszok megmaradtak. A minta kizárólag ebben az előnézetben szerepel, a többi illusztráció még nem készült el.

A teljes tesztfuttatás a minta jóváhagyása és a teljes illusztrációkészlet elkészülte után következik; ebben a lépésben csak az előnézeti képeket rendereltük.
