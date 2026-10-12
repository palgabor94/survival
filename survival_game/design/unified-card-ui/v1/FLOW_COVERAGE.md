# Craft, táborfejlesztés, expedíció és mentés — tervlefedettség

**Frissítve:** 2026-10-12. A kód és az adatfájlok alapján; az implementált UI-ról 30 új képernyőkép készült. A teljes tesztkör és alkalmazásbuild még hátravan.

## A munka állapota

Az egységes UI átírása a látványtervek jóváhagyása után elkészült. A CraftScreen, a táborfejlesztés, az ExpeditionScene, a FishingScreen és az induláskori betöltési felület is a közös illusztrált komponenseket használja. A generált tervlapok továbbra is látványtervek; a tényleges Flutter-felületet a [számozott screenshotgaléria](../../../screenshots/unified-ui-v1/index.html) mutatja. Az állapotlefedettség és a még hátralévő ellenőrzés: [IMPLEMENTATION.md](../IMPLEMENTATION.md).

## Képernyők és jelenlegi állapotok

| Játékfunkció | Látványterv | A végleges UI-ban megőrzendő állapotok |
|---|---|---|
| Craft / kiválasztott recept | 02-craft-build.png, bal oldal | Kijelölt tárgy, tényleges hatás, anyagonként birtokolt/szükséges mennyiség, időköltség. |
| Craft / elérhetőség | 02-craft-build.png, bal oldal | READY: elkészíthető; OWNED: már birtokolt; LOCKED: a konkrét tiltási ok olvasható. A zárolt recept kiválasztható részletezésre, az elkészítés nem indítható. |
| Táborfejlesztés | 02-craft-build.png, jobb oldal | Aktuális szint, kijelölt szint előnézete, költség és hatás. A következő szint építhető; a megszerzett szintek OWNED, a későbbiek követelménnyel zároltak. |
| Expedíció / tovább vagy haza | 04-expedition-night.png, bal oldal | Aktuális helyszín és lépés, hordott loot, aktuális veszély/esély, továbbhaladás tényleges költsége. |
| Expedíció / még nincs loot | A 04-es panel változata | A loot-sáv helyén rövid „Nothing gathered” felirat; a veszély és a két döntés megmarad. |
| Expedíció / nincs idő továbbmenni | A 04-es kártyák állapotváltozata | Go Deeper zárolt, a „No daylight left” ok olvasható; Return to Camp aktív. |
| Expedíció / támadás | 03-gathering-encounter-v2.png, jobb oldal | Felszerelés-, készlet- és statfeltételek; tényleges kockázat; menekülésnél a zsákmányvesztés következménye. |
| Expedíció / hazatérés, lootvesztés | 06-inventory-outcome.png, jobb oldal | A tényleges ActionReport szövege és erőforrás-változásai, külön kitalált jutalmak nélkül. |
| Mentett menet visszatöltése | 09-loading-error.png, bal oldal | Induláskori várakozás, ismeretlen játékállapotnál számok nélküli felület. Siker után az eltárolt esemény/eredmény/expedíció megfelelő nézete folytatódik. |
| Induláskori betöltési hiba | 09-loading-error.png, jobb oldal | Egyetlen Try Again akció, amely az induláskori betöltést újraindítja. |
| Új menet / régi mentés felülírása | 08-popups.png, jobb felső | Egyértelmű figyelmeztetés a felülírásról, Keep Playing és New Run döntés. |
| Mentésre vonatkozó segítség | 08-popups.png, jobb alsó | Az útmutató közölje: a menet automatikusan mentődik. |

Az állapotváltozatok a fő tervlapok közös keretét használják; nem mindegyikhez készült külön raszterkép. A feliratokat és számokat a kód adja, nem a generált képről kell átvenni.

## Recept- és fejlesztési adatok

A megjelenítés forrása az `assets/data/recipes.json`. A 02-es kép csak néhány receptet mutat; a végleges műhelyben mind a kilenc eszköz/táborelem elérhető marad. A kiválasztás és a teljes receptlista görgethető, a Craft és Back akció elérhető marad.

| Tábor | Anyagköltség | Idő |
|---|---|---|
| Basic Refuge (1) | 8 wood, 6 fiber | 2 |
| Established Camp (2) | 12 wood, 4 hardwood, 8 fiber | 2 |
| Rescue Base (3) | 8 hardwood, 5 metal scrap, 8 fiber | 2 |

A Rescue Base létező táborszint. A sikeres RESCUED befejezés és a beacon összerakása jelenleg még nem implementált játékfolyam; a recept hatásleírása nem bizonyít ilyen képernyőt. Ezeket nem szabad kész funkcióként hozzáadni az UI átírásakor.

## Automatikus mentés: tényleges működés és tervezési határ

A `main.dart` a betöltött mentést átadja a motor visszaállításának, majd a motor változásait a tárolóba menti. A `PreferencesRunStorage` egy helyi menetet tárol. Nincs kézi Save/Load gomb, mentéslista vagy mentésválasztó.

A tároló a hibákat elnyeli: sérült/olvashatatlan tárolt adatnál új menet indulhat, mentési hiba mellett a játék memóriában folytatódik. A 09-es jobb oldali kép ezért **nem** sérült mentésről vagy sikertelen mentésről szól, hanem az alkalmazás induláskori betöltési hibájáról.

„Saved”, „Saving…” vagy „Save failed” státusz nem szerepel a jelenlegi felületen. Ilyen visszajelzéshez a tároló eredményének UI felé továbbítása és külön állapotterv szükséges; az egységesítésben nem jelenítünk meg bizonyítatlan sikerüzenetet.

## Következő munkaszakasz

A közös komponensek bekötése és a 30 mobilképernyő exportja elkészült. A screenshot-exportáló lefordult és végig renderelte a felületeket; ez nem helyettesíti a játékfolyamok és az összes kijelzőméret ellenőrzését. A korábbi kérés szerint a teljes tesztkör, analyzer és alkalmazásbuild előtt megálltunk.


## A v3 kérés felülírja az események eredményelőnézetét

Az eseménykártyákon csak akció, illusztráció és előfeltétel jelenik meg, fix magassággal. A jutalom, statváltozás, kudarc és sikeresély a választás előtt nem látszik. A választás eredményét popup foglalja össze, még a Game Over előtt is. [Aktuális képek](../../../screenshots/event-choices-v3/index.html).
