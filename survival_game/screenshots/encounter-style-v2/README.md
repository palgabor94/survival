# Lost Canopy — encounter stílusegységesítés v2

2026-10-12 · [Hátterek és mobilképek galériája](index.html).

A jaguáros referencia alapján öt új hátteret generáltunk a beépített imagegen eszközzel. Az új képek nagyobb, egyszerűbb formákat, széles színfelületeket, ugyanazt a magas izometrikus nézetet és hasonló szereplőléptéket használnak. A jaguáros eredeti változatlan; a régi v1 képek megmaradtak.

| Encounter | Játékban használt háttér | Mobilkép |
|---|---|---|
| Jaguár · jóváhagyott referencia | [jaguar_encounter_isometric.png](../../assets/art/jaguar_encounter_isometric.png) | [Screenshot](01-jaguar_trail.png) |
| Kígyó | [snake_encounter_isometric_v2.png](../../assets/art/snake_encounter_isometric_v2.png) | [Screenshot](02-snake_thicket.png) |
| Vaddisznó | [boar_encounter_isometric_v2.png](../../assets/art/boar_encounter_isometric_v2.png) | [Screenshot](03-boar_charge.png) |
| Krokodil | [crocodile_encounter_isometric_v2.png](../../assets/art/crocodile_encounter_isometric_v2.png) | [Screenshot](04-crocodile_shallows.png) |
| Darázsfészek | [hornet_encounter_isometric_v3.png](../../assets/art/hornet_encounter_isometric_v3.png) | [Screenshot](05-hornet_nest.png) |
| Majmok | [monkey_encounter_isometric_v2.png](../../assets/art/monkey_encounter_isometric_v2.png) | [Screenshot](06-monkey_raiders.png) |

A `snake_thicket` és `boar_charge` külön hátteret kapott; a krokodil és majmok eseményeinek `background` mezője a v2, a darazsaké a frissített v3 képre mutat. A játékszabályok és a kártyák elrendezése változatlan.

[Pontos promptok](../../assets/art/ENCOUNTER_STYLE_V2_PROMPTS.md) · [Forrásjegyzék](../../assets/art/encounter_style_v2_manifest.json).

Export: `LOST_CANOPY_CAPTURE_ENCOUNTER_STYLE=1 python3 screenshots/tools/capture_unified_ui.py` a projekt gyökerében, meglévő Flutter SDK-val. A 6 mobilkép 390 × 844 logikai méreten, 780 × 1688 PNG-ként készül; renderelési hiba esetén az export megáll.

Ellenőrzés: mind az öt új háttér vizuálisan átnézve; hat encounter képe tényleges Flutter-widgetből, renderelési hiba nélkül elkészült. Analyzer: `No issues found`. [Screenshot-log](capture.log) · [Analyzer-log](analyze.log). A játéklogikát nem módosítottuk; a korábbi 179 teszt eredményét a külön tesztjelentés dokumentálja.

Darázsfrissítés v3: karcsú, csíkos darazsak külön száraz bambuszligetben; az izometrikus kamera és az egyszerű grafikai stílus megmaradt. [Pontos v3 prompt](../../assets/art/HORNET_ENCOUNTER_V3_PROMPT.md).

A v3 háttér a valódi mobilképen is ellenőrizve. A 6 encounter- és 10 expansion-képernyő friss exportja renderelési hiba nélkül lefutott. Az eseménykatalógus háttérhivatkozásai érvényesek.
