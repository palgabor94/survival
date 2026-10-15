# Menetvége és profil — működő Flutter képernyők

2026-10-15 · [Bekötés, mechanika és validáció](../../design/run-progression-v1/IMPLEMENTATION_HU.md).

16 kép a tényleges alkalmazás-widgetekből, 390×844 logikai telefonméreten, kétszeres PNG felbontással. A számlálókat bemutató előtörténettel és 420 előzetes XP-vel indítjuk, majd a motor valódi utazási tranzakciója mérgezéses vereséget zár le. A +246 XP / 666 össz-XP mentés-visszatöltés után is megmarad. A perk kiválasztása után valódi új menet indul 0 Wood / 2 Stone készlettel. A megmentési képek külön bemutatóállapotból a három valódi viharválasztás után, +720 XP-vel készülnek.

A mentéshibás kép beállított hibaállapotot szemléltet; a sikertelen tárolóírást és újrapróbálást külön automatizált tesztek ellenőrzik. Az aktív legacy mentés a valódi migrációs útvonalon kap részleges rekordot. Nem fizikai telefonos felvételek és nem nulláról végigjátszott screenshot-menetek; a nyolc nulláról végigvitt játékteszt eredménye külön szerepel a validációban.

1. [Vereség, tényleges mérgezési ok és rögzített XP](01-defeat-summary.png)
2. [XP tételes bontása](02-xp-breakdown.png)
3. [Rang 3 feloldása](03-rank-unlocked.png)
4. [Tartós játékosprofil](04-player-profile.png)
5. [Mentett menetek archívuma](05-journey-archive.png)
6. [Mérföldkövek és végső statok](06-journey-details.png)
7. [Indulókészlet-választás](07-starting-options.png)
8. [Zárolt Field Medic részletei](08-locked-option.png)
9. [Scavenger Kit előnye és ára](09-scavenger-details.png)
10. [Kiválasztott következő készlet](10-selected-option.png)
11. [Új menet pontos indulási összesítője](11-new-journey-review.png)
12. [Valódi új Day 1, Scavenger készlettel](12-new-starting-supplies.png)
13. [Valódi háromlépéses vihar utáni megmentési összesítő](13-rescued-summary.png)
14. [Megmentett profil és rekordok](14-rescued-profile.png)
15. [Mentéshiba és Retry Save állapot](15-save-retry.png)
16. [Régi aktív mentés részleges rekordja](16-partial-legacy-record.png)

Újraexportálás az app könyvtárából:

```sh
LOST_CANOPY_CAPTURE_PROGRESSION=1 LOST_CANOPY_CAPTURE_OUTPUT=screenshots/run-progression-v1 python3 screenshots/tools/capture_unified_ui.py
```

Teljes ellenőrzés: 450/450 teszt; a végső rekordvédelmi javítás után célzott profil/UI kör 24/24; analyzer tiszta. A kis kijelző, fekvő nézet és kétszeres betűméret része az UI-teszteknek. A fizikai telefonos próba és emberi balanszteszt még hátravan.
