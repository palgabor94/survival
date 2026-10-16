# Lost Canopy — állapot és további menetrend

**Frissítve: 2026-10-15 · Megmentési játékfolyam, Tier 0–3 tábor, 3 minijáték, hangok, haptic, pergamentes felület, képen választható térkép és menthető napzáró összesítő; 475 teszt sikeres; splash és váltakozó főmenü bekötve; az első menet tutorialja bekötve; a hátizsák/tároló, az új dzsungel-ökológia és halfaj-/csali-/botrendszer is bekötve.**

Most már az új játéktól a sikeres befejezésig működik a lánc: táborfejlesztés → roncsalkatrészek → Machete → Ancient Ruins puzzle → Beacon Core → Rescue Base → Emergency Beacon → jeladás → végső vihar → RESCUED.

A játékban **49 esemény, 7 játszható helyszín, 28 receptbejegyzés (25 tárgy + 3 táborszint), 42 korábbi kártyaillusztráció és új növény-/kezelésatlaszok** van. A kis itemikonokhoz külön átlátszó PNG-k tartoznak. A nagy kártyák 3:2 képi ablakot és egységes 112×172-es alapméretet használnak; a hosszabb adatok külön részletpanelen nyílnak meg.

[13 egységes háttér](design/world-camp-style-v1/index.html) · [17 új mobil screenshot](screenshots/camp-style-refresh-v1/index.html) · [9 táborváltozat](screenshots/camp-variants-v2/index.html) · [32 új, sorrendbe tett gameplay screenshot](screenshots/rescue-milestone-v1/index.html) · [Látványterv](design/rescue-milestone/DESIGN.md) · [Validáció](design/rescue-milestone/VALIDATION.md) · [MVP-hiánylista](MVP_AUDIT_2026_10_12.md).

Hat állatos encounter és hét további háttér egységesítve: romok, bambuszliget, roncs, mentés, viharos tábor, folyópart és műhely. Az új jaguár a kameraszög-referencia; a karakterlap minden új képnél csatolva volt. A horgászat háttere változatlan. [Pontos promptok és bekötés](design/world-camp-style-v1/README.md).

A Tier 0–3 a kapott négy karakter nélküli táborképet használja, szintenként öt külön átlátszó karakterpózzal: melegedés, favitel, földön barkácsolás, alacsony ládán/tuskón ülés és háttal, csípőre tett kézzel a menedék szemlélése. A háttér állandó, csak a karakter vált. Az ülő figura méretaránya korrigálva; nincs ülés a ládahalom tetején. A pózok minden táborban a szabad talajhoz vagy a kijelölt ülőhelyhez igazodnak. [48 mobilkép](screenshots/camp-layers-all-tiers-v1/index.html) · [Bekötés és promptok](design/camp-layers-all-tiers-v1/IMPLEMENTATION.md). A póz új nap kezdetén és nyugodt táborban 30 másodpercenként változik; a tábori event és beacon megőrzi. Minden képernyőváltás helyben történő áttűnés, lapozás nélkül; csökkentett animációnál nincs route-animáció.

A favágás, növénygyűjtés és vadászat a **Menu → Gather around camp** menüben és hét erdei eseményben játszható. A balta/lándzsa kopik és javítható. [20 gameplay kép](screenshots/minigames-v1/index.html) · [Végleges szabályok és mentés](design/minigames-v1/IMPLEMENTATION.md).

A horgászat elején rövid útmutató jelenik meg. A **Try it first** és a fejléc **?** gombja újrajátszható gyakorlást nyit; ez nem használ további csalit/időt és nem ad valódi zsákmányt. A fehér jelző a játékos, a zöld sáv a hal; nyomva tartás jobbra, elengedés balra mozgat. A teljes halfogás és gyakorlás valódi érintésekkel tesztelt. [Bekötés és ellenőrzés](design/fishing-tutorial-v1/IMPLEMENTATION.md) · [7 új képernyőkép](screenshots/fishing-tutorial-v1/index.html).

Álló nézetben minden teljes hátteret a kijelző szélességéhez igazítunk: nincs oldalsó képkivágás vagy aránytorzítás. A látható felső/alsó képszél finom fade-del olvad a sötét kitöltésbe; az UI nincs maszkolva. A vadászat mozgó elemei a képhez igazodnak. [Bekötés és ellenőrzés](design/scene-width-v1/IMPLEMENTATION.md) · [Új mobil screenshotok](screenshots/scene-width-v1/index.html).

## Elkészült

| Terület | Működés |
|---|---|
| Tábor és túlélés | Tier 0–3, kompakt HUD, 4 stat, 6 nappali idő; Forage/Explore/Rest, éjszakai esemény és alvás; Tier 0–3 szintenként 5 karakterpóz, 30 másodperces ambient váltás. |
| Esemény és encounter | 37 adatvezérelt esemény; 6 állatos encounter; egy sorban lapozható döntések, rejtett jutalmak és esélyek, tényleges eredmény-popup. |
| Expedíció | Több megálló, hordott zsákmány, növekvő veszély, hazatérés és zsákmányvesztés. |
| Craft és fejlesztés | 6 eszköz, 5 tábori tárgy és 3 fejlesztés. Machete nyitja a romok útját; Rescue Base-ben építhető a beacon. |
| Új minijátékok | 3 ütéses favágás, 8 másodperces lapozható növénygyűjtés, mozgó vaddisznós vadászat; eszközkapu, valódi egyszeri jutalom, megszakítás, pause és mentés. |
| Zene | main/camp/action MP3, helyzetfüggő loop és fade, mentett némítás/hangerő a Camp menüben, háttérben szünetel; hangeffektgyűjtési lista elkészült. |
| Hangeffektek | Mind a 7 kapott felvétel bekötve: 5 környezeti loop, 3 favágás és 4 lépésminta; helyszín/napszak/időjárás választás, külön tábori tűzréteg és mentett hangerő a menüben. |
| Haptic | Beépített selection/light/medium/heavy visszajelzés, mentett kapcsoló a Camp menüben, életciklus- és duplázásvédelem. |
| Horgászat | Basic Rod és csali; induló háromlépéses útmutató, ingyenes gyakorlás, 2 másodperces akasztás, érintéses nyomva tartás / elengedés; 1–2 Small Fish; popup/lifecycle alatt megáll. |
| Romok | 3 forgatható lap, Sun–Water–Leaf minta; ingyenes forgatás, 1 idő a beadás; megszerezhető és hazavihető Beacon Core. |
| Beacon | 4 roncsalkatrész + 1 romkomponens, külön forrás- és állapotlista; 2 idő az építés, 1 idő a jeladás. |
| Végső vihar | Jeladás utáni következő hajnal; három 2 időbe kerülő helyzet, mindegyiken szabad fallback. Az eredmények utólag látszanak. |
| Megmentés | Saját izometrikus megmentésjelenet, valódi menetösszesítő; mentve maradó végállapot, megerősített új menet. |
| Mentés | Folytatható esemény, olvasatlan eredmény, expedíció, horgászat, puzzle, jeladás, vihar és győzelem; régi v1 mentések is működnek. |

## Helyszínek

| Helyszín | Elérés és költség |
|---|---|
| Camp | Alaphelyszín, craft, készlet, pihenés. |
| Riverbank | Kezdettől; 2 idő, anyagok/víz/csali és mélyebb zsákmány. |
| Fishing Pond | 2. nap vagy Basic Rod; tényleges játékhoz bot és csali kell, 2 idő. |
| Plane Wreck | Tier 1; 3 idő; négy beacon-komponens és fém/hardwood. Saját új izometrikus háttér. |
| Ancient Ruins | Tier 2 + Machete; 3 idő az út, legalább 4 nappali idő a puzzle-látogatáshoz. |
| Bamboo Grove | 2. nap; 2 idő; bambusz, fiber és hardwood; az új jaguáros kamerát és egyszerű tábori stílust követő háttér. |
| Mangrove Shallows | Tier 1; 2 idő; sodródó fa, gyökérmedence, csali és hal. |

## Ellenőrzés

[Kiinduló haptic- és balanszaudit](design/balance-audit-v1/REPORT.md), [első balanszlépés és összevetés](design/balance-stage1/REPORT.md). Sima baltás/lándzsás használat −1 állapot; három PERFECT favágás 2 Hardwood; kézi fogás legfeljebb 1 hal. Azonos seedekkel újabb 1000 friss menet, 12 756 restore, 9000 gathering és 3000 fishing próba, 37 esemény / 151 döntési ág. A célkövető botok mind végigvitték: medián 15/18/20/22 nap. A javításigény nőtt, az ügyes favágás jobban fizet; a teljes survival továbbra is megengedő. 298 teszt sikeres, analyzer tiszta. A 320 px + 2× szöveges audio/haptic menü is ellenőrzött.

[Zene, bekötött hangeffektek és további Pixabay keresőszavak](AUDIO_INTEGRATION.md). 12 zeneteszt és 14 hangeffektteszt ellenőrzi a váltást, némítást, háttérbe kerülést, mentett beállítást, egyszeri akcióhangokat és a tényleges UI-t; az audio-backend fake. A készülékes meghallgatás még hátravan, az iOS buildet a külső SDK-cache írásvédelme megállította.

A repository valódi tesztjei natív Flutter-motorban futnak. Két új játékból sikeres mentési menet készült, megszerzett erőforrásokkal és többszöri save/restore-rel. Külön ellenőrzött a puzzle állása, a komponensek egyszeri jutalma, a végső vihar minden függő lépése, a halálos döntés és a mentett győzelem.

A mobilos ellenőrzések 320/375/390 px szélességet, fekvő kijelzőt, tabletet, kétszeres szöveget és csökkentett animációt fednek. A screenshotok tényleges widgetekből készülnek, 390 × 844 logikai méreten, 2× PNG-vel; a galéria előkészített késői táborból végiglépteti a tényleges roncs → romok → beacon → vihar → megmentés folyamatot. A screenshot seedelt indulása nem helyettesíti a két friss menet tesztjét.

A 200 seedelt menet stressztesztje a jelenlegi 37 eseménnyel és az új minijátékokkal is sikeres. Az új mobilos tesztek 375 px, fekvő nézet és 150% szöveg mellett is ellenőrzik a minijátékokat, mentést, szünetet és lifecycle-t. Készülékes végigjátszás, build és mért 30–60 perces menet még nem történt.

## Következő mérföldkövek

2026-10-15: a menetvégi és profilrendszer bekötve. **450/450 teszt sikeres**, két maggal mind a négy indulókészlet eljutott a megmentésig (22–47. nap). Egyszeri XP-jóváírás, rangok, külön profil, archívum, perkválasztás, régi mentések részleges rekordja és látható mentési hiba/újrapróbálás működik. A felhasználó új sorrendje: előbb a vezetett első nap/tutorial, utána a teljes rendszer több stratégiás és emberi balansza.

2026-10-15: a hátizsák és tábori készlet bekötve. **420/420 teszt sikeres**; mentett indulási pakolás és felszerelés, explicit zsákmányrendezés, automatikus kirakodás, 8/12/16 helyes fejlesztés és régi mentések veszteség nélküli folytatása működik. Azóta a menetösszesítő és a meta is elkészült; a vezetett első nap továbbra is az utolsó tartalmi fejlesztési lépés.

2026-10-15: a balta-/lándzsaprogresszió is bekötve. Teljes tesztfutás **398/398**, utolsó UI-tömörítés után **19/19** célzott teszt. Az azóta elkészült készletrendszer részletei alább. A teljes rendszer emberi balansza és a készülékes ellenőrzés még hátravan.

2026-10-15: a horgászati bővítés elkészült. A teljes natív tesztfutás **379 sikeres, 0 hibás**, a Dart analyzer tiszta. A fogási döntés és a folyamatban lévő fárasztás menthető; a ritka fajokat a bot és a nap is korlátozza. A készülékes próba és a teljes gazdaság újramérése még hátravan.

2026-10-15: az [új dzsungel-ökológia](design/survival-ecology-v1/IMPLEMENTATION_HU.md) bekötve: nyolc állandó növényi élelem, gyökér-előkészítés, négy menthető státusz, esőkitettség és fáradtság, négy új recept, tizenkét esemény, fajismeret és pergamentes kezelési UI. 355 teszt sikeres; analyzer tiszta. [13 valódi képernyőkép](screenshots/survival-ecology-v1/README.md). A mért emberi nehézség még nem végleges.

Az első balanszlépés elkészült és újramért. A tutorial után következő hangolási feladat a túl erős késői alvásgyógyítás és tea hangolása, majd a végső vihar feszültsége; ezek változatlanok. A növénygyűjtés hozamaránya is további vizsgálatot kér. Emberi játékosok és készülékes haptic/audio ellenőrzése szükséges, a botok nem adnak emberi sikerarányt.

1. **Eszköz- és fegyverprogresszió — elkészült:** három bot, három balta és három lándzsa, mentett felszerelés, külön javításköltség, eszközfüggő gyűjtés és fizikai események. [Bekötés és szabályok](design/tool-progression-v1/IMPLEMENTATION_HU.md) · [12 tényleges screenshot](screenshots/tool-progression-v1/README.md).
2. **Új halak és zsákmány — elkészült:** öt faj, méret/ritkaság, három csali, három bot, veszélyes halak, biztonságos előkészítés és halfajnapló. [Bekötés és pontos szabályok](design/fishing-progression-v1/IMPLEMENTATION_HU.md) · [15 tényleges screenshot](screenshots/fishing-progression-v1/README.md).
3. **Készlet és tárolás — elkészült:** 8/12/16 helyes hátizsák, külön felszerelés, kezdettől biztonságos korlátlan tábori készlet, explicit túlcsordulás és automatikus hazatérési kirakodás. [Bekötés, mentésmigráció és validáció](design/inventory-storage-v1/IMPLEMENTATION_HU.md) · [Valódi screenshotok](screenshots/inventory-storage-v1/README.md).
4. **Menetösszesítő és meta — elkészült:** közös győztes/vesztes összesítő, tételes Survival XP, tartós profil/rekordok, húsz menetes archívum és három választható indulókészlet-csere. [Bekötés és nyolc teljes végigjátszás](design/run-progression-v1/IMPLEMENTATION_HU.md) · [16 tényleges screenshot](screenshots/run-progression-v1/README.md).
5. **Vezetett első menet — elkészült:** csak az első friss menetben felajánlott, menthető/átugorható hatlépéses segítség. Normál tranzakciókat figyel, a Guide alatt visszaolvasható; régi mentésben és későbbi új menetben nem indul automatikusan. [Bekötés és korlátok](design/first-day-tutorial-v1/IMPLEMENTATION_HU.md) · [12 screenshot](screenshots/first-day-tutorial-v1/README.md).
6. **Teljes rendszer balanszolása:** a tutorial elkészülte után, az új tartalommal, több stratégiával és hibázó minijátékossal.
7. **Záró készülékes ellenőrzés:** sikeres/vesztes menet, process-kill és folytatás, mért játékidő, iOS/Android build és teljesítmény.

Analitika és monetizáció külön termékdöntés után következik. A játék már nyerhető, de a starter kit teljes MVP-tartalma még nincs kész.

## Pergamentes UI és képen választható térkép (2026-10-14)

2026-10-15: az elfogadott [napzáró terv](design/day-end-concept-v1/README.md) be van kötve az éjszaka és az alvás után. Három valódi napi történés, négy stat kis számmal és progress barral, nyersanyagkészlet, következő cél és Next day gomb jelenik meg. A napi napló és a függő összesítő menthető; folytatáskor nincs ismételt költség vagy napváltás. [Valódi screenshotok](screenshots/day-end-v1/README.md). A teljes tesztfutás 331/331 sikeres, benne mentés/folytatás, halálos éjszaka, kis kijelző, fekvő nézet és 2× betűméret.

A Craft, Camp upgrade, Items, Camp menu, Journal, Guide és annak minijáték-útmutatói, az események és expedíciók döntési részletei, az eredmény-popup, a Beacon, a romos puzzle és a megmentés képernyője az elfogadott pergamentes rendszert használja. A HUD kerek statikonokat és külön mennyiségjelzőket kapott. A döntési kártyák egységes 112 × 172 méretűek, 3:2 képpel; a hosszú költségek és feltételek a koppintásra nyíló részletpanelen jelennek meg. A kártya megérintése még nem költ időt vagy nyersanyagot, ehhez a megerősítés szükséges.

Az Explore térkép új, teljes képernyőn látható dzsungelképet használ. A hét helyszín saját tájrészletére vagy annak címkéjére lehet koppintani. A kiválasztott hely alul mutatja a pontos utazási költséget, a feloldási feltételt és az indulás gombját; a lezárt helyek is megtekinthetők. A horgásztó hiányzó bot esetén műhely-gyorsgombot ad. A helyszínválasztás nem indítja el az utat.

A [tényleges Flutter screenshotok](screenshots/parchment-all-v1/README.md) külön mappákban fedik a fő játékfolyamot, mentést, minijátékokat, útmutatókat és a frissített világot. A korábbi [47 képes tervezési sorozat](design/parchment-ui-all-v1/manifest.json) koncepcióként marad meg; az új térkép terve a `design/map-on-scene-concept-v1/` mappában van. Az új térkép bekötése után a teljes tesztfutás **324/324**, ezen belül az új térkép 15/15 célzott tesztje sikeres.

## Legutóbbi ellenőrzés — 2026-10-15

Első menetes tutorial: 462 sikeres teszt, 0 hiba, analyzer tiszta. A splash és a három váltakozó főmenüháttér bekötve, képszélhez igazodó fade-del és teljes pergamengombbal: [bekötés](design/menu-variations-v1/IMPLEMENTATION_HU.md) · [screenshotok](screenshots/main-menu-v1/README.md). A következő játékmeneti feladat a balansz, majd készülékes ellenőrzés.

## Főmenü és splash — 2026-10-16

475 sikeres teszt, analyzer tiszta. Valódi kezdés/folytatás, profil, beállítások, súgó, megerősített új menet, megjegyzett A/B/C hátterek. A felső és alsó perem képpontszinten ellenőrzött. [Bekötés](design/menu-variations-v1/IMPLEMENTATION_HU.md). [Új karakteres ikonjelölt](design/app-icon-v1/lost_canopy_explorer_icon_v1.png), az iOS AppIconhoz bekötve, 15 ellenőrzött RGB PNG-vel / 19 mérethelyen.

## iOS ikon és App Store — 2026-10-16

Az új karakteres ikon iOS-re bekötve. A méretek és az átlátszóság hiánya ellenőrzött; a teljes Xcode assetfordítást a nem elérhető CoreSimulator környezet blokkolta. [Ikonbekötés](design/app-icon-v1/IOS_INTEGRATION.md). Hat angol promóciós kép, címmel, alcímmel és friss, tényleges gameplay screenshotokkal, két iPhone-méretben: [App Store-csomag](app_store/en-US/README.md). Ezek fájlként elkészültek, App Store Connect-feltöltés nem történt.
