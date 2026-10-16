# Új generált splash- és főmenüképek

**2026-10-16: a jóváhagyott változatok bekötve.** [Működés és validáció](../menu-variations-v1/IMPLEMENTATION_HU.md) · [12 tényleges screenshot](../../screenshots/main-menu-v1/README.md). Az alábbiak a korábbi tervezési kör archivált leírásai.

2026-10-16 · Két új, külön kompozíció a Lost Canopy tábori stílusával. **Látványterv; az éles app nincs átállítva.**

- [Áttekintő a pergamenes UI-val](00-overview.png)
- [Splash UI előnézet](01-splash.png)
- [Főmenü — folytatható menet](02-main-menu-continue.png)
- [Főmenü — első indítás](03-main-menu-first-launch.png)

## Tiszta hátterek

- [Splash: patak, dzsungelösvény és felfedező](art/splash_jungle_v1.png)
- [Főmenü: alkonyati tábor, lámpás és tűz](art/main_menu_camp_v1.png)

Mindkét háttér 941×1672 pixel, közel 9:16 arányban. A logó, szövegek és gombok nincsenek beleégetve. Az UI külön réteg, a képek szélességre illeszkednek.

Beépített `image_gen` eszközzel készültek, két önálló generálásban. A tábori kép adta az egyszerű facettás anyag- és színvilágot, az új jaguáros kép a kamerareferenciát. A splashhez a kanonikus karakterlap is csatolva volt. Az eredeti fájlok a generáló saját mappájában is megmaradtak; a projekt saját másolatokat tartalmaz. [Teljes promptok és referenciák](PROMPTS.md).

Az előnézetek natív Flutterrel készültek a korábbi menüterv komponenseiből, 390×844 logikai méreten, 3× PNG-ként. Mindhárom lap elrendezése ellenőrizve 320×568, 844×390 és 375×667 / 2× szöveg mellett; analyzer tiszta. Játéklogika nem változott.

Újrarajzolás:

```sh
python3 design/splash-menu-v2/render.py
```
