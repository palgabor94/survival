# Hátizsák és tároló — működő Flutter felület

2026-10-15. 16 natív Flutter-export 390×844 logikai telefonméreten, 2× PNG felbontásban. [Bekötés, szabályok és ellenőrzés](../../design/inventory-storage-v1/IMPLEMENTATION_HU.md).

A bemutató reprodukálható Tier 2 készletből indul. Nyolc hátizsákhelyet töltünk meg; a Plane Wreck valódi `wreck_battery` eseménye +1 Battery és +1 Metal Scrap jutalmat ad. Ez 10/8 hely. Egy Stone és az új Metal Scrap hátrahagyásával az akkumulátor elfér 8/8 helyen. Hazatéréskor az eredetileg vitt ellátmány is visszakerül, de csak az akkumulátor számít új zsákmánynak. A táborban maradt fémhulladékhoz a terepi elhagyás nem nyúl.

A képek a játék tényleges widgetjeiből és motorjából készültek, beállított bemutatóállapottal. A popupok egy része külön sötét vásznon jelenik meg, hogy a tartalmuk jól áttekinthető legyen. Nem fizikai telefonos felvételek.

1. [Tábori tároló](01-camp-storage.png)
2. [Indulás: vitt ellátmány, 8/8 hely](02-packed-supplies.png)
3. [Mennyiség kiválasztása](03-quantity.png)
4. [Útra felszerelt eszközök](04-equipped-gear.png)
5. [Baltaválasztás](05-choose-axe.png)
6. [Túl nagy csomag: indulás letiltva](06-over-capacity-departure.png)
7. [Terepi hátizsák, tároló nélkül](07-field-backpack.png)
8. [Valódi akkumulátoros roncsesemény](08-wreck-discovery.png)
9. [Megtelt hátizsák, 10/8 hely](09-full-backpack.png)
10. [Az új akkumulátor és fémhulladék](09b-new-battery.png)
11. [Végleges választás, 8/8 hely](10-final-selection.png)
12. [Elhagyás tételes megerősítése](11-confirm-left-items.png)
13. [A megtartott eredmény](12-retained-result.png)
14. [Hazatérés: csak az új zsákmány jutalom](13-return-and-unload.png)
15. [Visszakerült készlet a tárolóban](14-stored-after-return.png)
16. [Trail Backpack fejlesztés](15-backpack-upgrade.png)

Újraexportálás az app könyvtárából:

```sh
LOST_CANOPY_CAPTURE_INVENTORY=1 LOST_CANOPY_CAPTURE_OUTPUT=screenshots/inventory-storage-v1 python3 screenshots/tools/capture_unified_ui.py
```

Ellenőrzés: teljes tesztkör 420/420; végső rövid név- és felületi javítások után célzott készlet/UI kör 29/29. Kis kijelző, fekvő nézet és 2× betűméret szerepel a tesztekben. Emberi balansz és fizikai készülékes ellenőrzés még szükséges.
