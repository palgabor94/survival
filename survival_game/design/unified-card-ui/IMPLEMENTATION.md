# Lost Canopy — egységes UI implementáció

**2026-10-12 · 35 saját hátteres kártyaillusztráció implementálva; 28 esemény, 7 helyszín. 179 teszt sikeres, analyzer tiszta.**

[Teljes új kártyakészlet](../../screenshots/card-illustrations-v1/index.html) · [Új expedíciók és encounterek](../../screenshots/expansion-v1/index.html) · [Aktuális grafikai szabályok](CARD_ILLUSTRATIONS_V1.md) · [Tesztjelentés](VALIDATION_2026_10_12.md).

[Kártyagrafika v4 és ikongaléria](../../screenshots/card-art-v4/index.html) · [V4 részletek](CARD_ART_V4.md).

[A legújabb esemény- és eredményképek](../../screenshots/event-choices-v3/index.html). A korábbi eseménykártya-terveket az alább leírt v3 döntés felülírja.

[30 tényleges mobilképernyő számozott galériája](../../screenshots/unified-ui-v1/index.html) · [Képlista](../../screenshots/unified-ui-v1/README.md) · [Jóváhagyott látványtervek](v1/README.md)

## Elkészült felületek

| Felület | Implementált megjelenítés | Screenshot |
|---|---|---|
| Tábor | Kompakt HUD; nap/idő bal fent, statok jobbra, ikon és szám felettük, csík alattuk; nyersanyagok ez alatt; célpanel; Inventory a döntési kártyák felett. Nappal, éjszaka és fejlesztett tábor. | 01, 11, 15 |
| Inventory | Materials / Food / Gear fülek, illusztrált tárgykártyák, készletmennyiség, használat/főzés és műhelyparancs. | 02–04 |
| Explore | Teljes képernyős térkép, helyszínek, kijelölés, követelmények, utazási költség és zárolt akció. | 05–06 |
| Craft | Új műhelyháttér, kiválasztott recept hatása és költsége, összes recept görgethető listája, READY / OWNED / LOCKED, Craft és Back kártyák. | 07–08 |
| Táborfejlesztés | Camp fül, szintelőnézet, aktuális szint és következő építés; későbbi szintek követelményei. | 09–11 |
| Események | Közös helyzetpanel és legfeljebb négy döntési kártya, akciónév és követelmény, előzetes eredmény nélkül. A változások a választás utáni popupban látszanak. Új folyóparti és jaguáros háttér. | 12, 14, 16 |
| Expedíció | Helyszín/lépés, hordott zsákmány és veszélyjelző, Return to Camp / Go Deeper. | 13 |
| Horgászat | Dobás, várakozás, kapás, fárasztás, eredmény; közös kártyák, tényleges minijátékvezérlés és megállított időzítő a kilépési ablakban. | 17–22 |
| Eredmény és popupok | Valós ActionReport és változáscsipek; tábor menü; napló; útmutató; új menet és horgászatból kilépés megerősítése; Game Over. | 21, 23–28 |
| Indulás | Betöltés HUD nélkül; induláskori hiba és Try Again. | 29–30 |

## Közös komponensek és grafika

Az `ActionCard` és `CardDeck` adja a kártyák keretét, illusztrációját, státuszát és természetes szövegmagasságát. A `CanopyHud`, `CanopyDialog`, `CanopyConfirmation`, `CanopyShortcut`, `CampPanel` és `SceneLayout` fogja össze a HUD-ot, a paneleket, a popupokat és a jelenet fölötti akciókat. A kártyák szemantikája és szöveges állapotjelzése is megmarad. Keskeny képernyőn vagy nagy szövegnél a rácsok kevesebb oszlopot, a panelek görgetést használnak; kis/fekvő kijelzőn és kétszeres szövegméretnél is sikeresen ellenőrizve. A közös `CanopySceneBody` természetes magassággal és görgetéssel őrzi meg a vezérlők elérhetőségét.

A nagy kártyaillusztrációk a `cardIllustrationFor` jegyzék alapján közvetlenül, saját háttérrel töltődnek be; a kis ikonokat a `CardArt` komponens adja. Új assetek: `card_art_atlas_v2.png`, `camp_objects_atlas.png`, `workshop_scene.png`, `riverbank_scene.png`, `jaguar_encounter_scene.png`. A HUD az előző illusztrált ikonatlaszt használja. A generálási promptok: [UNIFIED_UI_PROMPTS.md](../../assets/art/UNIFIED_UI_PROMPTS.md).

A megjelenített számok, költségek, hatások és tiltások a meglévő motorból és adatfájlokból származnak. A recept- és tárolóréteg megmaradt. Az eseménykatalógus négy új gyűjtési eseményt és három új encountert kapott; a zsákmány nyilvántartása az útközben elhasznált anyagokat is követi. A motor most a menetet lezáró akcióhoz is megőrzi az ActionReportot, hogy a popup a Game Over előtt megjelenhessen. Az automatikus mentés működése megmaradt; nincs új kézi Save/Load felület vagy bizonyítatlan „Saved” visszajelzés. A mentési határok részletei: [FLOW_COVERAGE.md](v1/FLOW_COVERAGE.md).

## Ellenőrzés és következő lépés

A screenshot-exportáló sikeresen lefordította az új Flutter-felületet és 30 képet renderelt 390 × 844 logikai méreten, 2× PNG-felbontásban. A képek előkészített játékállapotok és tényleges widgetműveletek eredményei; a horgászat sorozata végiglépteti a minijátékot. Az exportáló a widgetek renderelésekor jelentkező kivételeket hibának veszi. A screenshotok vizuális átnézése alapján javítva lett többek között a műhely fülváltásakor megmaradó görgetés, a térképi akciók elhelyezése és a központi jelenetek láthatósága.

**A teljes jelenlegi tesztkör sikeres: 179 teszt, 0 hiba, 0 kihagyás; `flutter analyze`: No issues found.** A tesztek a localhostot tiltó környezet miatt a natív Flutter-motorban, a repository tényleges tesztdeklarációival futottak. A 200 seedelt szimuláció 37 502 tranzakciót és 2 288 visszatöltést végzett, mind a 28 eseményt elérve. A 30 képernyős galéria az új illusztrációkkal frissült. [Futtatás és lefedettség](VALIDATION_2026_10_12.md). Alkalmazásbuild és készülékes próba ebben a körben még nem történt.

A magasabb táborszintek háttere egyelőre a korábbi starter kit képeiből maradt; éjszaka a meglévő színszűrést kapják. A Bamboo Grove és Mangrove Shallows, valamint a krokodil, darázsfészek és majmok saját izometrikus hátteret használnak. Az összes encounter a jóváhagyott jaguáros referencia egyszerű stílusát követi: külön kígyó- és vaddisznóháttér, valamint a krokodil és majmok v2 képe, valamint a darazsak bambuszligetes v3 képe. [Hátterek és mobilképek](../../screenshots/encounter-style-v2/index.html). A Plane Wreck jelenet továbbra is a meglévő háttérválasztást használja. A generált tervlapok illusztratív tipográfiáját futásidőben az alkalmazás Arial betűkészlete és natív szövege helyettesíti.

## Jelenetjavítás — izometrikus nézet és kártyalapozás

A felhasználói visszajelzés alapján az expedíció és a jaguáros encounter új felülnézeti, izometrikus hátteret kapott. A folyóparti esemény is ezt a helyszínhátteret használja. A korábbi raszterassetek megmaradtak. Az encounter kártyái egyetlen azonos magasságú, vízszintesen lapozható `CardCarousel` sorban vannak, 390 px széles mobilon három egyidejű kártyával, előre/hátra nyilakkal és lapozásjelzővel; 520 px széles nézetben mind a négy kártya elfér. A hosszú helyzetleírás információgombbal érhető el; a választások neve és feltételei látszanak; a hatások a választás utáni összesítőbe kerülnek. Az expedíció felső panelje is tömörebb.

[6 új screenshot, köztük lapozás és információablak](../../screenshots/scene-revision-v2/index.html). A teljes 30 képes galéria is frissült. A teljes aktuális tesztkör sikeres; a régebbi 6 képes galéria előző grafikai változatot dokumentál, a 30 képes galéria a mostani állapot. [Az új hátterek promptjai](../../assets/art/ISOMETRIC_SCENE_PROMPTS.md).

## Eseménykártyák v3 — rövid döntések, utólagos összesítő

A legújabb felhasználói kérés minden eseményre vonatkozik. Az EventScene csak akciónevet, illusztrációt és eszköz/készlet/statfeltételt jelenít meg. Nincs `effect.summary`, kudarcelőnézet, sikeresély vagy SAFE címke; a tooltip és ikonválasztás sem olvassa a rejtett eredményt. A kártyák egyetlen lapozható sorban, egységes 152 logikai pixel magassággal jelennek meg normál szövegméretnél, nagyított szövegnél egységesen magasabb változatban.

A választást követően az OutcomeDialog a tényleges narratív eredményt és a statok/készlet változásait mutatja. A motor a halálos eredményt is megőrzi; a CampScreen az összesítőt a Game Over előtt jeleníti meg. A meglévő mentési séma továbbra is tárolja a reportot. A motor- és widgettesztek a halálos döntést követő eredményablakot is ellenőrzik; a teljes tesztkör sikeres.

[9 screenshot a valódi választás → eredmény folyamatból](../../screenshots/event-choices-v3/index.html).
