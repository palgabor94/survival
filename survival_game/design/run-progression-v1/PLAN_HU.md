# Menetvége, Survival XP és profil — javasolt mechanika

2026-10-15 · **Jóváhagyásra kész terv, még nincs bekötve.** A számok kezdeti balanszértékek. Az eddig elfogadott pergamentes felület, egységes kártyák és részletpanelek maradnak. A vezetett első nap az utolsó tartalmi MVP-lépés.

## Mire való?

A menet végén érthető legyen, meddig jutottál, mi okozta a vereséget vagy hogyan sikerült megmenekülni, és mi marad meg a következő próbálkozásra. Egy jó, de elvesztett menet is eredmény. A profil a játékos történetét és XP-jét őrzi; a tábor, élelem, eszköz, hátizsákfejlesztés és mentési alkatrész minden új menetben újrakezdődik.

A fő sikerfeltétel változatlan: megépíteni a jeladót, túlélni a végső vihart és megmenekülni. Nincs napi belépési jutalom, kötelező grind, véletlen perk vagy XP-ért vásárolható gyógyítás.

## 1. Menetvégi képernyő

**Vereség:** sötétített utolsó helyszín, nagy „YOUR JOURNEY ENDED” cím. Külön „7 nights survived” és „Reached Day 8” mutató: nem számoljuk túlélésnek a félbehagyott nyolcadik napot. Rövid, konkrét végzetes ok és legfeljebb két közreható állapot. Példa: „Poisoned II caused the final health loss. No antidote was used.” Csak ténylegesen rögzített ok jelenhet meg; nincs utólag kitalált következtetés. Alatta helyszínek, fogások, elkészített tárgyak, táborszint, mentési haladás és a megszerzett XP.

**Megmentés:** az elfogadott helikopteres jelenet marad jól látható. „RESCUED”, teljes túlélt éjszakák, megmentés napja, öt komponens és három viharhelyzet. Ugyanaz a statisztikai struktúra, mint vereségnél. A végső statok opcionális részletek, nem zsúfoljuk rá a főlapra.

Fő gomb: **VIEW PROFILE**. Másodlagos: **JOURNEY DETAILS**, majd **NEW JOURNEY**. A terminális képernyőnek nincs X-e: nincs élő menet, ahová vissza lehetne zárni. A profil és részletpanelek jobb felső X-e visszavisz a menetvégi lapra; az új menethez külön megerősítés tartozik.

A menet a befejezés pillanatában archiválódik és jóváíródik, nem gombnyomásért jár a jutalom. Újranyitáskor „XP recorded” jelenik meg, nincs újabb jóváírás vagy új feloldási animáció.

## 2. Pontosan mi számít a statisztikákba?

| Mutató | Szabály |
|---|---|
| Túlélt éjszakák | Sikeresen befejezett alvás/éjszaka után egyszer nő. Halálos éjszaka nem számít. |
| Elért nap | A menet végi `day`; a megmentés napja külön címkét kap. |
| Helyszínek | Egyedi, ténylegesen elért táboron kívüli célok. Térképre koppintás/pakolás még nem látogatás. |
| Fogások | Valóban felakasztott és sikeresen kifárasztott hal, döntésenként egyszer. A visszaengedett hal is fogás; a gyakorlás nem. |
| Megtartott hal | Külön számláló, a végleges megtartás után. A fogásszám nem az inventoryban maradt hal mennyisége. |
| Elkészített tárgyak | Valódi sikeres crafttranzakciók. Javítás, megtekintés és megszakítás nem craft. Külön egyedi receptlista is készül. |
| Tábor | A menet legmagasabb tényleges Tierje, nem a megnyitott fejlesztési terv. |
| Encounterek | Feloldott állatos helyzetek száma és egyedi típusai. A biztonságos elkerülés is érvényes megoldás. |
| Mentési alkatrészek | Egyedi, legalább egyszer ténylegesen táborba hozott komponensek; otthagyott függő zsákmány még nem. Későbbi craft nem törli a rekordot. |
| Vihar | A három végső helyzet ténylegesen túlélt lépése. |
| Utazási történet | Legfeljebb 12 fontos, strukturált mérföldkő, nappal/helyszínnel; nem a teljes akciónapló másolata. |

A tárgydarabszám és az egyedi receptszám külön fogalom. Az XP az egyedi recepteket jutalmazza, nem a korlátlanul ismételt ételcraftot.

## 3. Survival XP — képlet és korlátok

A jutalom a lezárt menet rögzített összesítőjéből számolódik. Vereségnél is az összes ténylegesen megszerzett tétel jár, nincs külön vereségszorzó.

| Teljesítmény | XP | Menetenkénti korlát |
|---|---:|---:|
| Teljes túlélt éjszaka | 8 / éjszaka | 15 éjszaka = 120 |
| Egyedi, felkeresett külső helyszín | 15 / helyszín | 6 = 90 |
| Egyedi sikeresen kifogott halfaj | 10 / faj | 5 = 50 |
| Egyedi elkészített tárgyrecept | 5 / recept | 10 = 50 |
| Elért új táborszint | 20 / Tier | 3 = 60 |
| Egyedi megoldott állatos encountertípus | 15 / típus | 6 = 90 |
| Egyedi táborba hozott mentési komponens | 25 / komponens | 5 = 125 |
| Túlélt végső viharhelyzet | 25 / lépés | 3 = 75 |
| Sikeres megmentés | 100 | 1 = 100 |
| **Elméleti maximum a jelenlegi tartalommal** | **760** | |

Az XP-szabályzat a menet kezdetén verziót kap. Javítás, azonos tárgy ismételt craftolása, ugyanaz a hal újra, alkatrész eldobás-visszagyűjtés, mentésbetöltés, képernyőmegnyitás, gyakorló minijáték és puszta időhúzás nem ad új egyedi pontot. A 15 éjszakás plafon után a túlélési XP nem nő; a szabad játék folytatható. A 760-as összeg a mostani tartalomhoz kötött, új tartalomnál a táblát tudatosan verziózni kell.

**A látványterv vereségpéldája:** 7 éjszaka ×8 =56; 3 hely ×15 =45; 2 faj ×10 =20; 6 recept ×5 =30; Tier 2 =40; 2 encountertípus ×15 =30; 1 hazahozott komponens =25. Összesen **246 XP**. A profil korábban 420 XP-n állt, utána 666 XP. A megmentési példa külön alternatív menet: 10 éjszaka és minden további kategória maximuma = **720 XP**; 420 →1140 XP.

## 4. Rang és tartós profil

Az XP összegyűlik, nem elkölthető pénz. Rangvesztés nincs.

| Rang | Név | Összes szükséges XP |
|---:|---|---:|
| 1 | Castaway | 0 |
| 2 | Pathfinder | 200 |
| 3 | Forager | 500 |
| 4 | Survivor | 900 |
| 5 | Tracker | 1400 |
| 6 | Ranger | 2000 |
| 7 | Trailmaster | 2700 |
| 8 | Jungle Warden | 3500 |
| 9 | Canopy Veteran | 4400 |
| 10 | Lost Canopy Legend | 5400 |

Képlet: a r. rang küszöbe `50 × (r−1) × (r+2)`. A 10. rang után az össz-XP tovább nő, a rangjelző „MAX RANK”; nem rajzolunk félrevezető 0/X következő rangot. A profilon nagy rangszám, szöveges név, össz-XP, következő küszöbig tartó progress bar és hiányzó XP szerepel. Több átugrott rang esetén egy összesítő popup sorolja fel a feloldásokat.

Profilrekordok: lezárt menetek, külön elvesztett/feladott/megmentett darabszám, legjobb túlélt éjszaka, leggyorsabb sikeres megmentés napja, összes fogás és craft, valaha látott helyszínek/halfajok. A profilnapló nem teszi automatikusan az új menetet „mindent ismerővé”: a menet saját fajismerete és tanulmányozása megmarad. A régi profilrekord inkább a profiloldalon olvasható.

Legutóbbi 20 menet részletesen visszanézhető. A régebbi menetek törlése a részletes listából nem csökkenti a teljes XP-t vagy az élettartam-rekordokat. Üres profilnál világos szöveg: „Finish a journey to start your record.” A leggyorsabb megmentés első siker előtt „Not rescued yet”.

## 5. Perkek — egy választható indulókészlet-csere

A javaslat szerint rang 3/5/7 egy-egy készletet old fel. A jelenlegi alapindulás változatlan: 2 Wood, 0 Stone, 0 Fiber; normál statok, alap hátizsák. Egyszerre **0 vagy 1** perk aktív, választása kizárólag a következő új menet létrehozásakor érvényes. Bármikor visszaállítható „NO PERK”-re, nincs vásárlás vagy feloldási pontköltés.

| Perk | Feloldás | Induláskori változás az alaphoz képest | Hátrány |
|---|---|---|---|
| Scavenger Kit | Rang 3 / 500 XP | +2 Stone, −2 Wood | 0 fával indul, a tűz/eszközök fájáért gyűjteni kell |
| Angler Supplies | Rang 5 / 1400 XP | +3 Worms, −1 Wood | 1 fával indul; botot továbbra is craftolni kell |
| Field Medic | Rang 7 / 2700 XP | +1 Bandage, −1 Wood, −8 Food | Kevesebb alapanyag és 67 induló Food a normál 75 helyett |

Nincs ingyen fegyver, nagyobb alaphátizsák, javított encounteresély, gyorsabb alvásgyógyulás vagy jutalomszorzó. A készlet a tábori tárolóba kerül, nem automatikusan a terepi csomagba. A perk nem ad tudást vagy már elfogyasztott kezelést.

A perkek **előzetes balanszjavaslatok**: a következő implementációban külön kapcsolható modulokként érdemes kezelni őket. Először a semleges, perk nélküli teljes menetet kell visszamérni, majd mindhárom cserekészletet. Ha valamelyik egyértelműen jobb, az árát módosítani kell; a rögzített 8/12/16-os hátizsákszabályhoz nem nyúlunk. Az MVP elvárt alapja a pontos összesítő/profil; a perkek nem akadályozhatják a perk nélküli végigjátszást.

UI: azonos méretű kártyák csak névvel, képpel, rangfeltétellel és állapottal. A részletpanel pontosan mutatja a nyereséget és árat. Sötétzöld kijelölés, szöveges „SELECTED FOR NEXT RUN”; a zárolt lapok részletei is megnézhetők. Folyamatban lévő menetet a profilbeli választás nem módosít.

## 6. Új menet, feladás, mentés

Új menetet a lezárt összesítőből és a Camp menüből lehet indítani. Aktív menetnél előbb „End this journey?” megerősítés: a menet feladottként archiválódik, az addig megszerzett XP egyszer jár. Nincs extra befejezési bónusz a feladásért. A következő menet perkét ezután lehet választani, a tényleges reset előtt. A megerősítés írja le, melyik készlet marad meg és melyik nullázódik. Az X minden részlet/újmenet panelről veszteség nélkül visszalép.

Technikai javaslat:

- `RunMetrics`: `runId`, `startedAt`, `rulesVersion`, számlálók, egyedi ID-halmazok, fontos mérföldkövek, végzetes ok és közreható hatások. A futó mentés része; újraindítás és resume nem nullázza.
- `RunSummary`: megváltoztathatatlan végső másolat, `outcome` (rescued/lost/abandoned), XP-tétellista és lezárási idő. Tárolt ID-k + értékek, nem képernyőszövegek utólagos feldolgozása.
- `PlayerProfile`: saját verziózott helyi profil, össz-XP, rekordok, archivált menetek, választott következő perk. Független a `game.restart()` által cserélt menetállapottól.
- A profil és aktív/lezárt menet egy új verziózott mentési borítékba kerül. Atomi csere és előző jó mentés szükséges; a `runId` szerinti egyszeri lezárás a naplóban idempotens. Bármely újraindítási ponton a teljes régi vagy teljes új állapot tölthető vissza. Az XP nem a popup bezárásakor változik.
- Az élettartam-összegek külön tárolódnak, nem a legutóbbi 20-as archívumból újraszámoltak. A rövid, vágott archívum mellett az utolsó lezárt `runId` és aktív menetazonosító kizárja ugyanazon mentés véletlen újrajóváírását. Régi kézi backupok visszajátszását a helyi profil nem tudja megbízhatóan kizárni; szerveres ranglista nincs a scope-ban.
- Mentéshiba esetén a régi mentés megmarad; „Could not save your record. Retry” és Retry gomb, új menet indítása a sikeres rögzítésig letiltva. Nem mutatunk már megkapott XP-t elvesző rekord mellett.

**Régi v1/v2 mentés:** a jelenlegi játék folytatható. Új menetszámlálók a migrációtól indulnak. Ismert Tier és a mentett hazahozott komponensrekord átvehető; rövid naplóból nem találunk ki fogás-, craft- vagy látogatásszámot. „Partial record · tracking began on Day X” címke. Teljes éjszakákat csak a migráció után számolunk, nem egyszerű `day−1` képlettel. A korábban már lezárt győzelmet/vereséget nem jutalmazzuk újra visszamenőleg. A lezárt régi mentés is elindíthatja az új profilt/menetet, de a régi eredmény „Legacy record · no XP awarded”.

Végzetes ok: strukturált forrás a tényleges health-levonásból (poison, injury, encounter, deprivation, night stb.). Több hatás egy tranzakciójában a levonási sorrend és az utolsó nullára vivő forrás rögzül, a többi közreható. Hiányzó régi adatnál „Your health reached zero”, nem hamis konkrét ok. A minijáték gyakorlás nem ír menet- vagy profilstatisztikát.

## 7. Megvalósítási sorrend és ellenőrzés

1. Strukturált menetszámlálók és végzetes ok, közvetlenül a sikeres motortranzakcióknál; mentés/migráció.
2. Közös vesztes/győztes összesítő és fontos események. Egyszeri XP-lezárás és profilmentés.
3. Profil, archívum, XP-részletek és egyszeri rangfeloldás; maximumrang/üres állapot/régi részleges rekord.
4. Külön újmenet-megerősítés és a három opt-in készletcsere. Nincs menet közbeni alkalmazás.
5. Végigjátszás és összehasonlító balansz, majd vezetett első nap és fizikai készülékes záróellenőrzés.

Szükséges tesztek a bekötéskor: minden XP-sor határa és cap, ismételt craft/halfaj/komponens, visszaengedett hal vs gyakorlás, végzetes ok, halálos éjszaka, több rang átugrása, MAX rank, mentés/folytatás, megszakított lezárás és ismételt összesítő, 20-as archívum vágása rekordvesztés nélkül, régi aktív/lezárt mentés, feladás-megszakítás, perk csak új menetre és pontos kezdőkészlet, teljes megmentés perk nélkül és minden perkkel. UI: 320/390 szélesség, fekvő nézet, 2× betűméret, reduced motion, címkézett bezárók és szöveges állapotok.

Ez a tervezési kör a termelési játéklogikát nem módosítja. A PNG-k statikus Flutter-koncepciók, mintaszámokkal, nem már bekötött gameplay screenshotok.
