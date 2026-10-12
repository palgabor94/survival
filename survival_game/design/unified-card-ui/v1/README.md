# Lost Canopy — egységes kártyás UI, v1 látványtervek

Ezek generált tervek a LOST_CANOPY_CARD_SYSTEM_PACK alapján. A jóváhagyást követően elkészült az egységes Flutter UI implementációja a jelenlegi játék képernyőire, popupjaira és induláskori állapotaira. Az implementált felület [30 számozott képernyőképe](../../../screenshots/unified-ui-v1/index.html) külön galériában látható. A teljes automatizált tesztkör előtt a korábbi kérés szerint megálltunk; az implementáció és az ellenőrzés részletei: [IMPLEMENTATION.md](../IMPLEMENTATION.md).

## Elkészült tervlapok

- [Tábor és Explore térkép](01-camp-map.png)
- [Craft és táborfejlesztés](02-craft-build.png)
- [Folyóparti gyűjtés és encounter — egységesített HUD](03-gathering-encounter-v2.png)
- [Expedíciós döntés és éjszakai esemény](04-expedition-night.png)
- [Horgászat — indulás és fárasztás](05-fishing.png)
- [Inventory és eredménykártya](06-inventory-outcome.png)
- [Game Over és Survival Journal](07-gameover-journal.png)
- [Tábor menü, új menet, horgászatból kilépés és útmutató](08-popups.png)
- [Induláskori betöltés és betöltési hiba](09-loading-error.png)

A craft, táborfejlesztés, expedíció és automatikus mentés tényleges állapotai és a tervlapok kapcsolata: [FLOW_COVERAGE.md](FLOW_COVERAGE.md). A betöltési hibakép az alkalmazás induláskori hibáját mutatja; nem mentési hibaüzenet. A jelenlegi mentési réteg nem közöl siker-/hibastátuszt a UI-val.

## Közös irány

Nagy, flat-shaded tárgyillusztrációk; közös lekerekített, enyhén domború kártyakeret; rövid cím, feltétel, költség/jutalom és státuszcímke. Zöld: biztonságos; kék: navigáció/idő; homok/fa: eszköz és építés; rozsda: kockázat; szürke: zárolt. A státuszt felirat és ikon is jelzi.

A közös HUD célja: logó nélkül, bal fent nap/idő/időjárás, jobb fent négy stat; ikon és szám ugyanabban a felső sorban, alatta jobbra igazított csík, a nyersanyagok ez alatt. A 03-as tervhez külön v2 készült a HUD egységesítésével; az eredeti vázlat is megmaradt.

A központi jelenet maradjon jól látható. Az Inventory a döntési kártyák fölött jelenik meg. Négy választás kis kijelzőn 2×2 kártyában jelenhet meg, olvasható szöveggel.

A generált képek rövidített szövegei és bemutató értékei nem módosítják a játék szabályait. A végleges szövegeket és költségeket az alkalmazás adatfájljaiból kell betölteni. A képbe rajzolt szöveg/keret nem kész futásidejű asset; az implementációban a közös Flutter-kártyakomponens adja a szöveget és állapotot.

A generálási promptok: [PROMPTS.md](PROMPTS.md).

A jelenlegi UI áttekintése, a komponensszabályok és a javasolt implementációs sorrend: [DESIGN_REVIEW.md](DESIGN_REVIEW.md).

## A mockupok értelmezése

A generált képek a kártyacsalád, illusztrációk és képernyőhierarchia vizuális irányát mutatják. Az egyes lapok képaránya és díszítése kissé eltérhet; a Flutter-elrendezést a dokumentált közös komponensekhez kell igazítani. A HUD bemutatóértékei nem játékmentések: például a 07-es lapon a napló átvett egy 0 Health értéket és 5/5 időjelzést, amelyek nem követendő játékállapotok. A 04-es loot-sáv csali helyén halillusztrációt kapott; a végleges felület a tárgyhoz tartozó helyes ikont használja.

## Aktuális eseménykártya-szabály — v3

A legújabb felhasználói kérés felülírja az eredményelőnézetet mutató tervkártyákat: minden eseménynél rövid, fix magasságú döntési kártyák jelennek meg, csak akcióval és követelménnyel. Jutalom, veszteség és sikeresély nem látszik előre. A tényleges eredményt a választás után popup foglalja össze. [Aktuális screenshotok](../../../screenshots/event-choices-v3/index.html).
