# Lost Canopy — horgászati látványtervek

2026-10-15 · Az elfogadott, 390×844-es UI-koncepciók archívuma. Azóta elkészült a bekötés: [működő szabályok és ellenőrzés](IMPLEMENTATION_HU.md) · [15 tényleges gameplay screenshot](../../screenshots/fishing-progression-v1/README.md). Az alábbi mintaszámok a tervezési állapotot őrzik; a végleges értékek a bekötési dokumentumban szerepelnek.

## Áttekintők

- [Horgászat, csalik és fogási eredmények](00a-fishing-and-catches.png)
- [Fajismeret, előkészítés és mérgezés](00b-species-preparation-gear.png)

## Külön képernyők

1. [Bot és csali kiválasztása](01-fishing-loadout.png)
2. [Rovarcsali részletei és ismert halfaj-preferenciák](02-bait-details.png)
3. [Fárasztás: megtartó zóna és fogási progress](03-fishing-reeling.png)
4. [Közönséges fogás: Pataki ezüsthal](04-catch-common.png)
5. [Ritka fogás és első felfedezés: Aranyfoltos folyami hal](05-catch-new-rare.png)
6. [Veszélyes fogás: Tüskés napleső](06-catch-dangerous.png)
7. [Journal: halfajok gyűjteménye](07-fish-journal.png)
8. [Ismert halfaj és biztonságos előkészítés](08-species-and-preparation.png)
9. [Előkészítés költségeinek megerősítése](09-prepare-fish.png)
10. [Nyers és elkészített halak az Items ablakban](10-items-fish.png)
11. [Három botszint és az upgrade előnye](11-rod-progression.png)
12. [Veszélyes étel elfogyasztásának külön megerősítése](12-unsafe-meal-confirmation.png)
13. [A mérgező étkezés tényleges eredménye és kezelése](13-illness-after-unsafe-meal.png)

## Megőrzött UI-szabályok

- Pergamen, sötétzöld kijelölés, meglévő HUD és horgászati háttér. Nincs új állandó logó.
- Egységes 112×172-es alapméretű kártyák, azonos 3:2 képi ablakkal. A hosszú információ és a költség külön részletpanelen jelenik meg.
- Minden fogásnak nagy képe, fajneve, hossza, súlya és méretkategóriája van. A ritkaság és a veszély szöveggel is jelölt; nem csak színkülönbség.
- A fárasztás alatt nem derül ki előre a pontos faj, súly vagy jutalom. Ezek a sikeres fogás utáni ablakba kerülnek.
- Az ismert veszély előre látható, a tényleges változások utólag. A hal kifogása és megtartása nem automatikus mérgezés.
- A mérgezés meglévő játékbeli időre hat. Az eredményablak olvasása nem sebez.
- Megtartás és visszaengedés két külön művelet. Az X bezárás nem dobhatja el automatikusan a halat: a fogás döntése mentett, később folytatható állapot legyen.

## Tartalmi javaslat a terveken

Öt kitalált halfaj: Stream Silverfish / Pataki ezüsthal; Redfin Perch / Vörösúszójú sügér; Mud Whisker / Iszapbajusz; Spiny Sunlurker / Tüskés napleső; Goldspot Riverfish / Aranyfoltos folyami hal.

Három kezdő csali: giliszta, rovar és gyümölcs. A csali a fajeloszlást módosítja; nem garantál ritka fogást. A bot a fárasztást, kezelhető méretet és tartósságot befolyásolja. A három botszint itt vizuális szerkezeti példa, közös meglévő botillusztrációval; a két új bot saját grafikája a végleges tárgyterv része lesz.

A 8 hátizsákslot, a bot 20-as tartóssága, a fogási súlyok és a mérgező étel +8 Food értéke tervezési minta. A kapacitás és az új halfajok még nincsenek bekötve vagy balanszolva. A nyers/elkészített jelölések az ételállapotot mutatják, nem új kártyaméretet.

A biztonságos halfeldolgozás készletbe teszi az ételt, nem fogyasztja el automatikusan. Az Iszapbajusz külön tisztítási szabályt, a Tüskés napleső késes előkészítést kapna. A veszélyes fajok tulajdonságai állandók lennének.

## Assetek és ellenőrzés

[Új, saját hátteres hal-/csaliatlasz](assets/fish-and-bait-atlas-v1.png). Öt halfaj, három csali és előkészített halfilé, egyenlő cellákban. Built-in imagegen generálás, [pontos prompt és források](PROMPTS.md). A kártyák a teljes tárgyat középre igazítva mutatják.

A PNG-k a meglévő Flutter-komponensekből renderelt koncepciók, nem éles gameplay-screenshotok. Mind a 13 terv és két áttekintő renderelése Flutter-hiba nélkül befejeződött. A renderer külön statikus elemzést kapott. A produkciós játékhoz nem adtunk új funkciót, ezért gameplay-tesztek nem futottak.

Újrarenderelés az app könyvtárából:

```sh
python3 design/fishing-progression-v1/render.py
```

A vezetett első nap a felhasználó döntése szerint az MVP utolsó fejlesztési lépése lesz, a tartalmi bővítések és balanszolás után.
