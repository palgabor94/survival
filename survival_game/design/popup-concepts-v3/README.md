# Popupirányok – első összehasonlítás

Két külön, 390×844 logikai méretű koncepció, 3× exporttal. A meglévő képeket és a játék betűkészletét használó Flutter-látványtervek; produkciós UI nincs módosítva ebben a lépésben.

- **A / Field Journal:** pergamenszínű belső, sötét fejléc, kéthasábos tárgykártyák.
- **B / Forest Compact:** sötétzöld belső, sűrűbb háromhasábos tárgykártyák, egyértelmű arany kijelölés.

Közös: egyetlen popupkeret, fejléc jobb felső X-szel, azonos méretű kártyák az adott nézetben, 3:2 képarány, azonos vastagságú keret kijelölve is, rövid fix mennyiségmező, külön részletező és kompakt műhelygomb.

## A választott irány következő lépése

Az akció- és receptkártyákhoz azonos sormagasságú sablont érdemes tervezni: egységes kép, két sornak fenntartott névhely, rövid információs sor és állapotsáv. A hiányzó opcionális sor nem zsugoríthatja a kártyát. A hosszabb költséglista és felszerelésfeltétel a kijelölt kártya részletezőjébe kerül; fontos költség nem veszhet el levágás vagy három pont miatt. Az események előre nem ismert jutalma csak a választás utáni eredményablakban jelenik meg. Nagy rendszerbetűnél kevesebb oszlop és nagyobb közös sablon szükséges.

Ezen az első két képen a popup vizuális irányát és a tárgykártyákat lehet kiválasztani. A változó költségű recept- és eseménykártyák külön terve a választott irányra épülhet.

Újrarenderelés: `python3 design/popup-concepts-v3/render.py` a projekt gyökeréből. A natív Flutter-export során nem volt layout-hiba. [Összehasonlító galéria](index.html).

## Elfogadott irány

A felhasználó a **B / Forest Compact** irányt választotta. Ezt félretesszük a későbbi implementáláshoz. Jelenleg csak külön látványtervek készülnek, egyesével; játékba kötés nincs engedélyezve.

Következő elkészült koncepció: [02 – Workshop / recept részletező](02-workshop-B.png). Rövid és kétsoros nevek, eltérő anyagszám, hiányzó anyag állapot; minden kártya azonos méretű. A részletes költség és a tárgy ismert funkciója a kijelölt kártya alatti blokkban szerepel. A költségek a jelenlegi recipes.json adataiból származnak.

## 03 – Esemény utáni eredmény

[03-outcome-B.png](03-outcome-B.png): rövid történeti összefoglaló, külön háttér nélküli tárgyikonok, soronkénti összesített változások, előtte–utána értékek és időfelhasználás. Bezárás a jobb felső X-szel. A példában az ismert bogyók +20 ételt és +1 rostot adnak; az 1 idő költsége −3 étel és −4 víz, ezért nettó +17 étel látszik. A kiinduló értékek illusztratívak. Ezek az információk csak a döntés után jelennek meg.

Újrarenderelés: `python3 design/popup-concepts-v3/render_outcome.py`. Önálló látványterv, nincs játékba kötve. A 390×844-es, 3× exportot vizuálisan ellenőriztük; nincs renderelési túlcsordulás.

## 04 – Tábor menü

[04-menu-B.png](04-menu-B.png): B stílus, négy egységes 48 magas navigációs sor, külön zene/hangeffekt-hangerő és bekapcsolás, haptikus kapcsoló. A navigációs ikonok háttér nélkül szerepelnek. Az új játék külön, visszafogott arany keretű sor; megnyomása a meglévő megerősítéshez vezetne. Jobb felső X, külön vissza-kártya nélkül. Az automatikus mentés állandó tájékoztató felirat, nem új mentésgomb. A hangerők szemléltető értékek.

A jelenlegi menü összes funkciója megmarad a terven. Statikus, különálló koncepció: `python3 design/popup-concepts-v3/render_menu.py`.

## 05–06 – Craft és táborfejlesztés

[05 – Craft menü](05-craft-menu-B.png): hat recept háromhasábos rácsban, egységes 3:2 képpel, kétsoros névhellyel és állapotsávval. A kijelölt Stone Axe ismert funkciója és anyagköltsége külön részletezőbe kerül. Az elkészítés egyetlen, időigényt is mutató gomb.

[06 – Táborfejlesztés](06-camp-upgrade-B.png): három azonos méretű szintkártya, a következő szint előnézete és előnyei, valamint soronkénti anyagszükséglet. A példában két fa hiányzik, ezt a követelménylista és az inaktív gomb is jelzi. A hosszabb Established Camp név nem változtatja meg a kártya méretét.

A két kép a Workshop CRAFT / CAMP füleit mutatja. Az anyagköltségek és fejlesztési előnyök a jelenlegi recipes.json alapján készültek, a készletértékek külön illusztratív példák. Statikus tervek, játékba kötés nélkül. Mindkét 390×844-es nézet 3× exportját vizuálisan ellenőriztük; renderelési túlcsordulás nem jelentkezett. Újrarenderelés: `python3 design/popup-concepts-v3/render_craft_camp.py`.

## 07 – Túlélési napló

[07-journal-B.png](07-journal-B.png): aktuális cél nyersanyaghaladással és közvetlen fejlesztési gombbal, tömör mentési mérföldkövek, dátumozott eseménylista. Egy külső keret, állandó fejléc és jobb felső X. Hosszabb napló esetén csak a tartalom görgethető. A cél- és mérföldkőblokk a jelenlegi eseménynapló javasolt bővítése; a példában szereplő készletek és események szemléltetők. Különálló látványterv, nincs integrálva. Render: `python3 design/popup-concepts-v3/render_journal.py`.

## 08 – Túlélési útmutató

[08-guide-B.png](08-guide-B.png): négy rövid túlélési alapelv, külön tutorial-választó a horgászathoz, favágáshoz, növénygyűjtéshez, vadászathoz és romokhoz. A szabályok a jelenlegi útmutató alapján készültek; a tutorial-választó javasolt új navigáció. Az egyes tutorialok külön tervet igényelnek. Egy külső keret, jobb felső X, a hosszabb tartalom görgethető lenne rögzített fejléc alatt. A 390×844-es statikus tervet vizuálisan ellenőriztük, játékba nincs kötve. Render: `python3 design/popup-concepts-v3/render_guide.py`.

## 09 – Horgászat tutorial

[09-fishing-tutorial-B.png](09-fishing-tutorial-B.png): három lépés, jelmagyarázat a játékos fehér jelölőjéhez és a zöld halzónához, nyomva tartás/jobbra és elengedés/balra ábra, külön fogási haladás. A gyakorlógomb a csali és idő nélküli meglévő tutorialhoz vezetne. A 62% szemléltető érték. Statikus koncepció, nincs integrálva. A 390×844 exportot vizuálisan ellenőriztük. Render: `python3 design/popup-concepts-v3/render_fishing_tutorial.py`.

## 10–21 – Hátralévő koncepciók

A sorozat további 12 önálló tervvel bővült. A tutorialok szabályai a GatheringSession és RuinsPuzzleScreen alapján készültek: favágás három ütés/12 mp, vadászat egy dobás/12 mp, növénygyűjtés legfeljebb három különböző növény/8 mp; a romok igazítási próbája 1 nappali idő. A jutalmak csak az eredményben derülnek ki. A jelölő aránya a timing modell jó/tökéletes tartományait szemlélteti.

- [Favágás tutorial](10-chopping-tutorial-B.png)
- [Növénygyűjtés tutorial](11-plants-tutorial-B.png)
- [Vadászat tutorial](12-hunting-tutorial-B.png)
- [Romok tutorial](13-ruins-tutorial-B.png)
- [Jelenetinfó](14-scene-info-B.png)
- [Új játék megerősítése](15-new-run-confirm-B.png)
- [Éjszakai összesítő](16-night-summary-B.png)
- [Vereség](17-defeat-B.png)
- [Sikeres mentés](18-rescued-B.png)
- [Tábor körüli gyűjtés](19-gather-menu-B.png)
- [Szünet](20-paused-B.png)
- [Próbálkozás megszakítása](21-leave-attempt-B.png)

A jelenetinfó, lezárások és éjszakai összesítő állapotértékei illusztratív példák. A vereség okát és a következő játékhoz adott tippet a tényleges állapotból kell majd megjeleníteni. Az új játék a 15-ös megerősítésen keresztül indulna. A szünet X-e folytatást jelentene; az éjszakai összesítő X-e ugyanazt az átmenetet zárná le, mint a Begin Day gomb. A vereség és mentés X-e a lezárt játék nézetéhez térne vissza. A meglévő játék nem változott.

Minden terv azonos B keretet, fejlécet, 44-es X célterületet és 46-os műveletsorokat használ. Natív Flutter-export 390×844 méretben, 3× felbontással; mind a 12 kép vizuálisan ellenőrizve, renderelési hibák nélkül. Render: `python3 design/popup-concepts-v3/render_remaining.py`.

## 22–23 – Egységes kártyarendszer

[22 – Kártyák több helyzetben](22-unified-cards-B.png) és [23 – Sok extra információ](23-card-details-B.png). Közös sablon: 112×172 logikai képpont; 2-es keret kijelölve is, 108×72 kép (3:2), 36 magas kétsoros névhely, 20 magas rövid információs sor, 24 magas állapotsáv. Minden tartalom középre igazított. A hiányzó rövid információ helye megmarad; egy vagy két kártya sem nyúlhat szélesebbre.

A hosszú költségek, felszerelésfeltételek és ismert funkciók kijelölés után külön részletezőbe kerülnek. A kétsoros neveket jelentés szerinti szóhatáron törjük; nincs szóközi törés, levágás vagy automatikus betűzsugorítás. Ennél hosszabb címhez szerkesztett rövid cím kell, teljes névvel a részletezőben. Az események előre ismeretlen jutalmai továbbra is csak az eredményben jelennek meg. Az esemény kiválasztása a részletezőt nyitná, a döntést külön gomb véglegesítené.

Szűk kijelzőn a 112-es szélesség megmarad: kevesebb oszlop vagy vízszintes görgetés szükséges, nem nyújtás. Nagy rendszerbetűnél a közös sablon minden képernyőn együtt nőhet; egyedi kártyánkénti méretezés nincs. A képen normál betűméretű 390×844-es összehasonlítás látszik. A Beacon teljes 6 anyagos költsége a recipes.json alapján szerepel, a készletek szemléltetők. A táborfejlesztési kártya a méretpróba kedvéért került a receptek mellé.

A két natív Flutter-exportot vizuálisan ellenőriztük: a rövid és hosszú címek, követelmények és költségek is elférnek. Ez látványterv, nincs integrálva. Render: `python3 design/popup-concepts-v3/render_unified_cards.py`.
