# Splashscreen és főmenü — látványterv

**2026-10-16: a jóváhagyott változatok bekötve.** [Működés és validáció](../menu-variations-v1/IMPLEMENTATION_HU.md) · [12 tényleges screenshot](../../screenshots/main-menu-v1/README.md). Az alábbiak a korábbi tervezési kör archivált leírásai.

2026-10-15 · **Koncepció, nincs bekötve.** A meglévő Tier 2 tábori hátteret, valódi pergamentextúrát és a játék tipográfiai/színrendszerét használó natív Flutter-kompozíciók. Nincs újonnan generált háttér vagy végleges logó; a címlogó tipográfiai javaslat.

- [A három terv együtt](00-overview.png)
- [Splashscreen](01-splash.png)
- [Főmenü — mentett menet folytatása](02-main-menu-continue.png)
- [Főmenü — legelső indítás](03-main-menu-first-launch.png)

## Tervezett működés

A splash az induló betöltést kíséri; nem kell mesterséges várakoztatás. A folyamatjelző csak akkor százalékos, ha a betöltési lépések ténylegesen mérhetők; másként egyszerű folyamatos jelzés. A háttér teljes szélességre illesztett, sötét átmenettel felül és alul.

A főmenüben a kép nagy része látható marad. Meglévő mentésnél a Continue journey az elsődleges, mellette egy rövid nap/helyszín-kártya. A New journey meglévő megerősítést igényel majd, és a tartós profilt megőrzi. Első indításkor csak Begin your journey jelenik meg; annak megnyomásakor indulhat a most bekötött elsőmenetes tutorial kérdése. A mentést nem írjuk felül pusztán a főmenü megnyitásával.

A további sorok: Survivor profile, Settings és How to survive. A hangeffektek, zene és haptic a Settings részbe vezethetők át; mentés hiányában a profil üres, érthető kezdőállapotot mutasson. Az itt megjelenített Day 5 / Jungle Refuge csak mintaadat; implementáláskor a valódi mentésből kell származnia.

A tipográfiai logó krém és visszafogott arany; a kiválasztás/elsődleges gomb sötétzöld. A pergamenfelületek a meglévő játékkomponensekből jönnek. Nem került HUD vagy akciókártyasor a nyitómenübe.

## Fájlok és ellenőrzés

390×844 logikai méret, 3× PNG. Mindhárom koncepció elrendezése ellenőrizve 320×568, 844×390, illetve 375×667 és kétszeres szöveg mellett. Kevés helyen a tartalom görgethető; nincs kilógási hiba. Dart analyzer tiszta. Ez vizuális ellenőrzés, nem működő főmenü-teszt.

```sh
python3 design/splash-menu-v1/render.py
```

A szerkeszthető terv a `render.dart`; a gombok ebben csak bemutatóelemek. A natív renderer a meglévő artot komponálja, képgeneráló eszköz nélkül.
