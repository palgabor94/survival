# Tier 0: állandó tábor, külön karakterréteg

2026-10-13. Ez az első, hárompózos Tier 0 lépés dokumentációja. A jelenlegi játékban már mind a négy tábor rétegzett, öt pózzal: [aktuális bekötés és ellenőrzés](../camp-layers-all-tiers-v1/IMPLEMENTATION.md). Az alábbi leírás történeti állapot.

## Képek és promptok

A felhasználó 4. képe változatlan, byte-azonos másolatként került az `assets/art/camp_tier_0_empty_v1.jpg` fájlba. Eredeti: `/Users/palgabor/Downloads/ca346231-d66c-43c1-a87a-6b7a4596076e.jpg` (1536×2752). A régi, karaktert tartalmazó Tier 0 képeket az aktív `campArt(0)` nem használja.

Három új, különálló 1254×1254 RGBA sprite készült a **beépített image_gen** eszközzel, `transparent_background: true` beállítással. Minden generáláshoz csatolva volt az új tábor és a kanonikus `design/references/explorer_character_master_v1.png` karakterlap. A generált fájlokat alpha-megőrző másolással tettük be; nem vágtuk ki és nem szerkesztettük őket utólag.

| Póz | Játékbeli fájl | Teljes prompt |
|---|---|---|
| Melegedés a tűznél | `assets/art/explorer_camp_fire_v2.png` | [fire-v2-prompt.txt](fire-v2-prompt.txt) |
| Favitel a farakásnál | `assets/art/explorer_camp_wood_v1.png` | [wood-prompt.txt](wood-prompt.txt) |
| Térdelve barkácsolás a földön | `assets/art/explorer_camp_craft_v1.png` | [craft-prompt.txt](craft-prompt.txt) |

A tűznél melegedő karakter v2 változata hátulnézetből látszik, a képen jobbra-felfelé, a lángok irányába néz. A barkácsoló karakter a középső üres tisztásra került, a bokrok elé helyezett pozíció helyett. A farakásos póz változatlan. A korábbi tűznél álló v1 sprite és prompt megmaradt, de a játék a v2-t használja.

Nincs ágyon ülő póz. [Források, hash-ek és pontos koordináták](../../assets/art/camp_layers_tier0_manifest_v1.json).

## Bekötés

A `SceneArtwork` a dekódolt háttér méretéből kiszámolja a teljes kép festett téglalapját, és ezt adja át a karakterrétegnek. A pozíció, a méret és a talppont ehhez igazodik: álló telefonon teljes képszélesség, fekvő nézetben a meglévő cover működés. A sprite vászonarányát és alpha-csatornáját megtartjuk; külön, visszafogott talajárnyék készül a kódban.

Tier 0-nál a háttér állandó. Csak a karakter és az árnyéka vált 650 ms áttűnéssel, nyugodt nappali táborban 30 másodpercenként, illetve új nap kezdetén. Esemény, popup, foglalt játék vagy háttérbe tett alkalmazás alatt nem vált magától. Csökkentett animáció esetén nincs időzített váltás. A napi pózváltás nem használ játékidőt, erőforrást vagy RNG-t.

Az éjszakai kékes színezés a háttérre és a sprite-ra is érvényes. A tábori esemény és a beacon ugyanazt a pózindexet és háttérillesztést kapja. A képszélek fade-je továbbra is működik, a HUD és a kártyák kívül maradnak a maszkon.

## Ellenőrzés

- A kapott JPEG byte-azonossága, a tíz külön háttér és a három valóban átlátszó sprite ellenőrizve.
- Valódi widgetteszt ellenőrzi a háttérelem megmaradását a karakter áttűnése közben, valamint a talppont és a méret illesztését 390×844, 430×932 és fekvő 844×390 nézeten.
- Külön képpontteszt ellenőrzi, hogy az éjszakai színezés nem tölti ki a sprite átlátszó széleit. Ehhez a sprite `BlendMode.modulate` módot használ.
- A korábbi napi váltás, szüneteltetés, éjszaka, szintlépés és állapotváltozatlanság ellenőrzése megmaradt.
- [Hét valódi Flutter gameplay screenshot](../../screenshots/camp-layers-tier0-v1/index.html): három nappali póz két mobilméreten és az éjszakai tábor.

Teljes natív Flutter tesztfutás: **322 sikeres, 0 hibás, 0 kihagyott**. Analyzer: **No issues found**. A tesztfutás a repository tényleges tesztjeit futtatja a Flutter-motorban; a normál launcher localhost-korlátja miatt `screenshots/tools/run_native_tests.py` indítja.

Ellenőrzési logok: `/private/tmp/lost-canopy-camp-layers-full-tests.log`, `/private/tmp/lost-canopy-camp-layers-analyze.log`, `/private/tmp/lost-canopy-camp-layers-captures.log`. A gépi eredmény másolata: [test-results.json](test-results.json).

A készülékes vizuális ellenőrzés még hátravan.

## Pózok finomítása — 2026-10-13

A felhasználói visszajelzés alapján a barkácsoló talppontja a középső tisztásra került (x=0.47, y=0.72), ahol a sprite nem fedi a bokrot. A tűznél álló új v2 karakter hátulnézetből jobbra-felfelé néz, a tűz felé. Új talppontja x=0.42, y=0.69; a sprite talppont-ankora x=0.55, y=0.94. A v1 képet nem töröltük. A beépített image_gen készítette a v2-t, változatlan tábor- és karakterreferenciával, átlátszó háttérrel.

A javításhoz 9 táborháttér- és 10 háttérillesztési teszt futott: **19 sikeres, 0 hibás**. Analyzer tiszta. A teljes hétképes galéria frissítve (390×844, 430×932, éjszaka). A korábbi teljes 322 tesztes ellenőrzés eredménye megmaradt; ehhez a kis vizuális javításhoz a két érintett tesztcsoportot futtattuk újra. [Tábor-tesztek](pose-refinement-camp-tests.json) · [Háttér-tesztek](pose-refinement-scene-tests.json).
