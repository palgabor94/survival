# Jóváhagyott koncepciók — a rendszer már bekötve

2026-10-15: [Működés és validáció](IMPLEMENTATION_HU.md) · [Valódi gameplay screenshotok](../../screenshots/inventory-storage-v1/README.md). Az alábbi képsor az implementálás előtti látványterv archívuma.

# Lost Canopy — hátizsák és tároló

2026-10-15 · **Pontos terv és 10 UI-látványterv. Még nincs bekötve.**

**[Tárolás és indulás — összesítő kép](00a-storage-and-packing.png)** · **[Zsákmány és hazatérés — összesítő kép](00b-overflow-and-return.png)** · **[Teljes mechanikai terv](PLAN_HU.md)**

## Mire valók?

| Rész | Szerep | MVP-javaslat |
|---|---|---|
| Hátizsák | Amit az úton használhatsz és hazahozhatsz. | 8 hely, később 12 és 16. Tárgyanként meghatározott halomméret. |
| Tároló | Biztonságos tartalék és a tábori craft forrása. | Kezdettől használható, korlátlan. Terepről nem érhető el. |
| Felszerelés | Az útra választott eszközök és ruházat. | Külön helyek; nem foglalják el a zsákot. A tartalék eszközök a táborban maradnak. |

A döntés: több ellátmányt viszel vagy több helyet hagysz a zsákmánynak. Hazatéréskor automatikusan kirakodsz. Tele zsáknál te választasz; semmi nem vész el figyelmeztetés és végleges megerősítés nélkül. Meneküléskor a teljes hordott készlet elveszhet, de a tábori készlet és a felszerelt eszközök megmaradnak.

A storage nem újabb kötelező ládaépítési feladat. Külön megépítendő, szűk tárolóval két készletet kellene állandóan rendezni. A tervezett korlát az expedíciókra vonatkozik, a nyugodt tábori teendők nem igényelnek pakolási köröket.

## Képernyők sorrendben

1. [Tábori tároló — biztonságos készlet](01-camp-storage.png)
2. [Indulási hátizsák — 4/8 hely és felszerelés](02-prepare-pack.png)
3. [Mennyiség kiválasztása — kész étel pakolása](03-transfer-quantity.png)
4. [Opcionális indulási összesítő — cél, ellátmány és költség](04-departure-confirmation.png)
5. [Teli hátizsák útközben — 8/8 hely](05-backpack-on-trail.png)
6. [Új lelet — akkumulátor és fa nem fér el](06-pending-haul.png)
7. [Megtartandó mennyiségek kiválasztása](07-choose-kept-items.png)
8. [Az otthagyott tételek végleges megerősítése](08-confirm-left-behind.png)
9. [Hazatérés — automatikus kirakodás és valódi új hozam](09-return-and-unload.png)
10. [Hátizsákfejlesztés — 8 / 12 / 16 hely](10-backpack-upgrades.png)

A képsor ugyanazt a példát követi: 8/8 helyen 6 Stone két helyet foglal. Egy Battery és három Wood újabb két helyet kérne. Az új fát otthagyva, a követ 5-re csökkentve a Battery már elfér. A végső elhagyás 3 Wood + 1 Stone, a készlet 8/8 marad. Hazaérve a csomag kiürül, a tároló növekszik, a visszavitt saját ellátmány nem számít új jutalomnak.

## Vizuális és technikai megjegyzések

A meglévő artokat és az elfogadott Flutter pergamenkomponenseket használtam; ehhez a körhöz nem kellett új generált grafika. A táskafejlesztési kártyákon most ugyanaz a meglévő táskakép szerepel, a kapacitás és név különbözteti meg a szinteket; saját három változat később készíthető a jóváhagyott mechanikához.

A kártyák ugyanazok a 112×172-es elemek, 3:2 képablakkal; a hosszabb adatok külön részleteken vannak. A kis ikonok háttere átlátszó. Jobb felső X, sötétzöld kijelölés, darabszám és helyjelző szövegesen is szerepel. Az elhagyás előtt külön tételes megerősítés kell; a normál indulás egyetlen főgomb, a teljes indulási összesítő opcionális.

A képek **natív Flutterből kirajzolt statikus koncepciók**, nem működő gameplay screenshotok. Mind a tíz 390×844-es előnézet és két összesítő widgetkivétel nélkül kirajzolódott, a renderer Dart-elemzése tiszta. A mennyiségek és stack-számok a terv példáját követik. A koncepciók készítésekor a működő játék készletlogikája még nem változott. Az azóta elkészült implementálás ellenőrzése a fent linkelt dokumentumban szerepel.

Újrarajzolás az app könyvtárából:

```sh
python3 design/inventory-storage-v1/render.py
```

A teljes terv kitér a pontos halomméretekre, terepi felszerelésre, alkatrészekre, horgászatra, csomagvesztésre, mentésre és a régi mentések veszteség nélküli átállítására is.
