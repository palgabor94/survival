# Fejszék és lándzsák — javasolt mérföldkő

Frissítés: a terv azóta [be van kötve](IMPLEMENTATION_HU.md). Az alábbi eredeti tervezési állapot archívum; az aktuális értékeket és az ellenőrzést a bekötési dokumentum rögzíti.

2026-10-15 · Pontos mechanikai terv és natív Flutterben kirajzolt UI-koncepciók. **Még nincs bekötve a játékba.** Az értékek induló balanszjavaslatok; a fogásokhoz hasonlóan külön implementálás és mérés követi.

## Cél és jelenlegi helyzet

Jelenleg Stone Axe és Stone Spear működik, 10–10 tartóssággal. A favágás három időzített csapásból áll: MISS 0, GOOD 2, PERFECT 3 Wood; két PERFECT 1, három PERFECT 2 Hardwood. A vadászat egy dobás, GOOD 2, PERFECT 3 Raw Meat. Mindkét minijáték kopása `1 + MISS-ek száma`, befejezéskor egyszer elszámolva. A meglévő fegyveres jaguárakció alap esélye 70%, a krokodilé 65%, státusz- és sanity-levonások előtt.

A fejlesztés célja, hogy a jobb szerszám hosszabb expedícióra legyen alkalmas, a játékos időzítése továbbra is számítson. Nincs további kötelező kapu a megmentéshez; a jelenlegi menet alap eszközzel is nyerhető marad. A Machete megőrzi saját bozótvágó és előkészítő szerepét.

## Három balta

| Tárgy | Elérés és előfeltétel | Gyártás | Állapot | Szerep |
|---|---|---|---:|---|
| Stone Axe | Tier 0 | 2 Wood + 1 Stone + 2 Fiber; 1 idő | 10 | Meglévő alap eszköz és időzítés. |
| Reinforced Axe | Tier 1; birtokolt Stone Axe | 3 Wood + 2 Stone + 3 Fiber; 1 idő | 16 | Tartósabb kötés, kicsit könnyebb GOOD, több fa. |
| Salvage Axe | Tier 2; birtokolt Reinforced Axe | 3 Hardwood + 3 Metal Scrap + 3 Fiber; 1 idő | 24 | Jobb munka keményfával, hosszabb használat. |

Favágási GOOD félzóna szorzója 1 / 1,10 / 1,20. A PERFECT félzóna minden baltánál változatlan; az Exhausted ×0,9 továbbra is mindkét zónára hat. A jelző sebessége, a három csapás és a nappali költség nem változik.

A meglévő faeredményhez Reinforced +1, Salvage +2 Wood adódik **próbánként**, ha legalább egy csapás sikerült. Teljes melléütésre 0. A Salvage Axe két vagy három PERFECT esetén további +1 Hardwoodot ad, tehát a maximum 11 Wood + 3 Hardwood; alapbaltával továbbra is 9 + 2. A bónusz nem csapásonként számolódik.

A nem minijátékos, explicit baltás és pozitív faeredményt adó eseményágakon ugyanez +1/+2 Wood egyszer jár, siker esetén. Nincs általános loot-szorzó, sikertelen ágra vagy sima gyűjtésre nem jár. Az új minőségű fa és új kötelező építőanyag nem része ennek a körnek.

## Három lándzsa

| Tárgy | Elérés és előfeltétel | Gyártás | Állapot | Vadászat GOOD zóna | Fegyveres fizikai esély |
|---|---|---|---:|---:|---:|
| Stone Spear | Tier 0 | 2 Wood + 1 Stone + 3 Fiber; 1 idő | 10 | ×1 | +0 százalékpont |
| Hunting Spear | Tier 1; birtokolt Stone Spear | 2 Hardwood + 2 Stone + 4 Fiber; 1 idő | 16 | ×1,10 | +8 százalékpont |
| Salvage Spear | Tier 2; birtokolt Hunting Spear | 3 Hardwood + 3 Metal Scrap + 4 Fiber; 1 idő | 24 | ×1,20 | +15 százalékpont |

A PERFECT zóna és a hús alaphozama változatlan. Nincs automatikus találat vagy plusz véletlen kudarc egy sikeres minijáték után. Az esélybónusz csak `riskDomain=physical` és kifejezetten lándzsát használó döntéseken hat; nem hat méregre, romrejtvényre, lopakodásra vagy a végső vihar szabad választásaira.

Kockázatos lándzsás ág: `clamp(alapesély + felszerelésbónusz − fizikai státuszlevonás − alacsony sanity levonás, 10%, 90%)`. A meglévő levonások maradnak; más események 95%-os plafonja nem változik. Egészségesen jaguár 70/78/85%, krokodil 65/73/80%. A biztos ág továbbra is biztos, nem kap új véletlen dobást.

Új választható akció a meglévő vaddisznó-encounterben: **Keep it at bay**, bármely használható lándzsával, fizikai alap 65%, siker esetén a disznó félreáll, nincs húsjutalom; kudarc esetén −14 Health fizikai sérülés, −4 Sanity, az expedíció véget ér és a csomag elveszik. Az eddigi választások megmaradnak. A fejlettebb eszköz jobb esélyt ad ugyanarra az akcióra, nem szaporít három majdnem azonos kártyát.

## Felszerelés, kopás, javítás

- Két mentett kiválasztás: `equippedAxe`, `equippedSpear`. Camp / Items → Gear vagy a minijáték előnézetében választható. Csere 0 idő és 0 anyag, csak nyugodt állapotban. Aktív próba közben zárolt.
- Egy eszközcsalád feltételét bármely használható családtag teljesíti; a kopás mindig a ténylegesen használt tárgyat éri. A régi mentés és régi `requiresTools: stone_axe/stone_spear` ágak is működnek. A kés és machete feltétele külön marad.
- Ha a kijelölt eszköz törött vagy hiányzik, előnézetben a legjobb használható változat lép a helyére, erről szöveges jelzés jelenik meg. A próba indulásakor az eszközazonosító és a zónaszorzó rögzül és mentődik. Visszatöltés nem válthat jobb eszközre.
- Minijáték: a jelenlegi `1 + MISS-ek száma` kopás marad; kilépés/timeout is elszámolja, ha már elindult. Előnézet vagy részletablak 0 kopás. A last-use, 1 állapotú eszközzel a megkezdett próba befejezhető. Eseményben egy használat −1 állapot, eredménytől függetlenül. Nincs ugyanarra a próbára két kopás.
- Fejlesztés nem semmisíti meg az előző eszközt; a feltétel birtoklás, törötten is teljesül. A régi eszköz tartalék marad, a gyártott új változat teljes állapotú és automatikusan felszerelt. Tárgyanként egy példány, nincs gyártásos duplázás.
- Javítás táborban, nappal, 1 idő, teljes állapotra. Stone Axe: 1 Stone + 1 Fiber. Stone Spear: 1 Stone + 2 Fiber. Reinforced Axe: 1 Stone + 2 Fiber. Hunting Spear: 1 Stone + 2 Fiber. Salvage Axe/Spear: 1 Metal Scrap + 2 Fiber. Az ablak a jelenlegi és a teljes állapotot, minden költséget mutatja. Teljes állapotnál nincs javítás. Nincs beacon-alkatrész felhasználás.
- A minijáték/esemény és gyártás/javítás a meglévő idő–víz–étel rendszert használja, nincs új rejtett járulékos díj. Az ismert költség és veszély előre, a tényleges hozam utólag látszik.

## UI és látványtervek

Az elfogadott pergamenes komponensek, jobb felső X, erdőzöld kijelölés, egyetlen világos kártyakeret. A kártyák 112×172-esek, a képablak 3:2. Minden kártyán azonos cím-, kép-, rövid infó- és állapotsáv van; a költségek és több soros előnyök a külön részletablakban. A kiválasztást az EQUIPPED felirat is jelzi, nem csak szín.

1. Craft / Axes: három azonos kártya, meglévő, elérhető, lezárt fokozattal.
2. Craft / Spears: a három lándzsa ugyanabban az elrendezésben.
3. Reinforced Axe részletei: nagy kép, összehasonlítás, feltételek, költségek, Craft gomb.
4. Items / Gear: három lándzsa, választott eszköz állapota és Equip / Repair a részleten.
5. Javítás megerősítése: 3/24 → 24/24, erőforrások külön sorokon.
6. Favágás előnézet: választott balta, állapot, ismert költség, Start. Nincs előre kiírt fakifizetés.
7. Jaguár encounter: egy sor kompakt kártya, fegyver az akcióhoz kötve; a jelenet látható marad.
8. Lándzsás döntés részlete: választott fegyver, teljes számított esély, aktív hátrány, kopás; Confirm. Nincs előre Health/loot jutalom.
9. Akció utáni eredmény: a ténylegesen kapott fa és a megmaradt állapot, kompakt összesítővel.

Az új atlasz csak tárgyakat tartalmaz; a koncepciók a meglévő, elfogadott helyszínképeket használják. A prototípus képek, nem új játékfunkciók; a gombok a képi állapotot szemléltetik.

## Implementálási sorrend és ellenőrzés

1. Közös tool-catalog és családfeltétel-feloldás, mentésmigráció, felszerelés, pontos egyszeri kopás; a régi tárgyazonosítók maradnak.
2. Négy új recept és hat javítási receptszabály; craft és Items bekötése.
3. Sessionben rögzített balta/lándzsa és időzítési zóna; baltás hozamok; lándzsás fizikai döntések és új vaddisznóág.
4. Elfogadott UI és art bekötése; screenshotok, célzott motorteszt és mentés/folytatás teszt.
5. Azonos seedes összehasonlítás mindhárom eszközzel. Mérendő: túlélés/mentés napja, fa és hús időegységenként, javítási költség, alap eszközzel való nyerhetőség. Az itt megadott számok még nem mért játékos-balanszok.

Kritikus ellenőrzések: 0/1 állapot; csere indulás előtt/közben; törött előfeltétel; mentés közbeni fallback; nulla siker → nulla fa; bónusz egyszer; dupla finish és újratöltés nem ad jutalmat/kopást újra; Poisoned/Injured/Exhausted levonás; biztos ág nem lesz kockázatos; salvage anyag nem fogy el két helyen; 320 px, fekvő nézet és 2× szöveg. A koncepció renderelése külön ellenőrzés, a működő játék regressziós tesztjeit a bekötés után kell futtatni.

A vezetett első nap változatlanul az MVP utolsó fejlesztési mérföldköve.
