# Tábori karakterváltozatok

Frissítve: 2026-10-13. A 0–3. táborszinthez három-három teljes háttérkép van bekötve, összesen 12 pózváltozat. A meglévő tábor szerkezete, tárgyai, megvilágítása, kamerája és art style-ja megmarad. Egyetlen karakter látszik; pozíciója és tevékenysége változik.

| Változat | Tevékenység |
|---|---|
| Fire | A karakter a tűz mellett áll, felé fordul és melegíti a kezét. |
| Bed | A karakter az ágy szélén ül, a lábai lelógnak, pihen. |
| Workbench / Wood | Tier 1–3: a munkaasztalnál dolgozik. Tier 0: a láda mellett guggolva fát rendez; új munkaasztal nélkül. |

A háttér 30 másodpercenként lép a következő változatra, 650 ms áttűnéssel, ha a nappali tábor látható és nincs függő játéktevékenység vagy nyitott popup. Háttérbe kerülő alkalmazás, éjszaka, végső vihar és csökkentett animáció mellett nem vált. A HUD és a kártyák helye változatlan, a látványváltás nem használ nappali időt, nem módosít statot és nem indít mentést.

A Tier 0 saját, új fire/bed/wood képei használatosak a kezdőnézetben és betöltéskor is; az eredeti starter_camp és starter_camp_night már nem aktív háttér. A végső vihar külön képe megmarad. Éjszaka a pózhoz tartozó tábori képet egységes kékes multiply tint sötétíti minden táborszinten. A régi camp_tier_1/2/3 képek változatlan referenciafájlok maradnak. A Tier 1–3 kilenc PNG-je: camp_tier_{tier}_{fire/bed/workbench}_v2.png. A saját Tier 0 fájlok: camp_tier_0_fire_v1.png, camp_tier_0_bed_v1.png és camp_tier_0_wood_v2.png. A kezdőtábor felszereltsége megmarad, nem a Tier 1 képeit használja. Új játék első napján a tűz melletti változat az alapnézet; betöltéskor a nap száma választ kezdőpózt (fire → bed → workbench). Új nap kezdetén a következő pózra lép, így aktív játék mellett sem kell 30 másodpercet várni a változatosságra. Táborszint-váltáskor az adott naphoz tartozó új tier-kép jelenik meg. Az explicit screenshot-póz továbbra is megadható. A napi képválasztás csökkentett animáció mellett is működik, áttűnés nélkül; az időzített ambient váltás ilyenkor áll. A pontos promptok és források: [CAMP_VARIANTS_PROMPTS_V2.md](../../assets/art/CAMP_VARIANTS_PROMPTS_V2.md), [manifest](../../assets/art/camp_variants_manifest_v2.json). A [mobilgaléria](../../screenshots/camp-variants-v2/index.html) minden változatot a tényleges tábori UI-val mutat.

## Navigáció és ellenőrzés

Minden MaterialPageRoute a közös CanopyPageTransitionsBuilder átmenetet használja, minden platformon: 180 ms előre, 140 ms vissza, kizárólag helyben történő áttűnés. Nincs oldalirányú lapozás vagy zoom. Csökkentett animációnál a route tartalma animáció nélkül jelenik meg. A tábori esemény és a beacon képernyő az aktuális tábori pózt kapja, nem áll vissza minden megnyitáskor a fire képre.

306 repository-teszt sikeres, analyzer tiszta. A navigation_test.dart valódi push/pop közben ellenőrzi iOS/Android platformmal a változatlan képernyőkoordinátákat és reduced motion viselkedést; a LostCanopyApp betölti mind a tizenkét aktív PNG-t, és az esemény/beacon megtartja az aktuális pózt. A camp_backdrop_test.dart mindhárom tier teljes ambient ciklusát, a napi váltást, mentésből induló kezdőképet és a Tier 0 éjszakai póz/tint megőrzését, popup/lifecycle szünetet, éjszakát és vihart ellenőrzi. A teljes kör mobil/fekvő/tablet és nagy szöveg ellenőrzéseket is tartalmaz.

Tesztlog: /private/tmp/lost-canopy-camp-navigation-full-tests.log; analyzer: /private/tmp/lost-canopy-camp-navigation-analyze.log.

## Tier 0 új képek

Beépített image_gen eszközzel készült három saját póz, a starter_camp környezet és a canonical explorer_character_master_v1 karakterlap csatolásával. A fát rendező első változat telefonon jobb oldalt vágódott, ezért a karakter és farakás célzottan beljebb került; a korábbi próba archiválva maradt. A végleges képek változtatás nélkül kerültek az assets/art könyvtárba, 941 × 1672 PNG-ként. [Pontos promptok, források és hashek](../../assets/art/starter_camp_variants_manifest_v1.json). [Három tényleges kezdőképernyő](../../screenshots/starter-camp-variants-v1/index.html). A galéria új RunState()-ból, a production CampScreen widgettel készült, explicit vizuális pózválasztással.

Aktuális teljes tesztlog: /private/tmp/lost-canopy-starter-navigation-full-tests.log; analyzer: /private/tmp/lost-canopy-starter-navigation-analyze.log. Capture: LOST_CANOPY_CAPTURE_STARTER_VARIANTS=1 python3 screenshots/tools/capture_unified_ui.py.
