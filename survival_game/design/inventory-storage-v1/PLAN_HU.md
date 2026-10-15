# Hátizsák és tábori tároló — pontos MVP-terv

2026-10-15 · **Javaslat és látványterv, még nincs bekötve.** A számok induló balanszértékek. A vezetett első nap továbbra is az MVP utolsó tartalmi fejlesztési lépése.

## Mire kell, milyen döntést ad?

**Hátizsák:** az úton elérhető készlet. Előre választasz ellátmányt, és helyet hagysz annak, amit hazahoznál. A továbbindulásnál a nappali idő és az egészség mellett a hely is számít. Tele zsáknál választani kell a gyakori fa és a fontos új alkatrész között. A veszélyes menekülésnek a valóban magaddal vitt készlet a tétje.

**Tábori tároló:** a hazaszállított anyagok, élelmek, gyógyszerek és tartalék eszközök biztonságos helye. Indulás előtt innen pakolsz; távolról nem használható. A craft és a táborfejlesztés innen fogyaszt. A hazatérés ettől kézzelfogható biztosítási pont lesz.

A jelenlegi játékban egy közös `RunState.resources` készlet van: a tábor összes anyaga elérhető a terepi Items ablakból, az expedíció pedig külön `loot` térképpel jelöli, miből mennyit veszítesz meneküléskor. Nincs kapacitás és nincs valódi két készlet közötti pakolás. Ez a mérföldkő ezt a közös készletet választja ketté, nem pusztán új fület tesz a mostani Items ablakba.

**MVP-javaslat:** korlátlan tábori tároló + korlátozott hátizsák. A tároló már Tier 0-nál, a meglévő tábori ládaként elérhető, nincs külön kötelező ládaépítés. A tábori építéshez szükséges alapanyagokat nem kell egy mesterségesen kicsi ládába begyömöszölni. Bővítést a hátizsák kap; külön fizetős tárolószintnek most nem lenne érdemi szerepe.

## Készletek és kapacitás

| Hely | Kapacitás | Hozzáférés | Veszély |
|---|---|---|---|
| Camp Storage | MVP-ben korlátlan | Csak táborban | Nem vész el terepi meneküléskor. |
| Backpack | Kezdéskor 8 hely | Útközben, nyugodt megállónál | Csomageldobásnál a teljes hordott készlet elvész. |
| Equipped Gear | Külön rögzített felszerelési helyek | Indulás előtt | Meneküléskor megmarad, kopik és törhet. |

Egy hely egy tárgytípus legfeljebb megadott darabszámú csomagját jelenti. **Nem kilogramm és nem egy fajta korlátlan halom.** `helyek = Σ ceil(darabszám / stackLimit)`. 0 darab 0 hely; részben telt csomag is egy hely.

| Tárgyak | Darab / hátizsákhely |
|---|---:|
| Wood, Fiber, Charcoal | 10 |
| Stone, Hardwood, Metal Scrap | 5 |
| Herb | 5 |
| Worms, Insect Bait, Fruit Bait | 10 |
| Minden nyers halfaj, minden elkészített halfaj, Raw Meat, Cooked Root | 3 |
| Ember Berries, Dew Fruit, Canopy Fig, Iron Nut, Wild Honey, Ribbon Root, Wax Berries, Mooncap | 3 |
| Bandage, Antidote | 3 |
| Battery, Wire, Metal Parts, Radio Module, Beacon Core | 1 |
| Új, még nem besorolt hordható készletazonosító | Biztonságos alapértelmezés: 1 |

Eltérő fajok és nyers/elkészített ételek nem rakhatók egy csomagba. Azonos típusú részhalmok automatikusan összevonódnak: 6 Stone két hely, 5 Stone egy hely. A nagyobb hal jelenleg ugyanannyi helyet foglal, mint más hal; a külön tömeg és romlás nem ennek a körnek a része.

A Water/Food/Health/Sanity a karakter állapota, nem hátizsáktárgy. Nem lesz automatikusan vízpalack a Water statból. Az ételtárgy elfogyasztása feltölti a Food statot, majd felszabadítja a helyét, ha kiürült az utolsó csomagja.

## Felszerelés: ne hat szerszám foglalja el a nyolc helyet

Induláskor külön felszerelési hely: **1 balta, 1 lándzsa, 1 horgászbot, 1 penge (Stone Knife VAGY Machete), 1 Torch, 1 Leaf Rain Cape**. Üresen hagyhatók. A felszerelés nem fogyaszt hátizsákhelyet; családonként csak egy változat vihető. A második balta/lándzsa/bot a táborban marad, nem vihető korlátlan tartalékként a zsákban.

A Machete teljesíti a pengeként használt késszabályokat is (halelőkészítés, gyökér/gyógynövény akció), ahol ez tartalmilag helyettesítés. Nem helyettesíti a baltát. A torch a meglévő egyszer használatos eszköz marad: elhasználáskor a terepi felszerelésből fogy el. Az esőköpeny csak akkor véd az úton, ha felvetted.

A tábori építmények és tárgyak (bed, collector, filter, rack, beacon) nem hordhatók. A menedék alvás- és hajnali bónusza tábori marad. Az expedícióban érvényesülő állapotvédelem csak a ténylegesen felszerelt ruházatból jön. A tábori filter/rack bónusza terepen nem hat; a már elkészített ételt nem kell újra sütni.

A terepi eszközök induláskor rögzülnek, az egész expedíció alatt azok állapotát használod; távolról nem válthatsz a táborban hagyott Salvage Axe-ra. Egy eltört eszköz helyett csak akkor van automatikus helyettesítés, ha valóban a felszerelésben lévő tárgy teljesíti a követelményt; tábori tartalékból nincs teleportáló fallback. Új eszközfelvétel és zsákban hordott tartalék fegyver nem MVP-funkció.

## Indulás és pakolás

1. Térképen célhely választása → **Prepare pack**. Még nincs utazási díj. A fő előnézetből közvetlenül indulhatsz; a részletes indulási összesítő opcionálisan megnyitható, nem kötelező plusz megerősítőkör.
2. A tábori készletből mennyiséget teszel a tervezett hátizsákba: +1, +5, All és −1/−5, numerikus darabszám. A művelet előnézet; nincs költség vagy elvesző tárgy.
Az **All** a teljes rendelkezésre álló mennyiséget választja az előnézetben; nem csonkolja némán. Ha ez túl nagy, a helyjelző piros és a véglegesítés tiltott. Az előnézetben csökkenthető a darabszám.

3. Az ablak mutatja a foglalt helyeket, a szabad helyet és a felszerelést. Azonos tárgyak csomagolását automatikusan számolja; nincs kézi Tetris vagy húzáskényszer.
4. A **Leave camp · 2 time** gomb (az adott hely tényleges díjával) egyetlen tranzakcióban vonja le a kiválasztott ellátmányt a tárolóból, létrehozza a hordott készletet, és elindítja az utat a már meglévő utazási szabályokkal. Az előnézetben a pontos díj és feltétel látható.
5. X / Back az indulási előnézetet visszavonja, semmit nem költ. Túl sok tárggyal az indulás tiltott; magyarázat és pontos helyszám látszik.

A legutóbbi csomag sablonként megjegyezhető; hiányzó készletnél csak a rendelkezésre álló mennyiséget ajánlja fel, és jelzi az eltérést. Nem pakol és nem indul el automatikusan. A táborban a Load / Unload művelet 0 idő; az indulási draftot a következő valódi művelet előtt be kell fejezni vagy elvetni.

Fishing Pond esetén használható bot és legalább 1 csali szükséges a tényleges csomagban; a meglévő 2 idő útiköltség marad. Más helyre gyógyszer és élelem nélkül is el lehet indulni: egy rövid ellátmányjelzés látszik, nem kötelező figyelmeztető popup. Nem hozunk létre új, megkerülhetetlen menükört minden továbbhaladásnál: Prepare pack csak a tábor elhagyásakor van.

## Terepi használat, zsákmány és teli hátizsák

Nyugodt expedíciós megállónál a Backpack nyitható; a Camp Storage fül zárt, felirata **Available at camp**. Bandage, Antidote, Herb és kész ételek csak a hordott mennyiségből használhatók. Aktív encounter/minijáték közben továbbra sincs szabad Items-gyógyítás. Terepi esemény anyagigényét is kizárólag a zsák teljesíti. A felület a megszokott egyszeri költségeket követi, a használat nem kap új pakolási idődíjat.

A frissen szerzett anyag először a hátizsákba kerülne. Ha elfér, egyetlen eredmény után továbbmehetsz. **Ha nem fér el, semmi nem tűnik el automatikusan.**

- Előbb lefut az akció idő-, eszköz- és állapotköltsége, kockázata; ezek egyszer elszámoltak. A fogott/gyűjtött tétel ezután mentett **Pending haul** állapotba kerül.
- Külön ablak: jelenlegi helyek, friss zsákmány, várható helyigény. A rács és a részletes mennyiségválasztás együtt mutatja, mi maradna nálad és mi maradna ott.
- A játékos a meglévő zsákból és az új leletből is hagyhat ott mennyiséget. A **Keep chosen items** addig tiltott, amíg a tervezett összes készlet túl nagy.
- Ha bármit otthagysz, a végső megerősítés tételesen felsorolja az elvesző mennyiségeket. A megerősítés előtti X visszalép a rendezéshez; semmit nem dob el. A rendező ablak X-e minimalizálja a függő zsákmányt; Continue / Travel / Sleep tiltott marad a döntésig. Újramegnyitó gomb látható.
- Az elhagyott tárgy nem marad világban felvehető ládában; ezt a megerősítés kiírja. A döntésig nincs láthatatlan talajloot-időzítő. A kihagyás végleges, az expedíció későbbi új eseményei adhatnak új alapanyagot.

**Követhető példa a látványterveken:** 8/8 helyen van 2 prepared Silverfish, 3 Herb, 1 Bandage, 4 Worms, 10 Wood, 8 Fiber és 6 Stone. Ez hét fajta, de a Stone két hely. Új lelet: 1 Battery + 3 Wood → összesen 10/8 hely lenne. Választás: Wood marad 10, Stone 5, Battery 1; a többi változatlan → 8/8. Hátrahagyás: 3 Wood + 1 Stone. A Battery így hazavihető. A költség és a jutalom nem ismétlődik újratöltéskor.

## Horgászat, alkatrészek és tábori gyűjtés

A megtartott hal egy darab, a halfaj normál halmába kerül. Ha nem fér el, ugyanebben a kapacitásrendezőben döntesz; a hal nem duplázódik. Visszaengedésnél nincs készlet és nincs helyigény. A méret a meglévő fogási riportban marad meg, a készlet továbbra is fajonként darabszámot tárol.

A beacon-alkatrészek is 1–1 helyet foglalnak, meneküléskor elveszhetnek. Nincs külön ingyenes, sérthetetlen küldetéstáska. Alkatrész otthagyásakor erős szöveges jelzés kell, de a játékos dönthet így. A források újra adhatják az elveszett vagy otthagyott komponenst. A garantált alkatrészválasztás a **camp + backpack + pending haul** tényleges tartalmát vizsgálja, nem pusztán a történelmi „már felfedezted” jelzőt. Dupla pending/owned jutalom nem hozható létre.

A táborból indított Forage, favágás, vadászat, Rest, craft, kezelések és éjszakai tábori események közvetlenül a tábori tárolóhoz férnek hozzá és oda teszik a termést. Ezek nem kényszerítik hátizsák-pakolásra a játékost. Ugyanaz a minijáték expedíciós eseményből indítva a zsákot használja. A végső mentési vihar tábori szakasz, a tábori tartalék elérhető a meglévő vihar-akciók szabályai szerint.

## Hazatérés és menekülés

**Sikeres hazatérés:** a teljes megmaradt hordott készlet automatikusan átkerül a tárolóba. A backpack kiürül. Nincs kötelező második kirakodó popup és nincs kézi stack-tologatás. Az összesítő a tényleges új zsákmányt mutatja nyereségként, a fel nem használt indulási ellátmány visszapakolását külön tájékoztatja; nem számolja azt új jutalomnak. „10 Wood stored · total 22”, „Unused supplies returned”.

**Csomageldobás:** a zsák teljes pillanatnyi erőforráskészlete elvész, az induláskor vitt kész élelem és gyógyszer is. A felszerelt eszközök és a táborban hagyott tartalék megmarad. A döntés részletein ez előre látszik: **Lose all carried items; equipped gear stays with you.** Utólag tételes veszteség. A jelenlegi, csak az új zsákmányt elvesztő szabály változását a felület és a migrációs leírás is jelzi.

A meglévő `dropLoot` flag innentől a teljes zsákot üríti; a zsákmányeredet-nyilvántartás csak a napi/jutalomösszesítőhöz szükséges. Fogyasztáskor, fizetéskor, elhagyáskor előbb a friss lelet aránya fogy ugyanabból a tárgyból; így a hazaérkezési nettó új hozam pontosan számolható. Halál után a meglévő végállapot érvényes, nincs tárolós visszaélesztés.

## Hátizsákfejlesztés

| Fejlesztés | Feltétel | Kapacitás | Költség |
|---|---|---:|---|
| Worn Backpack | Kezdő felszerelés | 8 | Ingyenes, minden új menetben. |
| Trail Backpack | Tier 1 + Worn Backpack | 12 | 10 Fiber + 2 Hardwood; 1 idő. |
| Expedition Pack | Tier 2 + Trail Backpack | 16 | 8 Fiber + 4 Hardwood + 2 Metal Scrap; 1 idő. |

Passzív kapacitásfejlesztés, nem külön hordható készlet és nem kopik. A régi zsákot nem kell külön eladni vagy felszerelni. Táborban gyártható, az anyag a tárolóból fogy. A UI a kapacitást és a nettó +4 helyet írja; a kezdő 8 hely játék közben nem csökkenhet. Új tier vagy háttérjelenet nem szükséges hozzá.

## Adatmodell, mentés és atomi műveletek

Javasolt `campResources`, `packResources`, `packTier`, `expeditionGear`, `pendingHaul`, `packingDraft`; a régi `resources` olvasások helyett minden művelet explicit tábori/terepi készletet kap. A UI nem adja össze a két helyet követelményvizsgálathoz, ha az egyik nem hozzáférhető. A craft csak a táborit láthatja. A felszerelt tárgy tulajdonlása és állapota továbbra is a már bevezetett tool-rendszer része.

Mozgatás: forrás + cél + mennyiség, pozitív és ténylegesen elérhető darabszám, kapacitásellenőrzés. Előnézetben nincs tartós levonás, véglegesítéskor egyetlen mentésben mindkét oldal frissül. `camp + pack + pending + felhasznált/elhagyott` anyagmérleg megőrzése kötelező. Double-tap, X, visszatöltés és újraindítás nem másol és nem tüntet el tárgyat.

Régi, táborban álló mentés: minden erőforrás → camp, pack üres, alaptier8. Régi aktív expedíció vagy horgászat: az ottani `resources` teljes készlete az átállásra egyszer **legacy pack** marad, akár túl is lépi a 8 helyet. Semmit nem törlünk; az első sikeres hazatérés automatikusan kirakodja. Legacy túlcsordulásnál visszatérés és a folyamatban lévő próba befejezése engedélyezett, új mélyebb lépés nem; „Return to camp to repack”. A korábbi mentés betöltése önmagában nem dobhat tárgyat. A legacy átmeneti út még a régi csomagvesztési szabályt őrzi: az eredeti, nem lootként jelölt készletet migrációs védett mennyiségként nyilvántartjuk. Fogyasztás ezt is csökkenti, de meneküléskor a megmaradt védett rész a campbe kerül; csak a régi és az azóta szerzett terepi loot vész el. Ez nem második készletpéldány, csak mennyiségi eredetjelölés. Az első hazatéréssel a kivétel megszűnik, a következő új úton már az előre jelzett teljes-zsák veszteség érvényes.

Aktív régi felszerelésből családonként a használt/kiválasztott eszköz marad terepen, a többi tulajdonlás megmarad táborban. Az átállás előtt elindult akció lezárásakor a meglévő jutalom egyszer számolódik el.

A pending loot, a darabválasztás és az egyszer már elszámolt akcióköltség mind mentett. Régi olvasatlan riport nem futtatja újra a jutalmat. Külön schema-verzió és migrációs marker szükséges; a tábori és terepi készletet nem szabad két külön, megszakítható írással menteni.

## Látványtervek és következő implementálás

Az elfogadott pergamen, sötétzöld kijelölés, felső X, egységes 112×172-es kártyák és 3:2 képablak marad. Kártyán rövid név, csomagon belüli darab/max, rövid hely/állapot; teljes stack- és mozgatási információ a részleteken. A pack kapacitás sávja foglalt/összes számmal együtt látszik. Nincs új állandó logó, kézi drag kötelezettség vagy külön galéria az appban.

10 képernyő: camp storage; indulási pack; mennyiségmozgatás; indulás megerősítése; terepi teli pack; friss lelet miatti túlcsordulás; megtartandó mennyiségek; elhagyás megerősítése; automatikus kirakodás összesítő; hátizsákfejlesztés.

Implementálás: két készlet és migration → áthelyezés és indulási tranzakció → tevékenységek forrásának bekötése → pending haul/overflow → veszteség/hazatérés → UI és táskafejlesztések → teszt és valódi screenshot. Kritikus tesztek: 10/11 Wood; 5/6 Stone; több faj; fogyasztással felszabaduló hely; campből nem fizethető terepi akció; 0/negatív mozgatás; teljes zsákban halfogás/beacon; dupla confirm; kilépés közbeni pending; process-kill migráció után; felszerelés/tábor megmaradása meneküléskor; készletkonzerváció; 320 px, fekvő és 2× szöveg. A teljes nyerhető menetet a korlátokkal ismét végig kell mérni.
