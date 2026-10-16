# Bekötött splashscreen és főmenü

2026-10-16 · Tényleges Flutter-képernyők, 390×844 logikai méret / 2× PNG. A 11–12. kép 390×932 magas telefonon készült. A gombok a működő játékra vezetnek; a későbbi menetet ábrázoló képek előkészített állapotot használnak.

1. [Splash — valódi betöltési felület](01-splash.png)
2. [Első indítás — térkép](02-main-menu-map.png)
3. [Első indítás — folyóvölgy](03-main-menu-river.png)
4. [Első indítás — romvidék](04-main-menu-ruins.png)
5. [Mentés folytatása](05-continue-journey.png)
6. [Új menet megerősítése](06-new-journey-confirmation.png)
7. [Kezdőgomb után az első menet tutorialja](07-first-run-tutorial.png)
8. [Táborból vissza a főmenübe — következő háttér](08-returned-to-menu.png)
9. [Súgó](09-survival-guide.png)
10. [Profil](10-survivor-profile.png)
11. [Magas telefon — menü és javított fade](11-tall-phone-fade.png)
12. [A fade önmagában, UI nélkül](12-unobstructed-fade.png)

A splash képének kirajzolásához a renderer megállítja a betöltési nézetet; az app nem vár mesterségesen. A többi kép a valódi menüket és navigációt használja.

```sh
LOST_CANOPY_CAPTURE_MAIN_MENU=1 LOST_CANOPY_CAPTURE_OUTPUT=screenshots/main-menu-v1 python3 screenshots/tools/capture_unified_ui.py
```
