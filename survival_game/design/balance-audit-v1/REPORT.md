# Lost Canopy · haptic és teljes játékellenőrzés

Ez a változtatások előtti mérés archivált pillanatképe. Az aktuális szabályok és az azonos seedekkel újrafuttatott eredmények: [balansz első lépés](../balance-stage1/REPORT.md). Az itt tárolt results.json az eredeti mérés marad.

2026-10-13. **A játék végigvihető. A minijátékokban van ügyességi különbség, de a teljes túlélési menet a mért, célokat követő botoknak könnyű.** A hibák többnyire hosszabb játékot okoznak, nem vereséget. A jutalmakon, költségeken és nehézségi szabályokon ez az ellenőrzés nem változtatott.

## Haptic bekötés

Flutter beépített HapticFeedback API; új natív plugin nem szükséges. **Camp → Menu → Haptic feedback** kapcsoló, külön mentett beállítással. Kártyák és tábori navigáció: finom selection. Jó találat és növényfelvétel: light. Tökéletes találat, craft, fejlesztés és sikeres eredmény: medium. Sérülés, elrontott puzzle, elvesztett hal és sikertelen aktív gyűjtés: heavy. A kapás külön, egyszeri jelzést ad, a reeling nem rezeg minden képkockán.

Az eredmény visszajelzése felülírja az ugyanazon kártyához tartozó késleltetett tap-ot. Zárolt kártya, ismételt elutasított ütés és passzív UI-újraépítés néma. Némítás, háttérbe kerülés és dispose törli a függő visszajelzéseket; visszatéréskor nincs utólagos rezgés. Mentésbetöltéskor a már létező eredményből sem keletkezik új rezgés. A haptic nem módosítja a játék RNG-jét, jutalmát vagy autosave-ját.

Forrás: lib/feedback/haptics_controller.dart és haptics_scope.dart; bekötés main.dart, action_card.dart, canopy_components.dart és fishing_screen.dart. A natív platformhívások és a tényleges UI automatizáltan ellenőrzöttek; a rezgés érzetét telefonon még ellenőrizni kell.

## Módszer és korlátok

- **1000 teljes friss menet:** öt stratégia, egyenként 200 azonos világseed (0–199). Kezdőállapot mindig a valódi RunState(), hozzáadott tárgy/nyersanyag/stat nélkül. Legfeljebb 80 játéknap és 3500 vezérlési tranzakció.
- **12 764 save/restore** a teljes menetekben; 305 424 vezérlési tranzakció. A mentett statok, erőforrások, eredmények, expedíció és függő tevékenység ellenőrzése. A restore ismert normalizálásai megengedettek: event nélküli pendingAction törlése és aktív gathering pause.
- **9000 elkülönített gathering-próba:** favágás, gyűjtés, vadászat; három inputmodell, típusonként és modellenként 1000 próba. Ezek eszközökkel előkészített fixture-ök, nem teljes új játékok.
- **3000 horgászpróba:** három inputmodell, modellenként 1000 próba.
- **37 esemény, 151 döntési ág:** izolált fixture-ben minden kártya, a kockázatos választások siker/kudarc ága és minijáték-befejezések; valódi GameEngine-tranzakció, eredmény, duplázás elleni védelem, stat/nyersanyaghatár és eredmény-restore.
- **293 repository-teszt sikeres, analyzer tiszta; ebből 14 új haptic-/UI-teszt.** A teljes repository tesztkör külön ellenőrzi a UI-t, recepteket, fogyasztást, mentést, horgászatot, minijátékokat, rescue láncot és a hangokat. A korábbi 200-menetes random stresszpróba most is sikeres: 34 395 tranzakció, 2108 restore, 28 meglátogatott eseménytípus.

A botok **nem emberi játékosok**. Mind a négy célkövető stratégia ismeri a guide-ban szereplő megmentési útvonalat, a craft-igényeket, a fogyasztást és az eszközjavítást. Az óvatos, kezdő és vakmerő döntései címekből becsült hozamokat és korábbi tényleges eredményeket használnak; nem olvassák az előre rejtett numerikus jutalmakat. A tájékozott referencia az ismert adatokat is használja, ezért kedvező referenciabot, nem egy új játékos modellje. Nem bizonyított az optimális stratégia, és nem mértünk emberi sikerarányt vagy valós játékidőt.

A forgatási puzzle minden botnak látható célmintát ad; kezdőnél 15% beadási hibát modellezünk. A fordítás és próbálgatás nincs időben korlátozva. A világ-RNG és a motoros inputhiba RNG-je külön van; a restore-próbák a világ-RNG objektumát megtartják, ezért összehasonlíthatók. A valódi app nem ment RNG-állapotot; erre a jelentés nem állít azonosságot.

## Teljes menetek eredménye

| Stratégia | Megmentés | Halál | Medián befejezési nap | Befejezési nap P10–P90 | Meneten belüli legalacsonyabb HP mediánja | Végső HP mediánja |
|---|---:|---:|---:|---|---:|---:|
| Tájékozott, tökéletes timing | 200/200 | 0 | 16 | 15–17 | 84 | 100 |
| Óvatos, kisebb timinghiba | 200/200 | 0 | 18 | 17–20 | 94 | 100 |
| Célokat követő kezdő, 12% véletlen választás | 200/200 | 0 | 20 | 18–24 | 86 | 92 |
| Vakmerő, 35% véletlen választás és mélyebb expedíció | 200/200 | 0 | 21 | 18–25 | 72 | 92 |
| Csak pihenés, készletutánpótlás nélkül | 0/200 | 200 | — | — | 0 | — |

A pihenő kontroll medián a 4. napon hal meg. A túlélési alapmechanika tehát bünteti a készletek teljes elhanyagolását. A tényleges utánpótlást és gyógyítást használó botok azonban mind életben maradtak. Nincs blokkolt menet vagy időkorlát miatt megszakadt menet a végleges futásban. A fő megmentési útvonal 25 eseménytípust látogatott meg; az összes tartalom ellenőrzése a külön 37-es eseménymátrixból és a repository tesztjeiből származik.

**Következtetés:** az ügyetlenebb és kockázatosabb játék jelenleg inkább 4–5 plusz napot és több sérülést jelent. Ez egy laza túlélős MVP-hez működő alap, de erős survival kihívásnak kevés. A 100% itt a 200 mintafutás aránya, nem minden lehetséges seed vagy emberi játékos garantált sikeressége.

## Ügyességi minijátékok

| Mért érték | Tökéletes input | Gyakorlott input | Kezdő input |
|---|---:|---:|---:|
| Favágás: legalább 1 fa | 100% | 100% | 90% |
| Favágás: átlag fa / próbálkozás | 9,00 | 7,48 | 3,77 |
| Favágás: átlag balta-kopás | 1,00 | 1,08 | 2,41 |
| Vadászat: találat | 100% | 98,8% | 57,4% |
| Vadászat: átlag hús | 3,00 | 2,56 | 1,37 |
| Horgászat: sikeres fogás | 100% | 100% | 34,1% |
| Horgászat: tökéletes fogás | 100% | 73,9% | 0% |
| Biztonságos növénygyűjtés: átlag étel, idődíj előtt | 7,00 | 7,00 | 4,76 |
| Biztonságos növénygyűjtés: átlag fiber | 2,00 | 2,00 | 1,29 |

A gyakorlott timing input Gauss-hibájának szórása 65 ms, a kezdőé 200 ms. A gyűjtésnél kezdőnél 1–3 ismert növény és véletlen sorrend szerepel; veszélyes gomba/unknown nem kötelező, és ebben az izolált táblában nem választódik. A horgászat gyakorlott inputja 350 ms hook-reakcióval, 200 ms vezérlési mintavétellel működik. A kezdőé 450–1450 ms reakcióval, 500 ms mintavétellel és nagyobb vizuális hibával; a hook-ablak 1,2 s. Ezek modellezési feltételek, nem játékosokon mért reakcióidők.

**A favágás fokozatosan, a vadászat és horgászat érezhetőbben választja szét az ügyességi szinteket.** A növénygyűjtés inkább gyors válogatás, mint komoly kihívás. A romok puzzle-je a rögzített Sun–Water–Leaf minta miatt könnyen megoldható illesztés.

## Egyensúlyproblémák és indokolt következő munka

1. **A gyógyulás elfedi a kockázatot.** Tier 3 + Leaf Bed mellett egy táplált alvás 30 HP-t ad (10 alap + 4 + 4 + 6 tier + 6 bed). Egy tea 15 HP és 6 sanity, nappali idő nélkül. A célkövető futások végén 20–34 megmaradt herb a stratégia szerinti medián. Ezekkel a tipikus 6–24 HP sérülések gyorsan eltűnnek. Következő kísérlet: korlátozott tea-használat vagy kisebb alvásgyógyítás; a két változót külön kell mérni.
2. **Az egyszerű eseményválasztás megkerüli az eszközkopást.** A klasszikus `chop`/`split` és baltás encounter-kártyák nem csökkentik a balta durability-jét; a minijáték igen. A hardwood_grove közvetlen kártyája 3 hardwoodot ad, a tökéletes mini 1-et. Az ügyesebb minijáték-jutalmat és a minden tényleges eszközhasználatra egységes kopást együtt kell átnézni.
3. **A minijáték több munkát kér, sokszor gyengébb gazdasági haszonnal.** A berry_patch biztos választása 20 food + 1 fiber, a biztonságos mini 7 food + 2 fiber + 1 herb, ugyanazon alapakció költségén. A hidden_pool kézi fogása akár 2 hal, miközben a külön horgászat 2 nappali időt és csalit kér. A halas kártya kockázatos, ezért nem minden esetben dominál, de a költség/jutalom viszony külön hangolást kér.
4. **A védelem túl tartós.** Egy elkészített Torch használata több helyzetben biztos menekülési út, fogyasztás és kopás nélkül. A sanity fő hatása csak alacsony értéknél a kockázatos választások esélycsökkentése; maga a 0 sanity nem veszít el menetet. Késői táborban a visszatöltés ezt még kevésbé fenyegetővé teszi.
5. **A végső vihar inkább előkészítés-ellenőrzés.** A három ingyenes fallback összesen 26 HP közvetlen sérülés; a 6 idő még 24 water / 18 food költség. A kipihent, feltöltött túlélőnek ez biztosan kezelhető. A feszültséghez a signal állapotának vagy egy szűk, de javítható erőforrásdöntésnek is szerepet kell kapnia, új kötelező softlock nélkül.
6. **A balta javítása előrelépési tudáskapu.** A pilot botok nem javítottak: több menet hosszú hardwood-hiányba futott, miközben életben maradt. A végleges botok a guide és workshop javítását használják, mind továbbjutnak. Ez nem motoros softlock: figyelmeztetés/egyértelmű javítási shortcut indokolt, amikor a következő cél hardwoodot kér és a balta törött. Pilot-adat: pilot-results.json; nem a végleges nehézségbecslés.

Javasolt sorrend: egységes eszközkopás és minijáték-jutalmak → gyógyulás korlátozása → rescue-feszültség → tartósabb veszély/sanity → emberi kezdő/próbált játékos teszt. Nem javasolt mindet egyidejűleg nehezíteni. Minden változtatásnál ugyanezeket a seedeket és botokat kell újrafuttatni, majd telefonon kipróbálni, hogy a statisztikai szigorítás ne váljon frusztrálóvá.

## Fájlok és reprodukció

- [Nyers eredmények](results.json): minden menet, műveletszámlálók, nyersanyagok, minijáték-mérések és 151 eseményág.
- [Runner](../../tools/balance_audit.dart): összes stratégia és inputmodell.
- Haptic tesztek: test/haptics_test.dart.
- Natív teljes tesztlog: /private/tmp/lost-canopy-haptics-full-tests.log; analyzer: /private/tmp/lost-canopy-haptic-analyze.log.

Normál környezetben az app könyvtárából: `dart run tools/balance_audit.dart 200`. A sandboxban a Dart CLI natív build-hookja a külső telemetry cache miatt nem futott; a tisztán Dart runner közvetlenül futtatható:

```sh
/private/tmp/lost-canopy-flutter-sdk/bin/cache/dart-sdk/bin/dart --disable-dart-dev --packages=.dart_tool/package_config.json tools/balance_audit.dart 200 design/balance-stage1/results.json
python3 screenshots/tools/run_native_tests.py
```

A natív audio és haptic érzete, készülékes process-kill/folytatás, teljesítmény és egy tényleges, időmért emberi végigjátszás továbbra is eszközös ellenőrzést igényel. A botok tranzakciószáma és játéknapja nem valós játékidő.
