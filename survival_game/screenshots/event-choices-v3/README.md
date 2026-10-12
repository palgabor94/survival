# Lost Canopy — eseménykártyák v3

**2026-10-12 · 9 friss Flutter-screenshot, az új saját hátteres kártyakészlettel.**

[Számozott galéria](index.html)

Minden esemény ugyanazokat az alacsony, normál szövegméretnél fix 152 logikai pixel magas kártyákat használja, egyetlen lapozható sorban. Nagyított rendszerszövegnél az egységes kártyamagasság a szövegmérethez igazodik. A kártyákon csak az akció neve, illusztrációja és a szükséges eszköz/készlet/statfeltétel látszik. Nincs előzetes jutalom, statváltozás, kudarc vagy százalék. A tooltip és az akadálymentes felirat sem tartalmaz eredményadatot; az automatikus ikonválasztás az akcióból származik.

A valódi választás után a meglévő OutcomeDialog történetszöveget és tényleges változásokat közöl. Menetet lezáró választásnál az eredmény-popup megelőzi a Game Over ablakot. Az olvasatlan eredmény a meglévő mentési struktúrában tárolható. A játék hatásai és sorsolása nem változott.

1. [Encounter — rövid döntési kártyák](01-encounter-choices.png) — Három fix, 152 logikai pixel magas kártya, előre jelzett eredmény nélkül.
2. [Encounter — negyedik döntés](02-encounter-swiped.png) — A sor lapozható; a kártyákon csak az akció és feltétele látszik.
3. [Encounter — választás után](03-encounter-result.png) — A ténylegesen megnyílt eredmény-popup: mi történt és mi változott.
4. [Gyűjtés — választás előtt](04-forage-choices.png) — Ugyanaz a rövid kártyarendszer minden eseménynél.
5. [Gyűjtés — eredmény](05-forage-result.png) — A narratív összesítő és a statok/készlet tényleges változása.
6. [Éjszaka — döntések](06-night-choices.png) — Nincs számszerű jutalom-, veszteség- vagy esélyelőnézet.
7. [Éjszaka — eredmény](07-night-result.png) — Az összesítő csak a kiválasztott akció után jelenik meg.
8. [Menetet lezáró döntés — eredmény](08-fatal-result.png) — A sikertelen választásról is megjelenik az összesítő.
9. [Game Over — az összesítő után](09-game-over-after-result.png) — A menet lezárása az eredmény-popup folytatása után látszik.

Az exportáló a valódi alkalmazásban kattintja végig az encountert, gyűjtést, éjszakai és sikertelen választást, valamint az eredmény utáni Game Over állapotot. A teljes tesztkör külön lefutott: 179 sikeres teszt, tiszta analyzer. [Tesztjelentés](../../design/unified-card-ui/VALIDATION_2026_10_12.md). Újragenerálás: `LOST_CANOPY_CAPTURE_EVENT_CHOICES=1 python3 screenshots/tools/capture_unified_ui.py`.
