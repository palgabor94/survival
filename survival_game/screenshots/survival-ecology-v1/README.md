# Új túlélőrendszer — valódi Flutter-képernyőképek

390×844-es mobilnézet, kétszeres exportfelbontás. A tényleges alkalmazás widgetjei, reprodukálható mintamenetekkel. Az esemény és az ellenszer képe valódi motorállapotot használ; a napzáró tényleges alvás utáni állapotot mutat.

1. [Tábor: négy aktív állapot](01-camp-conditions.png)
2. [Mérgezés részletei](02-poison-details.png)
3. [Élelmek és kezelések](03-food-and-treatment-items.png)
4. [Ismeretlen faj részletlapja](04-species-details.png)
5. [Műhely](05-survival-workshop.png), [új receptek](05b-survival-recipes.png), [ellenszer költségei](05c-antidote-recipe-details.png)
6. [Békás esemény](06-frog-encounter.png)
7. [Ellenszer használatának eredménye](07-antidote-outcome.png)
8. [Gyűjtési próba előnézete](08-foraging-ready.png)
9. [Alvás után megmaradt állapotok](09-day-end-conditions.png)
10. [Journal és fajismeret](10-jungle-knowledge.png)
11. [Szárítás megerősítése](11-dry-by-fire-confirmation.png)

A normál futásban csak a valóban aktív állapotok jelennek meg. Az élelmek nem romlanak; a tárolt adagokat a játékos használja el.

Ellenőrzés: 355 teszt sikeres, 0 hibás. Köztük 18 új motorteszt és 6 új felületi teszt. A 42-es és 77-es seed teljes menete megszerzett nyersanyagokkal elérte a mentést. A végleges nehézséghez még emberi játékpróba szükséges.

Újrarenderelés:

```sh
LOST_CANOPY_CAPTURE_ECOLOGY=1 LOST_CANOPY_CAPTURE_OUTPUT=screenshots/survival-ecology-v1 python3 screenshots/tools/capture_unified_ui.py
```
