# Lost Canopy — nagy ellenőrzési kör

2026-10-12 · A teljes saját hátteres kártyakészlet és a tartalombővítés után.

**179 teszt sikeres, 0 sikertelen, 0 kihagyott. `flutter analyze`: No issues found.**

## Futtatás

A szokásos `flutter test --no-pub --concurrency=2 --reporter expanded` indító a környezet localhost-socket tiltása miatt a tesztfájlok betöltése előtt megállt (`Failed to create server socket`, errno 1). Ezért a repository tényleges tesztdeklarációit a Flutter natív motorjában, a `test_api` LiveTest/Invoker és az `AutomatedTestWidgetsFlutterBinding` segítségével futtattuk. Ugyanazok a teszttestek, ellenőrzések, setup/teardown és Flutter-hibakezelés futottak; nem kézi állapotellenőrzés vagy screenshot helyettesítette őket.

```sh
python3 screenshots/tools/run_native_tests.py
/private/tmp/lost-canopy-flutter-sdk/bin/flutter --suppress-analytics analyze --no-pub
```

Az alternatív indítóhoz meglévő Flutter SDK kell. Az útvonal felülírható a `LOST_CANOPY_CAPTURE_SDK` változóval. [Indító](../../screenshots/tools/run_native_tests.py) · [Natív futtató](../../screenshots/tools/run_native_tests.dart) · [Gépi eredmény](validation-results-2026-10-12.json) · [Teljes tesztlog](validation-tests-2026-10-12.log) · [Analyzer log](validation-analyze-2026-10-12.log).

## Lefedett viselkedés

A 13 tesztfájl ellenőrzi a nap/éjszaka váltást, stat- és készlethatárokat, időköltséget, craftot és táborszinteket, térképzárolásokat, expedíciót és encountereket, horgászatot, mentés/visszatöltést, végzetes eredmény utáni összesítőt, újrakezdést és megismételt választás elutasítását.

A tartalombővítés tesztjei a három új encounter minden választását, a kockázatos választások sikerét és kudarcát, az útlezárást és az út folytatását, a függő esemény mentését, valamint a már elhasznált zsákmány későbbi elvesztését fedik le. A két új helyszín kezdeti/mélyebb eseménye és egyszeri utazási költsége is ellenőrzött.

**200 seedelt játékfutás** összesen **37 502 tranzakciót és 2 288 mentés-visszatöltést** hajtott végre, és **mind a 28 eseményt elérte**. Az ellenőrzés nem talált zsákutcát, negatív készletet vagy határon kívüli statot/időt. Ez konzisztenciaellenőrzés; a nehézség és élvezeti érték kézi végigjátszást igényel.

A widgettesztek 320 × 568, 375 × 667, 390 × 844, 844 × 390, 768 × 1024 és 1440 × 900 méreteket fednek le; az érintett felületeken kétszeres szövegméretet és csökkentett animációt is. Mind a 35 PNG képaránya 3:2; egyetlen kártya szélességkorlátja 320/390/768 széles szülőben is ellenőrzött.

## Javítások a tesztkör alapján

- A jelenet teljes tartalmának korábbi `IntrinsicHeight`/`Spacer` elrendezése túl rövid görgetési tartalmat számolt. A közös `CanopySceneBody` most a ténylegesen tördelődő tartalomhoz igazodik.
- A normál mobilméretű horgászati fárasztás és visszatérés álló kártyát használ, így a hosszú feliratok olvashatóak; nagy szövegnél megmarad a vízszintes változat.
- A magában álló, legfeljebb 320 pixel széles vízszintes kártya természetes magasságot kap; a költségek és követelmények kétszeres szövegméretnél sem futnak túl.
- A szöveges tesztek az egységes nagybetűs címstílushoz és az inventory Materials/Food/Gear navigációjához igazodnak. Az elavult, előzetes jutalom/sikeresély elvárásokat a rejtett kimenet ellenőrzése váltotta fel.
- Az expedíció zsákmánylistája követi az útközben elhasznált anyagokat; az elvesztés nem csökkenti még egyszer a készletet.

## Képek és határok

Frissen renderelt [30 mobilképernyő](../../screenshots/unified-ui-v1/index.html), [10 tartalombővítés-kép](../../screenshots/expansion-v1/index.html) és [3 kártyakatalógus-lap / 35 külön illusztráció](../../screenshots/card-illustrations-v1/index.html). A screenshotok tényleges Flutter-widgetek, 390 × 844 logikai méreten, 780 × 1688 PNG-exporttal. A készítés renderelési hibánál megáll.

Készülékes próba, iOS/Android alkalmazásbuild, kiadási teljesítménymérés és végső játékmenet-kiegyensúlyozás ebben a körben nem történt.
