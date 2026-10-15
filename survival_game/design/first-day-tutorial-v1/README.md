# Vezetett első nap — terv és nyolc látványterv

2026-10-15 · **A következő fejlesztési feladat a tutorial, utána a balansz.** A sorrendet a menetrendben is átvezettük. A tutorial még nincs bekötve; az alábbi PNG-k ellenőrizhető, natív Flutterből kirajzolt koncepciók. [Pontos működési és mentési terv](PLAN_HU.md).

## Áttekintők

- [Indulás, gyűjtés, evés és craft](00a-first-day-basics.png)
- [Csomag, hazatérés, éjszaka és második nap](00b-first-expedition-and-night.png)

## Képek külön

1. [Welcome — vezetett vagy szabad kezdés](01-welcome.png)
2. [Első gyűjtés — coach a tényleges tábori felületen](02-first-forage.png)
3. [A gyűjtött ételt külön meg kell enni](03-eat-your-find.png)
4. [Első craft — a meglévő műhelyen](04-first-craft.png)
5. [Pakolás — a valódi készletválasztón](05-first-pack.png)
6. [Hazatérés — a meglévő expedíciós döntésen](06-return-home.png)
7. [Első éjszaka — a rendes eseményfelületen](07-first-night.png)
8. [Első nap teljesítve — Day 2](08-first-day-complete.png)

Hat ellenőrzőpont: gyűjtés, étkezés, eszközcraft, pakolás/indulás, hazatérés és túlélt éjszaka. A coach rövid, egyetlen aktuális célt mutat, Later és Skip guide lehetőséggel. Az események jutalmát továbbra is csak a választás után látjuk. A horgászat, ismeretlen növények, betegségek, javítás, megtelt csomag és mentés később, az első használatkor kap rövid súgót.

A készlethelyzethez igazodó segítség kell: más perk, más választás vagy elköltött alapanyag nem okozhat lezárt tutoriallépést. A célpozíciók a bekötéskor a tényleges gombhoz igazodnak. Ezek a coach-elhelyezések statikus kompozíciók, nem már működő érintési célkövetés. Kis/fekvő/nagy betűs nézetben a koncepció görgethető kompakt panelt használ; a végső célkiemelés és képernyőolvasós viselkedés a bekötés feladata.

## Mi lett ellenőrizve?

A renderer a meglévő motor valódi tranzakcióival állítja elő a mintanap állapotait: normál kezdés → berry_patch/gather → egy Ember Berries étkezés → Torch craft → Riverbank csomag → river_supplies → hazatérés → két pihenés → fire_dying/torch → alvás. Rögzített eseményválasztást használ, és ellenőrzi, hogy ténylegesen Day 2 és egy túlélt éjszaka következik. Nincs hozzáadott kezdőcsomag, ingyenes eszköz vagy tutorial-XP. A vezetést választó játék első nyitóeseményeinek bekötése külön feladat.

Mind a nyolc lap kirajzolva 390×844 logikai telefonméreten, 3× PNG felbontásban. Elrendezés ellenőrizve mindegyiken: 320×568 kis telefon, 844×390 fekvő nézet, illetve 375×667 és 2× betűméret, csökkentett animáció mellett. A koncepció Dart-elemzése tiszta. Ez nem a kész tutorial gameplay tesztje; játéklogikai vagy app-UI fájl ebben a körben nem változott.

Újrarajzolás az app könyvtárából:

```sh
python3 design/first-day-tutorial-v1/render.py
```

A meglévő, elfogadott tábori/jelenetképek, tárgyikonok és pergamenkomponensek szerepelnek. Új generált artworkre ehhez a tervhez nem volt szükség.
