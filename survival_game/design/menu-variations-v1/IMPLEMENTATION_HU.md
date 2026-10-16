# Splash és főmenü — bekötés

2026-10-16 · A jóváhagyott splash és a három főmenüháttér bekötve. Az új ikon külön generált jelölt; a launcher ikonokat még nem cseréltük le.

## Indulás és navigáció

A valódi alkalmazás a mentés betöltése alatt a karakteres ösvényképet mutatja. Nincs kötelező várakozás vagy kitalált százalék: a tényleges aszinkron betöltés végét a főmenü követi. Hibánál újrapróbálható ugyanitt.

Az első még el nem indított menetnél BEGIN YOUR JOURNEY látható. A főmenü böngészése és az automatikusan létrehozott üres mentés nem indítja el a tutorialt, nem ad XP-t és nem archivál menetet. Az indulás jelzője ugyanabban a v3 snapshotban mentődik, mint a játék. A régi mentések alapból már megkezdettnek számítanak, ezért folytathatók. A profilból kezdeményezett első indulás is megőrzi az eredeti elsőmenetes tutorialt.

Megkezdett menetnél CONTINUE JOURNEY; lezárt menetnél VIEW JOURNEY SUMMARY. A tényleges nap/helyszín a mentésből jön. NEW JOURNEY a meglévő megerősítést, egyszeri archiválást és tartós profilt használja. Visszalépés nem változtatja meg a menetet. A profil, a súgó és a zene/hangeffekt/haptic beállítások meglévő komponensek. A tábori menü MAIN MENU sora visszavezet a főmenübe.

Az injektált teszt-/exportmotorok alapból közvetlenül a játékot nyitják. A `showMainMenu: true` explicit lehetőség ott is bekapcsolja a főmenüt; a valódi app alapból használja.

## Háttér és gomb

A → B → C → A, menübe visszatéréskor és új alkalmazásindításkor. Az utolsó háttér külön kozmetikai Preferences-jelzőben tárolódik; ennek hibája nem blokkolja a mentés betöltését. A menü használata, súgó vagy beállítások olvasása közben nincs háttérváltás. A splash külön képe állandó.

A fő gomb teljesen világos pergamen, sötétzöld szöveggel és nyíllal, árnyékkal; nincs zöld alapkitöltés. Mindhárom képen ugyanaz a komponens.

A hátteret a SceneArtwork a kép valódi kirajzolt téglalapján maszkolja. A felső és alsó, 140 logikai pixelig nyúló, több állomású átmenet a sötétzöld alapszínbe olvad. Ez a kép tényleges szélén is nulla fedettségig fut, ezért a magas kijelzőn maradó felső/alsó hely nem éles téglalapszéllel kezdődik. A szöveges UI a maszkon kívül van. A többi játékjelenet meglévő alap fade-beállítása megmaradt.

## Validáció

**475 teszt sikeres, 0 hiba és 0 kihagyás; analyzer tiszta.** Tizenhárom új ellenőrzés: tartós rotáció, el nem indított mentés, Begin → tutorial → visszatérés → Continue, megerősítés visszavonása, profilból indított első tutorial, súgó/beállítások, öt képernyőméret és kétpixeles toleranciájú tényleges képperem-színmérés. Régi függő eseményt a főmenü nem old fel; csak a folytatás után nyílik meg.

A teljes tesztkör a valódi repository tesztjeit futtatta natív Flutter-motorban. A táborpózokat ellenőrző meglévő teszt képcache-átöröklését explicit cache-tisztítás javítja. Készülékes OS-launch, audio meghallgatás és build-ellenőrzés külön kiadás előtti feladat marad.

[12 tényleges screenshot](../../screenshots/main-menu-v1/README.md). A korábbi látványtervek archiváltak. A teljes rendszer balanszolása továbbra is a következő játékmeneti feladat.
