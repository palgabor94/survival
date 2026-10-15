# Hátizsák és tábori készlet — bekötés

2026-10-15. Az elfogadott [terv](PLAN_HU.md) alapján a rendszer a működő játék része. [Tényleges képernyőképek](../../screenshots/inventory-storage-v1/README.md).

## Játékosi működés

- A tábori tároló Tier 0-tól korlátlan. Nem kell külön ládát építeni; a tábori gyűjtés, craft és kezelések ezt a készletet használják.
- A hátizsák 8 helyes; a Trail Backpack 12, az Expedition Pack 16 helyet ad. A kapacitás állandó fejlesztés, nincs kopása.
- A térképen kiválasztott cél után Storage / Backpack / Gear indulási panel nyílik. Egy tárgyra koppintva −1, +1, +5 és All mennyiségválasztás érhető el. A terv menthető, az X ingyen megszakítja. A Leave camp véglegesíti az egyszeri utazási költséget.
- A következő útra az előző készletet és felszerelést ajánlja fel. A tudatosan üres csomagot is megjegyzi; hiányzó készletnél vagy elhasználódott eszköznél szöveges figyelmeztetés van. Egy újonnan craftolt eszközt a játékos választhat be.
- Külön felszerelhető egy balta, lándzsa, bot, penge, fáklya és esőköpeny. Ezek nem használnak hátizsákhelyet. A táborban maradt eszköz, csali, ellátmány és tábori bónusz nem használható távolról.
- Terepen az Items a vitt készletet mutatja; a Storage fül letiltott. A fogyasztás és az események költsége a vitt készletből történik.
- Ha új zsákmány miatt megtelik a csomag, a jutalom függő készletbe kerül. A költség, eszközkopás és esemény egyszer történik meg. A játékos kiválasztja a végleges mennyiségeket; a tényleges elhagyás előtt tételes megerősítés kell. Mentési alkatrésznél külön figyelmeztetés jelenik meg.
- Az X a zsákmányrendezést minimalizálja, nem dob el semmit. A tábori főnézet Resolve Backpack gombja visszanyitja. A döntés és kiválasztott mennyiségek újraindítás után is megmaradnak.
- Hazatéréskor minden automatikusan tárolóba kerül. Az eredmény csak az új, megtartott zsákmányt jelzi jutalomként; az eredetileg vitt ellátmány visszahozása nem új hozam.
- A csomag elvesztése a teljes vitt készletet érinti. A tábori készlet és a felszerelt eszközök megmaradnak. A hátrahagyott/elvesztett mentési alkatrészek forrásai ismét elérhetővé válnak.
- A megtartott halfogás is kérhet zsákmányrendezést. Ezután automatikusan történik a hazatérés és kirakodás, ismételt fogás vagy jutalom nélkül.

## Halomméretek és fejlesztések

| Csoport | Darab / hely |
|---|---:|
| Wood, Fiber, Charcoal, csalik | 10 |
| Stone, Hardwood, Metal Scrap, Herb | 5 |
| Halak, elkészített halak, növényi élelmek, hús, főtt gyökér, Bandage, Antidote | 3 |
| Mentési komponensek és egyéb különleges tárgyak | 1 |

Minden típus külön számol: `összes hely = Σ ceil(darabszám / halomméret)`. A felület tárgytípusonként egy egységes kártyát mutat, annak darabszámával és tényleges helyigényével; a két helyet elfoglaló 6 Stone nem két ismétlődő kártya. A hosszú halfajnevek rövidebb kártyacímet kapnak, a részletek megőrzik a teljes nevet. A kártyafejléc legfeljebb két sor.

| Fejlesztés | Feltétel | Költség | Idő | Kapacitás |
|---|---|---|---:|---:|
| Trail Backpack | Tier 1 | 10 Fiber + 2 Hardwood | 1 | 12 |
| Expedition Pack | Tier 2 + Trail Backpack | 8 Fiber + 4 Hardwood + 2 Metal Scrap | 1 | 16 |

A táskafejlesztések a meglévő elfogadott táskaillusztrációt használják; nevük és kapacitásuk különbözteti meg őket.

## Mentés és készletmegőrzés

A mentés verziója 2; a korábbi 1-es mentés betölthető. A `RunState.resources` a teljes birtokolt mennyiség, a `packResources` és `pendingResources` ebből elkülönített részek. A tároló ezek levonásával számolódik. A terepi műveletek az `availableResources` / `availableResource` hozzáférést használják; nincs két egymástól független, duplán jóváírt készlet.

A régi, terepen lévő mentést veszteség nélkül örökölt csomagként kezeli: megőriz minden korábbi erőforrást és felszerelés-hozzáférést. A kapacitáson felüli régi csomag hazatérhet, de nem indulhat mélyebbre. Az első örökölt úton a korábbi zsákmányvesztési szabály marad érvényben: csak a nyilvántartott új zsákmány veszhet el. Hazatérés után a normál új rendszer működik.

## Ellenőrzés

- Teljes natív Flutter tesztkör: **420 sikeres, 0 hibás, 0 kihagyott**. Mindkét valódi újmenetes megmentési teszt végigért; a tesztjátékos is kiválasztja az útvonalhoz szükséges felszerelést.
- 15 új készletlogikai és 7 új felületi teszt: halomméretek, draft, készletmegőrzés, felszereléskorlát, túlcsordulás, kiválasztás mentése, csomagvesztés, régi mentés, halfogás, fejlesztések és újrajóváírás elleni védelem.
- A felületi tesztek 320 pixeles keskeny kijelzőt, 844×390 fekvő nézetet és kétszeres betűméretet is ellenőriznek.
- A kártyanév-javítás után célzott készlet/UI ellenőrzés és új képexport készült. A képek natív Flutter widgetekből, beállított reprodukálható állapotból származnak; a roncs akkumulátoros eseménye a valódi tartalomból fut le.
- Az emberi nehézség, a teljes új gazdaság balansza és a fizikai telefonos lifecycle/audio/haptic ellenőrzés külön hátralévő feladat.

Újrafuttatás az app könyvtárából:

```sh
python3 screenshots/tools/run_native_tests.py
LOST_CANOPY_CAPTURE_INVENTORY=1 LOST_CANOPY_CAPTURE_OUTPUT=screenshots/inventory-storage-v1 python3 screenshots/tools/capture_unified_ui.py
```
