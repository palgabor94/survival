# Lost Canopy — teljes kártyakészlet

2026-10-12 · **42 saját hátteres kártyaillusztráció**, 1536 × 1024 PNG, 3:2.

[Galéria: natív Flutter-kártyák és mind a 42 kép külön](index.html).

A Forage újragenerálva, középre helyezett tárgycsoporttal. A jóváhagyott fáklya, lándzsa, rönkök, hal és visszavonulás képe megmaradt; további 37 kép külön imagegen-hívással készült. Az illusztrációk közvetlenül a saját hátterükkel kerülnek a kártyákra. A HUD atlaszfájljai megmaradtak; a hét új rescue-item külön átlátszó PNG-t használ. [Rescue promptok](../../assets/art/RESCUE_MILESTONE_PROMPTS.md) · [Itemikon-promptok](../../assets/art/ITEM_ICON_PROMPTS_V1.md).

Az álló kártyák legfeljebb 160, a vízszintes változatok 320 logikai pixel szélesek; képi ablakuk mindig 3:2. Az eseménykártyák egy sorban lapozhatók, egyenlő magassággal. A tényleges eredményt a választás utáni popup közli.

- [1. kártyalap](01-card-set.png)
- [2. kártyalap](02-card-set.png)
- [3. kártyalap](03-card-set.png)
- [4. kártyalap](04-card-set.png)
- [Pontos generálási promptok](../../assets/art/CARD_ILLUSTRATION_FULL_PROMPTS.md)
- [Forrásjegyzék](../../assets/art/card_illustration_manifest_v1.json)
- [Friss mobilképernyők](../unified-ui-v1/index.html)
- [Új expedíciók és encounterek](../expansion-v1/index.html)

A natív kártyalapok 390 × 844 logikai méreten, 2× PNG exporttal készültek. Export: `LOST_CANOPY_CAPTURE_CARD_SET=1 python3 screenshots/tools/capture_unified_ui.py` a projekt gyökerében. Az exporterhez meglévő Flutter SDK szükséges; szükség esetén `LOST_CANOPY_CAPTURE_SDK` adja meg az útját.
