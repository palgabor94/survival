# Rescue + shelter mérföldkő ellenőrzése

2026-10-12. **221 teszt sikeres, 0 hiba, 0 kihagyás; Flutter analyze: No issues found.**

[Strukturált eredmény](test-results.json) · [Teljes tesztnapló](native-tests.log) · [Analyzer](analyzer.log).

## Mit ellenőriztünk?

- A korábbi tábor, craft, inventory, expedíció, horgászat, esemény- és reszponzív UI-tesztek továbbra is sikeresek.
- A roncs négy alkatrészének prioritása, egyszeri megszerzése és elveszítés utáni pótlása; Machete/Tier 2 romkapu; puzzle forgatás, helyes/hibás beadás, kilépés, utazási költségek és zsákmány.
- Beacon Tier 3 craft, öt alkatrész és két scrap egyszeri fogyasztása; jeladás egyszerisége; következő hajnali Storm, Rain Collector viharos bónusza; három viharhelyzet, eszköz nélküli döntések, halál és győzelem.
- Mentés-visszatöltés puzzle, expedíció, függő döntés, olvasatlan eredmény, vihar és győzelem közben; korábbi v1 mentések alapértékei. A megmentett összesítő újra megnyílik, az új menet megerősítést kér.
- Két friss játékból induló, megszerzett erőforrásokat használó szimuláció (seed 42 és 77) eléri a rescue befejezést. Többször ment és visszatölt, nem injektál beacon-komponenseket vagy táborfejlesztést.
- UI kis mobilon, normál mobilon, fekvő nézetben, tableten és kétszeres szövegméretnél; puzzle, beacon és győzelmi vezérlők elérhetősége.
- Hét kis itemikon alpha háttere, látható tárgyai és a külön nagy kártyaillusztráció megtartása.
- Kilenc különböző, álló tábor-PNG; tűz → ágy → asztal → tűz ciklus; 30 másodperc és áttűnés; popup, háttérbe tett app, busy, éjszaka, vihar és reduced motion miatti szünet; szintváltás és időzítő takarítása. A háttérváltás nem módosítja a RunState-et.

A képtöltési tesztek a natív asseteket előtöltik. A tesztkörök közötti image/bundle cache-t ürítik, hogy egy korábbi fake clock függő asset-future-je ne befolyásolja a következő kör időzítőtesztjét.

## Képi ellenőrzés

[9 táborváltozat és teljes háttér](../../screenshots/camp-variants-v2/index.html) · [32 rescue képernyő](../../screenshots/rescue-milestone-v1/index.html) · [42 kártyakép, 4 natív kártyalap](../../screenshots/card-illustrations-v1/index.html) · [30 alapképernyő](../../screenshots/unified-ui-v1/index.html).

A natív gameplay PNG-k 390 × 844 logikai méretből 780 × 1688 felbontásban készülnek. Valódi Flutter widgetek és műveletek, előkészített játékállapotokból. A rescue-sorozat egy Tier 3 állapotból indul, de a komponenseket tényleges roncs/romok műveletekkel szerzi meg, puzzle után hazaviszi, majd megépíti és aktiválja a beacont. A 19. és 20. képen az alkatrészek már átlátszó ikonok. A tábori galéria csak a kezdeti kozmetikai pózt rögzíti a reprodukálható képekhez; a valódi váltakozás külön widgettesztben fut.

A képek SHA-256 jegyzéke az egyes galériák capture_manifest.json fájljában; a tábori assetek [manifestje](../../assets/art/camp_variants_manifest_v2.json) a forrást, promptot, méretet és hash-t is tárolja. A régi camp_tier_1/2/3 referenciák változatlanok maradtak.

## Futtatás

```sh
python3 screenshots/tools/run_native_tests.py
flutter analyze --no-pub
LOST_CANOPY_CAPTURE_CAMP_VARIANTS=1 python3 screenshots/tools/capture_unified_ui.py
LOST_CANOPY_CAPTURE_RESCUE=1 python3 screenshots/tools/capture_unified_ui.py
LOST_CANOPY_CAPTURE_CARD_SET=1 python3 screenshots/tools/capture_unified_ui.py
python3 screenshots/tools/capture_unified_ui.py
python3 screenshots/tools/update_current_galleries.py
```

A tesztfuttató a repository tényleges testWidgets/test deklarációit futtatja Flutter 3.41.1 natív motorjában. Ez a környezet a normál flutter test launcher localhost kapcsolatát tiltja; a natív futtató kerüli ezt. Az exporter külön képkészítő, nem helyettesíti a tesztkört.

## Hátralévő ellenőrzés

Fizikai iOS/Android build és készülékes futás, process-kill visszatöltés, memória/teljesítménymérés és valódi játékos által mért 30–60 perces menet még nem történt. A funkcionális győzelem igazolt, a készülékes élmény és balansz külön következő kör. [MVP-hiányok](../../MVP_AUDIT_2026_10_12.md).
