# Tier 0–3: állandó háttér, öt külön karakterpóz

2026-10-13. Mind a négy tábor a felhasználó karakter nélküli JPEG-jét használja, változatlan másolatként. A karakter külön átlátszó réteg: melegedés, favitel, földön barkácsolás, alacsony ülőhelyen pihenés és háttal állva, csípőre tett kézzel a menedék szemlélése.

## Képek és méretarányok

A sprite-ok a beépített **image_gen** eszközzel készültek, valódi átlátszó háttérrel. Minden generáláshoz mellékeltük a tábor stílusreferenciáját és az `explorer_character_master_v1.png` karakterlapot. Hat 1254×1254 RGBA fájl adja az öt pózt: az ülésből két külön irány készült. Az eredeti alpha és vászon változatlan maradt; a méretet és az elhelyezést a játékban igazítottuk.

| Póz | Aktív sprite | Teljes prompt |
|---|---|---|
| Melegedés | `explorer_camp_fire_v2.png` | [Tűz](../camp-layers-tier0-v1/fire-v2-prompt.txt) |
| Favitel | `explorer_camp_wood_v1.png` | [Fa](../camp-layers-tier0-v1/wood-prompt.txt) |
| Barkácsolás | `explorer_camp_craft_v1.png` | [Barkácsolás](../camp-layers-tier0-v1/craft-prompt.txt) |
| Ülés balra | `explorer_camp_seated_v1.png` | [Ülés](../camp-layers-tier0-v1/seated-prompt.txt) |
| Ülés jobbra, Tier 2 | `explorer_camp_seated_right_v1.png` | [Ülés jobbra](../camp-layers-tier0-v1/seated-right-prompt.txt) |
| Menedék szemlélése | `explorer_camp_inspect_v1.png` | [Háttal, csípőre tett kézzel](../camp-layers-tier0-v1/inspect-prompt.txt) |

A fej és a felsőtest méretét a többi pózhoz igazítottuk, nem a teljes képfájl oldalméretét tettük azonossá. Az ülő sprite szélessége a táborrajz szélességének 24%-a, a jobbra ülőé 25%; a korábbi 31%-os ülő méret megszűnt. A térdelő póz 22%, az állók 29,5–31%. A karakter így üléskor alacsonyabb, de ugyanakkora embernek látszik.

## Elhelyezés és takarás

Minden póz külön, szintenként beállított talaj- vagy ülőpontot kap. A méret és a koordináták a teljes dekódolt háttérhez kötődnek, ezért a képszélességhez illesztés és a felső/alsó fade nem bontja szét a jelenetet.

| Tábor | Ülőhely | Javított elhelyezés |
|---|---|---|
| Tier 0 | Egyetlen földön álló láda | A szemlélődő karakter a farakásról a szabad talajra került. A barkácsolás a tisztáson marad. |
| Tier 1 | A ládahalom előtti földön álló láda | A magas ládáról levettük. A lábak nem a ládahalom tetején állnak. |
| Tier 2 | A tűz előtti alacsony tuskó | A magas ládás ülés megszűnt. A favivő a bokorról a lépcső előtti tisztásra került; a barkácsoló a tuskótól és az előtéri növénytől távolabb. |
| Tier 3 | A műhely előtti külön, földön álló láda | A karakter és a csizma nem takarja hibásan a lámpát vagy az előtéri bokrot. |

A 20 nappali elhelyezést és az éjszakai színezést a tényleges Flutter screenshotokon ellenőriztük, mindkét mobilméreten. A sprite-okat nem mozgatjuk a bokrok vagy más előtéri tárgyak mögé: az engedélyezett helyek a szabad talajon, illetve a kijelölt ülőhelyen vannak. Ez kézzel beállított jelenet, nem általános 3D takarásrendszer.

[Pontos koordináták, méretek, eredeti források és SHA-256 hash-ek](../../assets/art/camp_layers_all_tiers_manifest_v1.json).

## Működés

A háttér a pózváltások közben állandó; csak a karakter és a talajárnyéka vált 650 ms áttűnéssel, 30 másodpercenként nyugodt nappali táborban, illetve új nap kezdetén. Az ülő póznál nincs a csípő alá rajzolt talajárnyék. A váltás nem használ időt, erőforrást vagy játék-RNG-t.

Popup, esemény, foglalt játék, éjszaka, végső vihar, háttérbe tett app vagy csökkentett animáció alatt nincs automatikus ambient váltás. A tábori esemény és a beacon megőrzi a pózindexet és a szint szerinti illesztést. Az éjszakai sprite `BlendMode.modulate` színezést kap, így a transparent szélek nem lesznek kék téglalapok. A végső vihar továbbra is a saját dedikált jelenetét használja.

## Ellenőrzés

[48 gameplay screenshot, szint és mobilméret szerint szűrhető](../../screenshots/camp-layers-all-tiers-v1/index.html): öt nappali póz és éjszaka, Tier 0–3, 390×844 és 430×932, 2× pixelarány.

A tényleges repository-tesztek ellenőrzik a hat sprite alpha-csatornáját, a négy háttér különbözőségét, az ötpózos ciklust és az állapot változatlanságát minden szinten, a sprite háttérhez kötött illesztését, az éjszakai átlátszóságot, a szüneteltetést és a navigáció utáni pózmegőrzést. A Flutter native runner a normál launcher localhost-korlátja miatt szükséges.

A két elhelyezési finomítás előtti teljes ellenőrzés: **322 sikeres, 0 hibás, 0 kihagyott**; analyzer: **No issues found**. [Gépi eredmény](test-results.json) · [Teljes tesztlog](test-run.log). Logok: `/private/tmp/lost-canopy-all-camp-layers-tests.log`, `/private/tmp/lost-canopy-all-camp-layers-analyze.log`, `/private/tmp/lost-canopy-all-camp-layers-captures.log`.

A fizikai készülékes ellenőrzés külön hátravan.

## Két elhelyezés finomítása

2026-10-13: a Tier 2 tűznél álló karakterének talajpontja `(0.59, 0.80)` helyett `(0.635, 0.80)`, így a csizma a tuskó mellett van. A Tier 3 favivője `(0.66, 0.66)` helyett `(0.66, 0.635)` pontot kapott, hogy hátrébb álljon a tűz tartólécétől. A méretarányok és a többi póz változatlanok.

Újrageneráltuk a 48 gameplay screenshotot. Csak az érintett hat kép változott; a többi fájl SHA-256 hash-e azonos maradt. A két nappali pózt mindkét mobilméreten, a Tier 2 tűzpózt éjszaka is vizuálisan ellenőriztük. Friss célzott ellenőrzés: **9 sikeres, 0 hibás, 0 kihagyott** ([eredmény](pose-clearance-tests.json), [log](pose-clearance-tests.log)); `diff --check` sikeres.
