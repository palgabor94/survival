# Items és közös popupok – 2026-10-13

A `CardDeck` az utolsó, hiányos sorban is fenntartja az üres kártyahelyeket. A négy anyagból álló listában így a Bait mérete megegyezik a Wood, Stone és Fiber kártyáéval; a javítás a többi kártyás listára is érvényes.

A `CanopyDialog` egyetlen panelkeretet rajzol. A fejléc és a 48×48 érintési területű, arany X gomb a görgethető tartalmon kívül van. Az X haptikus visszajelzést ad és bezárja az adott popupot. Az Items, menü, napló, útmutató, tevékenységválasztó, jelenetleírás és horgászoktató külön vissza/bezárás kártyája megszűnt. A használat, barkácsolás, gyakorlás és valódi döntések kártyái megmaradtak.

Az inventory címe `CAMP ITEMS`. A tábor alsó négy gombja egységes szélességű és jobbra igazított.

Ellenőrzés: **324 sikeres teszt, 0 hibás, 0 kihagyott**, analyzer hibamentes. Két új regressziós teszt ellenőrzi a negyedik anyagkártya méretét és a görgetés közben helyben maradó fejléc/X gombot, valamint az állapotváltozás nélküli bezárást. A meglévő tesztek a kis mobilos, fekvő és nagy betűméretes elrendezéseket, illetve a popupok érintett játékfolyamatait is ellenőrzik.

[Friss gameplay képek](../../screenshots/items-popup-v2/index.html) · [Tesztadatok](test-results.json) · [Teljes log](test-run.log) · [Analyzer](analyze.log)
