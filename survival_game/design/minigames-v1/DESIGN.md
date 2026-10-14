# Lost Canopy – három minijáték látványterve

2026-10-13. A jóváhagyott játékok már bekötve: [végleges szabályok](IMPLEMENTATION.md). Az alábbi az eredeti tervezési csomag; a képernyők külön Flutter látványtervek, nem a játékba bekötött minijátékok. A mintabeli loot és tartósság szemléltető érték, a végleges balansz az implementáció feladata.

## Közös megjelenés

- A játék meglévő `CanopyHud`, `CampPanel`, `ActionCard`, `OutcomeDialog` és `CanopyConfirmation` komponensei adják a ténylegesen renderelt terveket.
- Bal felül nap/idő, jobb felül négy stat és alattuk nyersanyagok. Logó nincs. Rövid helyszíncím; a középső jelenet szabadon látható.
- Az interakció alul van: kis időzítősáv vagy egyetlen lapozható növénykártya-sor. Kártyaképek mindig 3:2, középre komponálva. Egy sor minden kártyája azonos magasságú és szélességű, maximum 160 pont széles. Három teljes növénykártya látható alap mobilméreten.
- A képernyő alján legfeljebb egy fő művelet; a szünet és kilépés külön, minimum 48 pontos gomb. Az eredmény csak az akció után jelenik meg: nem mutatjuk előre a loot mennyiségét vagy a véletlen kimenetelt.
- A kártyák képei saját környezettel készülnek. A HUD és az eredmény-popup kis itemikonjai a meglévő, háttér nélküli ikonokat használják.
- Aktív kamerareferencia: `../jaguar-camp-style-test/jaguar_camp_style_v3.png`; minden karakteres generálás mellé `../references/explorer_character_master_v1.png`. Egyszerű facettás tábori stílus, ferde felülnézet, változatos terep, egységes karakter.

## Favágás

Új helyszín: napsütéses favágó tisztás, tuskó, farönk és nagy gyökerek. A karakter kőbaltával dolgozik.

1. Belépés: kőbalta, tartósság és 1 nappali idő költség látható; START / BACK kártyák.
2. Aktív: 3 ütés, mozgó jelző, széles GOOD és keskeny PERFECT időzítési ablak. CHOP gomb. Az aktuális ütés rövid visszajelzése nem jutalomelőnézet.
3. Jó / tökéletes / elhibázott ütés: rövid szöveg + eltérő jelölés; a maradék ütések folytatódnak. Színek mellé mindig címke is jár.
4. Végén egyetlen összesítő: tényleges fa, ellátmányváltozás és a leírásban tartósságvesztés. Nem ütésenkénti popup.
5. Sérült vagy hiányzó balta: LOCKED, WORKSHOP / BACK. Időhiány ugyanennek a kapuállapotnak külön szövegváltozata.

## Növénygyűjtés

Új helyszín: árnyas növényliget, köves sekély patakágy, bogyó, gyógynövény és gomba; a karakter térdelve vizsgál egy növényt.

1. Belépés: rövid instrukció, eszköz, 1 idő; START / BACK.
2. Aktív: 8 másodperces kör, öt növény egy lapozható sorban: BERRIES, FIBER, HERB, MUSHROOMS, UNKNOWN PLANT. Három teljes kártya látható, nyilakkal is lehet lapozni, nem csak swipe-pal.
3. Kiválasztás: kártya kijelölve, SELECTED visszajelzés, legfeljebb 3 választás. Ismételt tap nem ad második példányt. A név/eszközfeltétel látható, pontos loot és mérgezési eredmény nem.
4. FINISH vagy idő lejárta → a már kiválasztott növények egyszeri kiértékelése → összesítő. Üres választásnál nincs loot, a már felhasznált nappali idő megmarad.
5. Kockázatos növény: választás előtt nem mondja meg a statvesztést; utólag az összesítő közli, mi történt. Új státuszrendszer nélkül az első implementáció egyértelmű, egyszeri hatást használhat; tartós mérgezés majd a státusz-mérföldkő része.
6. Machetével elérhető növény: hiányzó eszköznél ugyanakkora szürke kártya, „Requires Machete”, LOCKED. A kör az elérhető növényekkel továbbra is játszható.

## Vadászat

Új helyszín: nyitott vadászösvény száraz fűvel, világos sziklákkal és pálmalevelekkel. A karakter kőlándzsával készül dobni. A vaddisznó külön átlátszó sprite, hogy ténylegesen mozgatható legyen; nincs az alap háttérbe festve.

1. Belépés: kőlándzsa, tartósság, 1 idő; START / BACK.
2. Aktív: oldalirányban mozgó vaddisznó, kis célgyűrű és vele összhangban lévő alsó jelző. THROW gomb; nem kell apró állatra pontosan rátapintani.
3. Egy dobás: HIT / PERFECT / MISS visszajelzés; a lándzsa rövid, kódból rajzolt mozgása, nem új szögből generált teljes háttér. A célállat ugyanazon izometrikus vetületben marad.
4. Összesítő: tényleges hús és esetleges további zsákmány, vagy elhibázott dobásnál loot nélküli kimenetel. Későbbi jobb lándzsa tágabb ablakot és eltérő loot-táblát adhat.
5. Hiányzó/törött lándzsa: WORKSHOP / BACK; időlimit és kilépés nem teszi lehetővé ugyanazt az akciót ingyen újrapróbálni.

## Közös popupok és állapotátmenetek

Mindhárom játékhoz van START, ACTIVE, PERFECT, MISS/SELECTED, SUCCESS RESULT, FAILURE/TIMEOUT RESULT, PAUSE, LEAVE CONFIRMATION és GEAR LOCKED terv. A növénygyűjtéshez külön második kártyalap és kockázatos eredmény is készült.

`ready → active → feedback → outcome → camp / expedition / night / run ended`

- Ready állapotból visszalépés költségmentes. START egyszer terheli az akcióköltséget. A körön belüli tapok nem fogyasztanak új nappali időegységet.
- Szünet / háttérbe kerülés: mozgás és visszaszámlálás megáll; explicit RESUME után folytatódik. Nem fut a háttérben.
- Aktív kilépés: „Leave this attempt?” popup; a felhasznált idő nem jár vissza. Nincs automatikus újradobás. A növénygyűjtés megtartja a már kiválasztott növények kiértékelését; favágás a már teljesített ütések eredményét; vadászat a már megtörtént dobást.
- A kör eredménye egyszer kerül a GameEngine-be és az autosave-ba. Popup bezárása / alkalmazás újranyitása nem duplázhat lootot. Függőben lévő session mentése vagy determinisztikus megszakítási szabály az implementáció része.
- Ha az eredmény elfogyasztja az utolsó nappali időt, a meglévő „Night is falling” összesítő-CTA és éjszakai folyamat következik. Expedíción a loot hordozott zsákmányként kerül a meglévő folyamatba; halál esetén a meglévő game-over ág.
- Tartósság, új itemek és választási számok tervezett integrációk. Ne vezessünk be látszólag működő tartósságot vagy új jutalmat a tényleges adatmodell/mentés nélkül.

## Implementációs sorrend a vizuális jóváhagyás után

1. Közös minigame-session és egyszeri költség/eredmény szerződés, megszakítás, pause, mentés.
2. Favágás: időzítés, 2–4 ütés, balta/eszközkapu, eredmény és camp/expedition integráció.
3. Növénygyűjtés: lapozható választások, timer, eszközkapuk, kiértékelés.
4. Vadászat: mozgó sprite, dobás időzítése, hit/miss, zsákmány.
5. Session/engine tesztek és mobil screenshotok, végigjátszás a meglévő rescue folyamattal.

## Ellenőrzés

A mostani csomag ellenőrzése a látványtervek renderelése, kártyaarányok, túlcsordulás, mobil és fekvő nézet, nagy betűk és a fájlok megléte. Nem gameplay-teszt: a három minijáték még nincs implementálva. A horgászós képernyő és képe változatlan marad.
