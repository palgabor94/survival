# Lost Canopy — állapot és további menetrend

**Frissítve: 2026-10-13 · Megmentési játékfolyam, rétegzett Tier 0–3, szintenként 5 arányos karakterpóz, 13 egységes háttér és 3 új minijáték, hangok és haptic kész; 322 teszt sikeres, analyzer tiszta.**

Most már az új játéktól a sikeres befejezésig működik a lánc: táborfejlesztés → roncsalkatrészek → Machete → Ancient Ruins puzzle → Beacon Core → Rescue Base → Emergency Beacon → jeladás → végső vihar → RESCUED.

A játékban **37 esemény, 7 játszható helyszín, 14 receptbejegyzés (11 tárgy + 3 táborszint), 42 saját hátteres kártyaillusztráció** van. A kis itemikonokhoz külön átlátszó PNG-k tartoznak. A nagy kártyák 3:2 képi ablakot és legfeljebb 160 px álló szélességet használnak; egy sor minden kártyája a legmagasabbhoz igazodik.

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

Az első balanszlépés elkészült és újramért. Következő külön lépés a túl erős késői alvásgyógyítás és tea hangolása, majd a végső vihar feszültsége; ezek változatlanok. A növénygyűjtés hozamaránya is további vizsgálatot kér. Emberi játékosok és készülékes haptic/audio ellenőrzése szükséges, a botok nem adnak emberi sikerarányt.

1. **Eszközök és túlélés:** fejlettebb eszközök, nagyobb/ritka halak, Poisoned/Injured/Wet/Exhausted, hordott slotok és tábori storage.
2. **Betanítás és meta:** vezetett első nap, unlock-visszajelzés, vereségösszesítő, Survival XP, profil és perkek; 12–15 valódi tárgyrecept.
3. **Balansz és kiadás:** készülékes teljes sikeres/vesztes menet, process-kill és folytatás, mért játékidő, iOS/Android build és teljesítmény.

Analitika és monetizáció külön termékdöntés után következik. A játék már nyerhető, de a starter kit teljes MVP-tartalma még nincs kész.

## Pergamentes UI – első bekötött felületek (2026-10-14)

A Craft és Camp upgrade képernyők, valamint az Items Materials / Food / Gear már az új pergamentes komponenseket használják. A közös 112×172-es kártyák 3:2 képaránnyal készülnek. Koppintás után részletpanel mutatja a költségeket, felszerelési feltételeket vagy a használatot; a megerősítés adja vissza a parancsot a tranzakciókat kezelő tábornak. Az X csak bezár. Nagy rendszerbetűnél minden kártya együtt nő; kis képernyőn kevesebb oszlop van.

A működő felületekről 10 valódi Flutter screenshot készült: `screenshots/parchment-craft-v1/index.html`. 14 camp UI és 15 expedition UI teszt sikeres, köztük kis mobil, landscape és 2× szövegméret. A többi screen és popup pergamentes átépítése még hátravan; a 47 képes tervezési galéria továbbra is koncepciókat tartalmaz.
