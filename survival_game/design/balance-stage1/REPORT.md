# Balansz · első lépés · 2026-10-13

**Az eseményes eszközkopás egységes, a tökéletes favágás jutalma nagyobb, a kézi halászat legfeljebb egy halat ad.** A friss menetek továbbra is végigvihetők; a teljes túlélés a célkövető botoknak még megengedő.

## Bekötött szabályok

| Terület | Korábban | Most |
|---|---|---|
| Sima baltás/lándzsás választás | Nem kopott | Használatonként −1 állapot, siker és kudarc esetén is |
| Három PERFECT favágó ütés | 9 Wood + 1 Hardwood | 9 Wood + 2 Hardwood |
| Két PERFECT favágó ütés | 1 Hardwood bónusz | Változatlan |
| Hidden Pool kézi fogás | Siker esetén 2 hal | Siker esetén 1 hal, kudarc esetén 0 |
| Horgász-minijáték | PERFECT 2 hal, GOOD 1 hal | Változatlan |

A kopás az eredmény-popupban látszik, törésnél javítási útmutatással. Elutasított, zárolt, duplán megnyomott vagy visszatöltött, már befejezett választás nem koptat újra. Az állapot mentődik; régi, durability nélküli mentés teljes állapotú eszközökkel indul.

A minijáték megnyitása és a ready képernyő elhagyása ingyenes. Ott csak befejezéskor számít a kopás: minimum 1, plusz minden MISS. Törött balta/lándzsa sem sima választáshoz, sem minijátékhoz nem használható; a workshop meglévő receptköltsége javítja teljesre. Csak a már állapotpontos balta és lándzsa érintett. Gyógyulás, tea, vihar és foraging változatlan.

## Azonos seedekkel mért összevetés

Mindkét mérés a 0–199 világseedet és külön inputhiba-RNG-t használja, stratégiánként 200 friss RunState()-ból indított menettel. A referencia bot ismert tökéletes favágó hozamát 1-ről 2 Hardwoodra frissítettük; más stratégiaszabály és inputmodell nem változott. Az eltérő döntések más eseménysorrendet adhatnak: menetenkénti eredményeket hasonlítunk össze, nem azonos találkozások hatását.

| Stratégia | Megmentés előtte → utána | Befejezési nap mediánja előtte → utána | Balta-javítások összesen, 200 menet előtte → utána |
|---|---|---|---|
| Tájékozott, tökéletes timing | 200 → 200 | 16 → 15 | 0 → 1 |
| Óvatos | 200 → 200 | 18 → 18 | 9 → 130 |
| Célkövető kezdő | 200 → 200 | 20 → 20 | 94 → 263 |
| Vakmerő | 200 → 200 | 21 → 22 | 56 → 226 |
| Csak pihenés, utánpótlás nélkül | 0 → 0 | Halál a 4. napon mindkét mérésben | — |

Az új 1000 menet **305 186 vezérlési tranzakciót és 12 756 save/restore-t** tartalmaz. Nincs blokkolt vagy időkorlátos menet. A célkövető stratégiák 800/800 alkalommal jutottak megmentésig; a pihenő kontroll 200/200 alkalommal meghalt. Az óvatos bot legalacsonyabb HP-jának mediánja továbbra is 94, a kezdőé 86, a vakmerőé 72-ről 74-re változott. A javítás számít az anyaggazdálkodásban, de önmagában nem hozott erős halálozási kockázatot.

| Favágási inputmodell, 1000–1000 próba | Átlag Hardwood előtte → utána | Átlag Wood | Átlag kopás |
|---|---|---:|---:|
| Tökéletes | 1,000 → 2,000 | 9,000 | 1,000 |
| Gyakorlott | 0,572 → 0,726 | 7,482 | 1,075 |
| Kezdő | 0,102 → 0,106 | 3,773 | 2,408 |

A jutalomemelés a három tökéletes ütést díjazza; a hibás ütések hozama és kopása változatlan. Kézi halászatot egyik teljesmenet-bot sem választott, ezért annak nehézségi hatása a teljesmenet-adatokból nem állapítható meg. A siker/kudarc ágát külön motorteszt és az eseménymátrix, a horgászat 1/2 halas elszámolását meglévő motorteszt ellenőrzi.

## Ellenőrzés és korlátok

- **298 repository-teszt sikeres, 0 hiba, 0 kihagyás; analyzer tiszta.** Öt új motorteszt: három/két PERFECT különbsége; minden sima baltás/lándzsás kártya siker/kudarc kopása; törés, blokkolás és javítás; hiányzó/nem kopó eszközök; kézi halászat. A minijátékos expedícióteszt ellenőrzi, hogy ready/START nem koptat, befejezés csak egyszer koptat, és a 2 Hardwood hordott zsákmányként kerül elszámolásra.
- Friss rescue menetek, audio, haptic, UI, mentés és a 200 seedes random stresszpróba is sikeres. Az eseménytesztek az új kopásjelzést is ellenőrzik.
- **37 esemény / 151 döntési ág**, **9000 gathering + 3000 fishing** izolált próba újrafutott. Az ügyességi modellek feltételezett reakcióidőket használnak, nem emberi méréseket.

A következő külön hangolandó változó a késői alvásgyógyítás és tea, majd a végső vihar. Ezek még nincsenek módosítva. A botok ismerik a megmentési célt, javítanak és gyógyítanak; a 100% mintabeli siker nem emberi sikerarány vagy minden seedre adott garancia.

## Adatok és reprodukció

- [Kiinduló audit](../balance-audit-v1/REPORT.md) és [változatlan kiinduló adatok](../balance-audit-v1/results.json).
- [Új nyers adatok](results.json), [seedenkénti összevetés és forrás-hashek](comparison.json).
- [Runner](../../tools/balance_audit.dart).
- Tesztlog: `/private/tmp/lost-canopy-balance-stage1-full-tests.log`; analyzer: `/private/tmp/lost-canopy-balance-stage1-analyze.log`.

Az app könyvtárából:

```sh
/private/tmp/lost-canopy-flutter-sdk/bin/cache/dart-sdk/bin/dart --disable-dart-dev --packages=.dart_tool/package_config.json tools/balance_audit.dart 200 design/balance-stage1/results.json
python3 screenshots/tools/run_native_tests.py
```
