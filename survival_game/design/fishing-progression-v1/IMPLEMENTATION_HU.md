# Horgászat — bekötött első változat

2026-10-15. Az elfogadott pergamentes tervek alapján. [15 tényleges mobilkép](../../screenshots/fishing-progression-v1/README.md).

## Halfajok, csalik, botok

Öt állandó tulajdonságú, kitalált faj került a játékba: Stream Silverfish, Redfin Perch, Mud Whisker, Spiny Sunlurker és Goldspot Riverfish. A korábbi `small_fish` készletazonosító megmaradt; most a Stream Silverfish fajhoz tartozik. A régi készlet nem vész el.

| Faj | Felszerelés / elérés | Elkészítve Food | Nyers veszély |
|---|---|---:|---|
| Stream Silverfish | Bármely bot | 25 | Tábori gyors sütés/evés megmaradt. |
| Redfin Perch | Bármely bot | 32 | Táborban süthető/ehető vagy előre elkészíthető. |
| Mud Whisker | Reinforced Rod vagy jobb | 36 | Előkészítetlenül +8 Food, Poisoned I. |
| Spiny Sunlurker | Reinforced Rod vagy jobb, 3. naptól | 34 | Előkészítetlenül +8 Food, Poisoned II. Kés/machete kell a biztonságos előkészítéshez. |
| Goldspot Riverfish | River Rod, 3. naptól | 48 | Ritka, nagyobb halfaj; táborban süthető/ehető. |

A Drying Rack meglévő +10 Food bónusza a biztonságosan fogyasztott halakon megmarad. A nyers mérgező étel nem kapja meg ezt a bónuszt. Minden új fogás egyetlen, saját méretű hal: a perfect landing a fogás minősége, nem duplikálja a halat.

A három csali relatív faj-súlyai; a nem megfelelő bothoz/naphoz kötött fajokat a sorsolás előbb kizárja, majd a többit újranormalizálja:

| Csali | Silverfish | Redfin | Mud Whisker | Sunlurker | Goldspot |
|---|---:|---:|---:|---:|---:|
| Worms | 65 | 22 | 8 | 4 | 1 |
| Insects | 22 | 43 | 10 | 20 | 5 |
| Fruit | 25 | 12 | 25 | 13 | 25 |

A bot fejlődése:

| Bot | Fárasztó zóna | Tartósság | Gyártás |
|---|---:|---:|---|
| Basic Rod | ×1 | 12 | Meglévő 2 Wood + 3 Fiber, 1 idő. |
| Reinforced Rod | ×1,12 | 20 | Tier 1, Basic Rod, 4 Wood + 5 Fiber + 1 Stone, 1 idő. |
| River Rod | ×1,22 | 30 | Tier 2, Reinforced Rod, 3 Hardwood + 2 Metal Scrap + 5 Fiber, 1 idő. |

A ritka Goldspot a zónát ×0,88-cal szűkíti. Az Exhausted induláskor rögzített ×0,9-e megmarad. A tényleges zóna látható; sikeres fárasztás után nincs újabb rejtett kudarc-dobás. A botot Items → Gear vagy a horgászati előnézet Change gombja választja. Dobásonként egy tartósság fogy, a törött bot javítható a saját receptjének költségéért.

Insect Bait: 2 Fiber + 1 idő → 2 adag. Fruit Bait: 1 Ember Berries + 1 idő → 3 adag. A csalik többször gyártható készletek. A meglévő gilisztás `bait` eseményforrások megmaradtak.

## Fogás, fogyasztás és mentés

A tóhoz vezető út továbbra is 2 idő. A dobás ezen felül egy kiválasztott csalit és egy botállapotot fogyaszt; nem von le újabb nappali időt. Egy úton egy dobás van. A látványtervben szereplő példaköltség helyett a működő felület ezt a tényleges szabályt írja ki.

A faj és a méret egyszer, a dobás indításakor dől el, és onnantól a session része. Csali- vagy botváltás aktív dobás közben tilos. A sikeres fogási ablak nagy képpel, fajnévvel, ritkasággal, hossz/súly/méret adatokkal és veszélyjelzéssel jelenik meg. Megtartás vagy visszaengedés után a faj bekerül a Journalba. Az X bezárás nem számolja el egyik döntést sem, a fogás később újranyitható. A megtartás egyszer adja a halat, a visszaengedés nem ad ételt és nem téríti vissza a csalit.

Az új mentések a teljes fárasztást is megőrzik: kurzor, cél, progress, belső idő, minőség, kiválasztott csali és bot, kifogandó faj/méret. Aktív dobás szüneteltetve áll vissza; explicit Resume kell hozzá. Háttérbe kerülés és az útmutató megnyitása alatt a próba nem halad. A korábbi, session-adatok nélküli mentések a régi megszakított-dobás szabályával töltődnek be. A fogási metaadat az eredményriportban is mentett.

Biztonságos előkészítés: táborban 1 nyers hal + 1 Wood + 1 idő → 1 kész adag. A tüskés halhoz kés vagy machete szükséges. Külön megerősítő ablak mutatja az anyagokat, az időt és a feltételt. A kész étel táborban vagy nyugodt expedíciós megállónál, 0 időért ehető. A nyers hal kezelése/sütése tábori művelet.

Az előkészítetlen veszélyes hal külön megerősítést kér. A mérgezés az étkezéskor keletkezik, de csak a következő elköltött időben sebez; az ablak olvasása nem okoz sebzést. A meglévő ellenszer és gyógynövényes elsősegély működik rá. A halfogás önmagában nem mérgez.

## Ellenőrzés és fennmaradó munka

16 új motorteszt és 8 új felületi teszt készült: faj-/bot-/napkapu, csali-eloszlás, pontos költség, megszakítás és mentés, a hal duplázásának tiltása, visszaengedés, mérgezés, feldolgozás, 320-as telefon, fekvő nézet és kétszeres szövegméret. A teljes natív tesztfutás 379 sikeres, 0 hibás, 0 kihagyott teszt; a Dart analyzer tiszta.

A 8 slotos hátizsák és a külön tábori storage a következő készletmérföldkő része; nem került be félkész kapacitáskorlát. Az aktuális felület nem mutat fiktív slotértéket. Az egyedi halméret a fogási eredményben és az olvasatlan riportban marad meg; a készlet fajonként darabszámot tárol. Készülékes, emberi horgászpróba és az új élelmi hozam balanszolása még szükséges.
