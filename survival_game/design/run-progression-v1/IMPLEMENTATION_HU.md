# Menetösszesítő, Survival XP és profil — bekötés

2026-10-15. Az elfogadott [mechanikai terv](PLAN_HU.md) és [tíz látványterv](README.md) alapján a rendszer be van kötve. [16 tényleges Flutter-képernyőkép](../../screenshots/run-progression-v1/README.md).

## Játékosi működés

A vereség és a megmentés azonos szerkezetű pergamentes összesítőt kapott. Külön mutatja az elért napot és a teljesen túlélt éjszakákat, a helyszíneket, fogásokat, craftokat, legmagasabb táborszintet, hazahozott komponenseket, végső viharhaladást és az XP-t. A részletekben ott vannak a fontos mérföldkövek, a végső statok progress barral, a megtartott fogások és az indulókészlet.

A végzetes ok a tényleges health-levonásnál rögzül. A Poisoned I/II, a víz-/élelemhiány és az állatos encounter külön azonosítható; nem ismert vagy régi forrásnál a felület csak azt mondja, hogy az életpont elfogyott. A mérgezés oka akkor is megmarad, ha a státusz a végzetes időegységben lejár. Legfeljebb két másik aktív állapot szerepel közrehatóként.

A fő lapon nincs X élő játékba. A profil és részletlapok X-szel zárhatók; új menethez külön megerősítés kell. A profil a **Camp menu → Survivor profile** útvonalon játék közben is elérhető.

## XP és rangok

A tervben elfogadott számítás működik: éjszakánként 8 XP (legfeljebb 15); egyedi külső helyszín 15 (6); halfaj 10 (5); itemrecept 5 (10); Tier 20 (3); állatos encountertípus 15 (6); hazahozott komponens 25 (5); végső viharhelyzet 25 (3); megmentés 100. Maximum 760 XP a jelenlegi tartalommal. Az XP nem elkölthető pénz.

A rangküszöbök 0 / 200 / 500 / 900 / 1400 / 2000 / 2700 / 3500 / 4400 / 5400. A következő rang progress barral és hiányzó XP-vel jelenik meg, a tizedik rangnál MAX RANK. A rangfeloldást a menet összesítőjéről vagy a Camp menüből nyitott profil előtt egyszer mutatjuk meg; nincs automatikusan kiválasztott perk.

A jutalom a lezáráskor készül, nem a képernyő bezárásakor. Ugyanaz a menetazonosító nem írható jóvá ismét. A részletes archívum a legutóbbi húsz menetet tartja; az össz-XP és élettartam-rekordok a régebbi részletek kiesésekor megmaradnak. A profil külön számolja a megmentett, elvesztett és feladott meneteket.

## Számlálók és lehetséges félreértések

- A térkép/pakolás megnyitása nem látogatás; csak az elfogadott valódi indulás rögzít helyszínt.
- A sikeresen kifogott, visszaengedett hal fogásnak számít, megtartott ételnek nem. A terepi túlcsordulás után is a tényleges megtartás számít. Az otthoni korábbi halkészlet nem növeli vagy csökkenti az új fogás számlálóját.
- A craftdarabszám tényleges sikeres item-craft, külön egyedi receptlistával. Javítás és befejezetlen craft nem jutalmazott craft. Táborfejlesztés a Tier kategóriában jutalmazott, nem még egyszer itemreceptként.
- A mentési komponens csak biztonságos tábori készletbe kerülve számít. Függő zsákmány, terepi lelet vagy otthagyott alkatrész még nem jutalmazott hazahozatal. Ugyanannak az alkatrésznek a későbbi craftja vagy újrakeresése nem ad ismételt egyedi XP-t.
- A sikeres éjszaka explicit számláló; nincs egyszerű `day−1` visszaszámolás és nincs pont a halálos éjszakáért. A gyakorló minijáték külön szimuláció, nem módosít menetszámlálót.
- A fontos mérföldkövek legutóbbi tizenkét bejegyzése strukturáltan tárolódik. A korábbi rövid szöveges naplóból nem állítunk elő kitalált statisztikát.

## Indulókészlet-cserék

| Választás | Feloldás | Kezdő készlet eltérése |
|---|---|---|
| No Perk | Kezdettől | Normál 2 Wood, 0 Stone, normál statok |
| Scavenger Kit | Rank 3 | −2 Wood, +2 Stone |
| Angler Supplies | Rank 5 | −1 Wood, +3 Worms; botot craftolni kell |
| Field Medic | Rank 7 | −1 Wood, +1 Bandage, −8 Food |

Egyszerre nulla vagy egy opció választható. A választás mentődik, de csak a következő menet indulásakor módosítja a kezdő készletet. A két alap gyógynövény megmarad; nincs ingyen fegyver, nagyobb alaphátizsák, encounterbónusz vagy gyógyulási szorzó. Az induló tárgyak a tárolóba kerülnek; a hátizsák üres, nyolc helyes. Az újmenet lap a pontos induló mennyiségeket is megmutatja.

Aktív menet feladása megerősítéshez kötött. A feladott menet addig megszerzett XP-je egyszer rögzül, majd a kiválasztott következő készlettel új Day 1 / Tier 0 indul. Megszakított megerősítés nem cserél menetet.

## Mentés és régi állapotok

A mentés verziója **3**. A `RunMetrics`, a megváltoztathatatlan `RunSummary`, a `PlayerProfile` és az aktív játék egyetlen teljes JSON-pillanatképbe kerül. A tranzakciók sorba rendezett, külön rögzített pillanatképeket írnak, így egy később befejeződő régi írás nem írhatja felül az új profilt. A Preferences tároló megőrzi az előző jó pillanatképet; sérült elsődleges adatnál a tartalékra tud visszalépni. A tényleges fizikai készülékes process-kill tartóssági ellenőrzés még hátravan.

A sikertelen mentés látható Retry Save állapot. Az új menet indítása a mentés sikeréig letiltott. Az új menet legelső mentésének hibája után az újrapróbálás ugyanazt az új menetet menti, nem adja fel és indítja újra ismét. Hibás `restore` az aktuális jó játékot és profilt változatlanul megőrzi; nem nullázza ki őket.

A régi v1/v2 aktív mentés folytatható, de **Partial record · tracking began on Day X** címkét kap. A teljes számlálók onnan indulnak; a korábbi táborszint átvehető. A régi, már lezárt menet **Legacy record · no XP awarded**, visszamenőleges jutalom nélkül. A profil fajrekordjai nem oldanak fel automatikusan fajismeretet az új játékban.

## Ellenőrzés és határai

- **450 sikeres natív Flutter teszt, 0 hibás, 0 kihagyott.** A teljes korábbi játéktesztkör is lefutott.
- 17 új logikai és 7 új UI-teszt: XP-korlátok és mintaszámok; ranghatárok; húszas archívum; ismételt jóváírás; valódi craft/fogás/komponens; végzetes ok; régi mentés; perkválasztás; soros mentés, hiba/újrapróbálás és sérült mentésből visszaállás.
- A profil, eredmény, archívum, XP, menettörténet, perklapok és újmenet lap ellenőrizve 320×568 telefonon, 844×390 fekvő nézetben, illetve 375×667 méreten 2× betűskálával. A meglévő megmentési UI-tesztek tabletet és több további méretet is lefednek.
- **Nyolc megmentésig végigvitt menet:** két mag, mind a négy indulási opció. A teszt csak a perk feloldásához állít be előzetes profilrangot; az új menet eszközeit, táborát és mentési alkatrészeit játékakciókból szerzi. Folyamat közben többször ment/visszatölt.
- A lezárt rekord megváltoztathatatlanságának végső szigorítása után a célzott profil/UI kör **24/24** sikeres.
- Dart analyzer tiszta; `git diff --check` sikeres. A screenshotok tényleges alkalmazás-widgetekből, reprodukálható bemutatóállapotból származnak; nem fizikai telefonos fotók.

| Mag | Opció | Megmentés napja | Túlélt éjszaka | Tranzakció |
|---:|---|---:|---:|---:|
| 42 | No Perk | 22 | 21 | 522 |
| 42 | Scavenger Kit | 22 | 21 | 522 |
| 42 | Angler Supplies | 22 | 21 | 522 |
| 42 | Field Medic | 29 | 28 | 731 |
| 77 | No Perk | 28 | 27 | 719 |
| 77 | Scavenger Kit | 47 | 46 | 1257 |
| 77 | Angler Supplies | 33 | 32 | 848 |
| 77 | Field Medic | 33 | 32 | 859 |

Ez egy óvatos, ellátmányt előnyben részesítő tesztstratégia, nem emberi nehézségmérés vagy statisztikai egyensúlybizonyíték. A magok a különböző tranzakciószám és mentési pontok miatt sem alkotnak szigorúan párosított összehasonlítást. Mind a nyolc végén 100 Health maradt; a korábban azonosított késői gyógyulás/ellátmány és a teljes gazdaság hangolása továbbra is szükséges. A perkek ára egyelőre az elfogadott terv értéke.

A felhasználó legutóbbi döntése szerinti következő lépés: először a vezetett első nap/tutorial, utána a több stratégiás balanszmérés és emberi próba, végül a fizikai készülékes ellenőrzés.
