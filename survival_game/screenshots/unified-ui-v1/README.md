# Lost Canopy — elkészült UI, sorban

**Aktuális esemény-UI: [rövid, soronként azonos magasságú kártyák és utólagos eredmény-popup](../event-choices-v3/index.html).**

**2026-10-12 · 30 friss képernyőkép, saját hátteres kártyákkal.**

[42 külön illusztráció](../card-illustrations-v1/index.html) · [Új expedíciók és encounterek](../expansion-v1/index.html) · [221 sikeres teszt és tiszta analyzer](../../design/rescue-milestone/VALIDATION.md).

Az expedíció és az encounter a felülnézeti, izometrikus változatra frissült; az encounter egysoros kártyái lapozhatók. [A javítás 6 képe](../scene-revision-v2/index.html).

[Az összes kép számozott galériája](index.html) · [9 shelter-változat](../camp-variants-v2/index.html) · [32 rescue kép](../rescue-milestone-v1/index.html)

A képek az implementált Flutter-felületből készültek, 390 × 844 logikai mobilméreten, 2× exporttal (780 × 1688 PNG). Előkészített játékállapotok és tényleges UI-műveletek mutatják a képernyőket; nem generált látványtervek és nem készülékfotók. A horgászati sorozat valóban végiglépteti a minijátékot. A hosszabb panelek kezdő görgetési pozíciója látszik.

1. [Nappali tábor](01-camp-day.png) — Kompakt HUD, célpanel, Inventory a három akciókártya felett.
2. [Inventory — nyersanyagok](02-inventory-materials.png) — Anyagkártyák a tényleges készletmennyiséggel.
3. [Inventory — étel](03-inventory-food.png) — Ételfogyasztás, főzés és gyógyítás.
4. [Inventory — felszerelés](04-inventory-gear.png) — Birtokolt eszközök és hatásuk.
5. [Explore térkép](05-explore-map.png) — Helyszínválasztás és utazási kártyák.
6. [Zárolt helyszín](06-explore-locked.png) — Követelmény és tiltott utazás.
7. [Craft — elkészíthető recept](07-craft.png) — Illusztrált műhely, receptlista és anyagköltség.
8. [Craft — zárolt recept](08-craft-locked.png) — Részletezhető recept, olvasható követelménnyel.
9. [Táborfejlesztés](09-camp-upgrade.png) — Kijelölt szint előnézete és építési költsége.
10. [Zárolt táborfejlesztés](10-camp-upgrade-locked.png) — A későbbi szint követelményei.
11. [Basic Refuge tábor](11-camp-tier-1.png) — A megépített első fejlesztési szint.
12. [Folyóparti esemény](12-riverbank-event.png) — Gyűjtési lehetőségek és választási kártyák.
13. [Expedíció — tovább vagy haza](13-expedition.png) — Hordott zsákmány, veszély és két döntés.
14. [Jaguáros találkozás](14-encounter.png) — Felszereléshez és készlethez kötött döntések.
15. [Éjszakai tábor](15-camp-night.png) — Éjszakai háttér és napi állapot.
16. [Éjszakai esemény](16-night-event.png) — Éjszakai döntési kártyák.
17. [Horgászat — dobás előtt](17-fishing-ready.png) — Bot, csali és induló akció.
18. [Horgászat — várakozás](18-fishing-waiting.png) — Bedobott csali, várakozás a kapásra.
19. [Horgászat — kapás](19-fishing-bite.png) — Akasztás a reakcióablakban.
20. [Horgászat — fárasztás](20-fishing-reeling.png) — Zöld célzóna, jelző és tartva működő vezérlés.
21. [Horgászat — kilépés megerősítése](21-fishing-exit.png) — Megállított időzítő és a csali következménye.
22. [Horgászat — fogás eredménye](22-fishing-result.png) — A végigjátszott minijáték tökéletes fogása.
23. [Eredményablak](23-outcome.png) — Valós akcióeredmény és erőforrás-változások.
24. [Tábor menü](24-camp-menu.png) — Napló, útmutató és új menet.
25. [Survival Journal](25-journal.png) — A menet naplója a közös popupkeretben.
26. [Túlélési útmutató](26-guide.png) — Görgethető súgó és automatikus mentés leírása.
27. [Új menet megerősítése](27-restart-confirmation.png) — A korábbi menet felülírására figyelmeztető döntés.
28. [Game Over](28-game-over.png) — A lezárt menet és újrakezdés.
29. [Induláskori betöltés](29-loading.png) — Várakozás a menet betöltésére, HUD nélkül.
30. [Induláskori betöltési hiba](30-loading-error.png) — Újrapróbálható induláskori hibaállapot.

Az exportáló: [capture_unified_ui.dart](../tools/capture_unified_ui.dart), indító: [capture_unified_ui.py](../tools/capture_unified_ui.py). A screenshotkészítés fordítja és rendereli a felületet; a teljes automatizált tesztkör sikeres és az analyzer tiszta. Alkalmazásbuild és készülékes próba ebben a körben nem készült.

[Implementációs állapot](../../design/unified-card-ui/IMPLEMENTATION.md) · [Jóváhagyott látványtervek](../../design/unified-card-ui/v1/README.md)
