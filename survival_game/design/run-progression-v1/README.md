# Menetvége és fejlődés — már bekötve

2026-10-15: [Implementáció és validáció](IMPLEMENTATION_HU.md) · [16 működő Flutter-kép](../../screenshots/run-progression-v1/README.md). Az alábbi anyag a jóváhagyott látványtervek archívuma.

# Menetvége és tartós fejlődés — pergamentes látványtervek

2026-10-15 · **Tervezési kör, még nincs bekötve a játékba.** [Pontos mechanikai terv](PLAN_HU.md).

A javaslat: közös struktúrájú vereség-/megmentési összesítő, visszanézhető XP-számítás, tartós profil és rekordok, 20 menetes archívum. Rangokkal három opcionális indulókészlet-csere oldható fel; egyszerre egy választható. Mindegyiknek ára van, a normál perk nélküli indulás megmarad.

## Áttekintők

- [Menetvége, XP, rang és profil — öt képernyő](00a-results-and-profile.png)
- [Archívum, történet, perkek és új menet — öt képernyő](00b-records-and-start.png)

## Képernyők, sorrendben

1. [Vereség: konkrét ok, 7 teljes éjszaka, elért 8. nap, +246 XP](01-lost-journey.png)
2. [Megmentés: 10 éjszaka, megmentés a 11. napon, +720 XP](02-rescued-journey.png)
3. [Tételes XP-részletek és progress bar](03-xp-breakdown.png)
4. [Rangfeloldás: Rank 3, Scavenger Kit](04-rank-unlocked.png)
5. [Profil, rekordok, következő menet beállítása](05-player-profile.png)
6. [Korábbi menetek archívuma](06-journey-archive.png)
7. [Egy menet fontos történései és a végzetes ok](07-journey-details.png)
8. [Indulókészlet választása, egységes kártyák](08-starting-options.png)
9. [Perkrészletek: pontos előny és ár](09-option-details.png)
10. [Új menet előtti megerősítés](10-new-journey.png)

A fő példában 420 korábbi XP +246 menetjutalom =666 XP, Rank 3. A három archív rekord 246 +297 +123 =666 XP. A megmentési kép külön alternatív példa ugyanarról a 420-as kiindulásról: +720 =1140 XP, Rank 4. A profil még NO PERK állapotot mutat; a választó és újmenet lapja a Scavenger Kit későbbi kiválasztását szemlélteti. Minden szám illusztratív, a mechanikai tervhez igazított.

## Vizuális szabályok

A meglévő játék pergamenfelületét, ikon- és kártyaillusztrációit használjuk. Új generált jelenet vagy ikon nem kellett, így nem változott az art style. A vereség illusztrációja a meglévő folyópart sötétítése, a megmentésé a jóváhagyott helikopteres háttér.

Sötétzöld kijelölés, rozsdaszínű hátrány/zárolás, szöveges állapotjelzések. Azonos 112×172-es kártyák 3:2 képablakkal; rajtuk csak rövid név, feltétel és állapot. A pontos készletcsere külön részletpanelen szerepel. A köztes lapokon jobb felső X van; a lezárt menet főlapján nincs bezárás élő játékba. Fix főgomb mellett a tartalom görgethető.

A profil bármikor elérhetővé tehető a Camp menüből. A perk kiválasztása csak a következő új menethez tartozik, nem alakítja át a jelenlegi készletet. Az XP már a lezárásnál rögzül, nem a popup bezárásáért jár.

## Kirajzolás és ellenőrzés

A PNG-k **natív Flutterből kirajzolt statikus koncepciók**, nem a már működő funkció screenshotjai. A gombok mintaképek, a jutalom- és profilrendszer még nincs implementálva. Játéklogikai fájl nem változott, új gameplay tesztet ebben a körben nem futtattam.

Mind a tíz lap 390×844 logikai méreten, háromszoros PNG felbontásban készült. Mindegyik widgetkivétel nélkül kirajzolódott 320×568-as kis telefonon, 844×390-es fekvő nézetben és 375×667-es méreten 2× betűskálával, csökkentett animáció mellett is. Ez elrendezési ellenőrzés, nem helyettesíti a fizikai telefonos vagy képernyőolvasós tesztet. A renderer Dart-elemzése tiszta.

Újraexportálás az app könyvtárából:

```sh
python3 design/run-progression-v1/render.py
```

Következő lépés elfogadás után: strukturált menetszámlálók és mentés, utána közös összesítő/profil, végül az újmenet-választó és a készletcserék balansza. A teljes tartalomhangolás és vezetett első nap ez után következik.
