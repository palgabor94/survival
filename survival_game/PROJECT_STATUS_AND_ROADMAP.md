# Lost Canopy — állapot és további menetrend

**Frissítve: 2026-10-12 · Teljes kártyakészlet, tartalombővítés és nagy tesztkör kész.**

A tábor → gyűjtés/expedíció/horgászat → eredmény → tábor → éjszaka → következő nap játékfolyam működik. Craft, táborfejlesztés és automatikus mentés is része a játéknak. Az eseménykatalógus **28 eseményt**, a térkép **7 helyszínt** tartalmaz. A játék még nem rendelkezik sikeres megmentés/befejezés menettel.

**Bamboo Grove grafika v2:** a bambuszliget egyszerűbb, a jóváhagyott jaguáros stílushoz illeszkedő hátteret használ. [Háttér](assets/art/bamboo_grove_isometric_v2.png) · [Prompt](assets/art/BAMBOO_GROVE_V2_PROMPT.md).

**Encounter grafika v2:** a jaguáros referencia egyszerűbb stílusában újragenerált krokodil, darázsfészek és majmok, valamint külön kígyó- és vaddisznóháttér. Mind az öt kép bekerült a játékba. A darázsos jelenet frissített v3 változata felismerhetőbb darazsakat és külön száraz bambuszligetet kapott; [prompt](assets/art/HORNET_ENCOUNTER_V3_PROMPT.md). [Hátterek és 6 mobilkép](screenshots/encounter-style-v2/index.html) · [Pontos promptok](assets/art/ENCOUNTER_STYLE_V2_PROMPTS.md).

A jelenlegi UI minden kártyája az egységes komponensre épül, **35 saját hátteres illusztrációval**. A Forage középre komponált új képet kapott; a többi főtárgy is középre kerül. Minden képi ablak 3:2, az álló kártyák szélessége legfeljebb 160 logikai pixel. A kis HUD-ikonok megmaradtak. Az eseménykártyák egy sorban lapozhatók; a választás következményét az utána megjelenő popup közli.

[35 kártya galériája](screenshots/card-illustrations-v1/index.html) · [30 friss mobilképernyő](screenshots/unified-ui-v1/index.html) · [10 új expedíciókép](screenshots/expansion-v1/index.html) · [Implementáció](design/unified-card-ui/IMPLEMENTATION.md) · [Tesztjelentés](design/unified-card-ui/VALIDATION_2026_10_12.md).

## Elkészült játékfolyamok

| Terület | Jelenlegi állapot |
|---|---|
| Tábor | Nappal/éjszaka és táborszintek, kompakt HUD, célpanel. Nap/idő bal fent; statok és nyersanyagok jobbra. Inventory/Craft/Menu/Map a három akciókártya felett. |
| Túlélés | Health, Water, Food, Sanity; 6 nappali időegység; Forage / Explore / Rest; éjszakai esemény és alvás. Időegységenként 4 Water és 3 Food fogy. Kimerült készletek egészségvesztést okoznak. |
| Események | Adatvezérelt választások, eszköz/készlet/statfeltételek, rejtett eredmény és utólagos tényleges összesítő; halálos döntés után is. |
| Expedíció | Több megálló, hordott zsákmány; hazatérés vagy −1 időért mélyebbre haladás. Az encounter veszélye 40 → 60 → 80%-ig emelkedik. |
| Encounter | Jaguár, kígyó, vaddisznó, krokodil, darázsfészek és majmok. Eszközös, készletet fogyasztó, kockázatos és szabadon választható lehetőségek. |
| Craft | Közös adatvezérelt receptmodell: eszközök, táborelemek és fejlesztési szintek; költségek, időköltség és követelmények. Basic Rod, Stone Knife, Stone Axe, Torch, Stone Spear és passzív táborelemek. |
| Táborfejlesztés | Basic Refuge, Established Camp és fejlett tábor; saját nappali grafika, éjszakai szűrés. Leaf Bed, Water Filter, Rain Collector, Drying Rack bónuszok. |
| Horgászat | Basic Rod + csali; 2 időegység/út, 1 dobás/út, 1 csali/dobás. Kapás, akasztás és fárasztás; 1–2 Small Fish. Kilépési ablak és háttérbe kerülés alatt megáll az óra. |
| Inventory | Materials / Food / Gear fülek; étel/gyógynövény használata, eszközök hatása és műhelyparancs. |
| Mentés | Automatikus mentés és folytatás nyugodt táborból, függő eseményből, olvasatlan eredményből, expedícióból és horgászatból. Sérült mentésből friss menet indul. Nincs külön kézi Save/Load képernyő. |
| Popupok | Eredmény, helyzet részletes leírása, kilépés/új menet megerősítése, napló, súgó, game over és induláskori hiba. |

## Helyszínek és legújabb tartalombővítés

| Helyszín | Elérés / költség |
|---|---|
| Camp | Alaphelyszín; craft, készlet és pihenés. |
| Riverbank | Kezdettől elérhető; 2 idő, víz/fa/fiber/csali, mélyebben jobb zsákmány. |
| Fishing Pond | A 2. naptól vagy Basic Rod birtokában látható; tényleges horgászathoz bot és csali kell; 2 idő. |
| Plane Wreck | 1. táborszinttől játszható expedíció; 3 idő, metal scrap és hardwood. |
| Ancient Ruins | Térképen látszik, a játszható tartalom későbbi fejlesztés. |
| Bamboo Grove | **Új:** a 2. naptól; 2 idő; kezdeti hajtásgyűjtés és mélyebb bambuszbozót. |
| Mangrove Shallows | **Új:** 1. táborszinttől; 2 idő; sodródó fa gyűjtése és mélyebb gyökérmedence. |

Négy új gyűjtési esemény és három új encounter került be. A krokodil Riverbank/Mangrove Shallows, a darázsfészek Bamboo Grove/Riverbank/Plane Wreck, a majmok Bamboo Grove/Mangrove Shallows/Plane Wreck útjain fordulhatnak elő. A két új helyszín és a három új találkozás külön izometrikus jelenetképet kapott.

## Ellenőrzés

**185 teszt sikeres, 0 hiba, 0 kihagyás; analyzer tiszta.** A kártyamagasság javítása és 6 új regresszió elkészült; [friss validáció](design/unified-card-ui/CARD_HEIGHT_VALIDATION_2026_10_12.md). A szokásos Flutter tesztindító localhost-socket tiltásba ütközött, ezért ugyanazokat a repository-teszteket a natív Flutter-motorban futtattuk. [Pontos módszer és teljes logok](design/unified-card-ui/VALIDATION_2026_10_12.md).

A nagy szimuláció **200 menetben 37 502 tranzakciót és 2 288 mentés-visszatöltést** végzett, mind a 28 eseményt elérve. A widgettesztek kis/fekvő képernyőt és kétszeres szövegméretet is ellenőriznek. Javítva a nagy szövegnél túlfutó jelenet- és kártyaelrendezés, valamint a már elhasznált zsákmány kettős levonása.

A screenshotok az implementált Flutter-widgetekből készültek, 390 × 844 logikai méreten, 2× PNG exporttal. Készülékes ellenőrzés és alkalmazásbuild ebben a körben nem történt.

## További menetrend

[Friss, kód alapján ellenőrzött MVP-hiánylista és kész feltételek](MVP_AUDIT_2026_10_12.md).

1. **Készülékes végigjátszás és balansz.** Riverbank → kés/fejsze → Basic Refuge → bambusz/mangrove → Plane Wreck → fejlesztések → éjszaka; alkalmazás bezárása/folytatása. Mérni az élelem-, víz- és eszközköltségeket, az encountergyakoriságot és a menet hosszát. A szimuláció konzisztenciát igazol, az élményt nem.
2. **4. mérföldkő folytatása.** Ancient Ruins játszható tartalma, felszerelési feltétele és puzzle; további gyűjtés/vadászat minijátékok. Az új expedíciók és a Plane Wreck már működnek, ezeket bővíteni kell. Előbb látványterv a tényleges képernyőkre és popupokra, majd implementálás.
3. **Tartalom és grafika.** A 28 eseményt a starter kit 30–40 eseményes céljához bővíteni; további helyszínhez illő találkozások. Külön Plane Wreck jelenet és a magasabb táborszintek valódi éjszakai grafikája. Változatosabb időjárás és állapothatások.
4. **5. mérföldkő — teljes MVP menet.** Beacon-alkatrészek a roncsnál/romoknál, Emergency Beacon építése, végső vihar és mentés, RESCUED befejezés, menetösszesítő. Célzott 30–60 perces menet balanszolása.
5. **6. mérföldkő — kiadásra előkészítés.** Bevezető, készülékes hozzáférhetőség és teljesítmény, iOS/Android kiadási build és regresszió. Analitika/monetizáció külön termékdöntés után.

A jelenlegi határok: nincs sikeres mentés/befejezés vagy meta-progression, a romok még nem játszhatók, a horgászat Basic Rod/Small Fish szinten marad. Újabb botok, nagyobb/ritka halak és a többi tervezett minijáték későbbi munka.
