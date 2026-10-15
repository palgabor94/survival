# Lost Canopy — a kiismerhető dzsungel

Tervezési javaslat · 2026-10-15 · Még nincs implementálva vagy balanszteszttel igazolva.

## 1. Milyen élményt építünk?

A játékos megtanulja, hol talál vizet és tápláló ételt, melyik növényhez kell eszköz vagy előkészítés, mikor veszélyes a terep, és mikor érdemes visszafordulnia. A dzsungel sajátosságai összefüggenek: a vihar vizet ad, de megáztat és nehezíti az átkelést; a méz jó élelem, de rovarokat vonz; a kés biztonságosabb gyűjtést tesz lehetővé; egy sérülés után ugyanaz a vadászat már rosszabb vállalás.

A meglévő négy fő stat marad. Négy átmeneti státusz kapcsolja össze a rendszereket: Poisoned, Injured, Wet, Exhausted. Nincs új folyamatosan fogyó fő stat. A cél a helyzetekre adott döntés, nem négy új sáv állandó feltöltése.

**Alapelv:** minden veszélynek legyen felismerhető jele, következménye és legalább egy ésszerű elkerülési vagy kezelési módja. A fajok kitalált játékbeli fajok, állandó tulajdonságokkal; a szín mellett alak, levél és mintázat is azonosítja őket.

## 2. A jelenlegi alap, amihez a számokat mérjük

- 6 időegység egy nap.
- Egy elköltött idő: jelenleg −4 Water, −3 Food, valamint hiány esetén egészségvesztés.
- Alvás: jelenleg −10 Water, −8 Food, −3 Sanity; a tábor felszerelése és szintje bónuszokat ad.
- A statok 0–100 közöttiek. A fogyasztás jelenleg a táborhoz kötött.
- A kockázatos választások esélyét most alacsony Sanity alatt −15 százalékpont módosítja.
- A gyűjtés most részben közvetlen statjutalmat ad; a gomba/ismeretlen növény biztonsága próbánként kisorsolt.

**Tervezett változás:** a növények faji tulajdonsága rögzített lesz; az élelmet tárgyként gyűjtjük. Ezután a játékos dönt arról, mikor fogyasztja el vagy készíti elő. A jelenlegi növényi véletlent ez váltja fel, nem egy újabb büntető réteg kerül mellé.

## 3. A dzsungel éléskamrája

Egy mennyiség a táblázatban egy adag. Az értékek a terv belső számai: a választási kártya nem írja ki előre a rejtett jutalmat. Az ismert veszélyt és az eszközigényt viszont jelzi.

| Növény / élelem | Felismerhető jel és lelőhely | Felhasználás | Egy adag tényleges hatása |
|---|---|---|---|
| Parázsbogyó — `ember_berries` | Piros, hármas fürt; csillag alakú levél. Tábor környéke, liget. | Kezdettől ismert, megbízható úti étel. | +12 Food, +2 Water. |
| Harmatkörte — `dew_fruit` | Sárga, csepp alakú termés széles levéltölcsérben. Folyópart, eső utáni liget. | Kevésbé laktat, jól hidratál. | +8 Food, +14 Water. |
| Lombfüge — `canopy_fig` | Narancsszínű bordás termés magas ágakon. Bambuszliget, romok pereme. | Tápláló zsákmány; biztonságos eléréshez Machete vagy eseménybeli ágrögzítés kell. | +18 Food, +6 Water. |
| Vasdió — `iron_nut` | Barna, hatszögletű kemény héj. Száraz erdei talaj. | Késsel felnyitható a táborban; sok étel, kis szomjúságköltség. | +22 Food, −3 Water. |
| Vadméz — `wild_honey` | Borostyánszínű csorgás üreges törzsön; rovarmozgás. | Jó étel és hangulatjavító, a megszerzése veszélyesebb. | +16 Food, +3 Sanity. |
| Szalaggyökér — `ribbon_root` | Lila csíkos, összecsavarodott gyökér, feltűnő világos levélfonák. Mangrove. | Táborban előkészítendő élelem. | Előkészítve +18 Food; nyersen +5 Food és Poisoned I. |
| Viaszbogyó — `wax_berries` | Kék, fehér pöttyös, kettes termés; vastag kerek levél. | Mérgező étel, de hasznos festékanyag útjelzéshez. | Elfogyasztva +6 Food és biztos Poisoned I. |
| Holdkalap — `mooncap` | Világos gomba, kék gyűrű a tönkön; nedves korhadék. | Veszélyjelző faj: gombás korhadéknál spórás esemény is lehet. Nem része a biztonságos főzési recepteknek. | Elfogyasztva +4 Food és biztos Poisoned II. |

### Gyűjtés és előkészítés

- Egy szokásos gyűjtési kísérlet továbbra is 1 idő, legfeljebb három különböző gyűjtési célponttal. Ez nem három véletlen ételfaj: a képen látható faj választásával konkrét adagot szerzünk.
- A megszokott, biztonságos bogyós esemény két adag Parázsbogyót adhat. A +24 Food később fogyasztható el; ez nagyjából a jelenlegi egyszeri +20 Food szerepét veszi át.
- Egy próbában legfeljebb egy Harmatkörte vagy egy Lombfüge szerezhető. A nagy hidratáló jutalom ne legyen egyetlen minijátékban többszörözhető.
- Szalaggyökér előkészítése: tábor, 1 Wood, 1 idő, legfeljebb három nyers adagból ugyanennyi kész adag. Egy adagnál is ugyanennyi a költség, ezért érdemes gyűjteni és tervezni.
- A hal/hús jelenlegi egyszerű, tábori elkészítése egyelőre megmarad. A gyökér külön előkészítési művelete az új növény sajátossága.
- A Viaszbogyó forralástól nem válik ehetővé. A Holdkalapnak nincs „egy kattintással biztonságosra főzöm” receptje.
- A gyümölcs és az elkészített étel a táborban és a nyugodt expedíciós megállónál fogyasztható, 0 időért. Aktív encounter, eredményablak, minijáték vagy viharhelyzet közben nem.
- A táboron kívüli tárgyhasználat külön, tudatosan engedélyezett művelet lesz. A mostani „csak camp” szabályt ehhez bővíteni kell.

### Fajismeret

- A Parázsbogyó kezdettől ismert. Az első veszélyes növény eseménye megtanítja, hogy a fajok tulajdonságai állandóak.
- Ismeretlen fajból egy mintát a táborban 1 időért meg lehet vizsgálni: a minta elfogy, a faj ismertté válik erre a menetre, ételjutalom nincs.
- Az elfogyasztott vagy megvizsgált faj bekerül a Journal „Jungle knowledge” részébe. Egy mérgezés után ugyanazt a fajt már egyértelmű figyelmeztetéssel látjuk.
- Az információ mentett adat; újratöltéssel a faj és az esemény kimenetele nem sorsolódik újra. Új menetben is ugyanaz a faj biztonságos vagy mérgező, így a játékos saját tudása is érték.
- Ismert veszély: „Toxic”, „Prepare at camp”, „Knife required”. Ismeretlen: fajnév, jellegzetes kép és környezeti utalás. A kártya nem fedi fel a pontos jutalmat és a rejtett dobást.
- A szín mellett a fürt, a levél, a héj és a mintázat is különbözik; a rendszer színtévesztéssel is olvasható.

## 4. Négy státusz, pontos szabályokkal

Az „időtick” egy elköltött játékbeli időegység. Nem valódi másodperc. A menü megnyitása, egy kártya olvasása, a telefon lezárása vagy a minijáték animációja nem sebez tovább.

| Státusz | Alap időtartam | Hatás egy aktív időtickben | További hatás | Kezelés |
|---|---:|---|---|---|
| Poisoned I | 4 időtick | −2 Health, további −1 Water. | Fizikai kockázatos döntések −10 százalékpont; aktív mérgezés alatt a pozitív Health-gyógyítás nem hat. | Antidote azonnal eltávolítja; külön gyógynövényes elsősegély rövidítheti. |
| Poisoned II | 4 időtick | −4 Health, további −2 Water. | Fizikai kockázatos döntések −15 százalékpont; ugyanaz a gyógyításkorlátozás. | Antidote eltávolítja. Nem kerül mellé még egy külön Poisoned I. |
| Injured | 6 időtick | Nincs automatikus vérzés vagy folyamatos Health-vesztés. | Fizikai kockázatos döntések −10 százalékpont; az új fizikai sérülések Health-sebzése ×1,2, felfelé kerekítve; gyógyítás és alvási Health-bónusz feleződik. | Bandage eltávolítja; pihenés gyorsítja a lejárást. |
| Wet | 3 száraz időtick | További −1 Food, −1 Sanity. | Önmagában nem rontja a rejtvényt vagy minden encountert. A csúszós terep külön, felismerhető helyzeti veszély. | Száradás, tábori tűz, jobb menedék. Esőben végzett új kültéri időtick 3-ra frissíti. |
| Exhausted | 4 időtick | További −1 Water, −1 Food. | Fizikai kockázatos döntések −10 százalékpont; a favágás/vadászat időzítési zónája szűkül. | Pihenés rövidíti, teljes alvás megszünteti. |

### Felhalmozódás és korlátok

- Egy típusból csak egy státusz lehet aktív. Az új azonos hatás időtartama `max(régi, új)`, nem összeadás.
- Új mérgezésnél az erősebb fokozat marad. Az enyhe mérgezés nem gyengíti le a már meglévő erőset.
- A normál sérülés alapból 6 tick, kisebb esemény adhat 3 ticket. Azonos hatása van, csak hamarabb gyógyul.
- A státuszok miatti extra fogyasztás felső korlátja időtickenként: +4 Water, +3 Food és −2 Sanity. A jelenlegi normál fogyasztás ezen felül értendő.
- Az Injured ×1,2 csak a fizikai találat közvetlen sebzésére vonatkozik; nem erősíti a mérget, az éhezést, a szomjazást vagy saját magát.
- Az új Poisoned a korábbi „rossz növény: azonnal −16 Health” helyébe lép azoknál az eseményeknél. Nem adunk automatikusan teljes régi sebzést és teljes új mérgezést egyszerre.

## 5. Eső, víz és terep

### Megázás: láthatatlan mérő helyett érthető állapot

A motor egy 0–6 közötti nedvességkitettséget tart nyilván. Ez nem új HUD-sáv. Félúton egy rövid „Your clothes are getting soaked” jelzés jelenik meg.

| Helyzet | Kitettség egy kültéri időtickben |
|---|---:|
| Napos kültér | −2, minimum 0. |
| Light rain | +2. |
| Storm | +3. |
| Táborban craft / pihenés / készletkezelés | Nem kap esőkitettséget. Időbe kerülő fedett művelet −2 kitettség. |
| Leaf Rain Cape felszereléssel | Az esőből származó növekedés −1: Light rain +1, Storm +2. |

- 6 kitettségnél Wet keletkezik, a kitettség 0-ra áll. Védelem nélkül három esős vagy két viharos időtick áztat át.
- Ha már Wet: az új esős kültéri időtick 3-ra frissíti a hátralévő száradást. Száraz időtickben rendesen fogy az időtartam.
- Gázolás vagy vízbe esés közvetlenül Wet-et adhat, a köpeny ezt nem akadályozza meg.
- **Dry by the fire:** táborban 1 Wood és 1 idő; a Wet a művelet kezdetén eltűnik. Más aktív státuszok ettől még tickelnek. Csak akkor választható, ha Wet aktív és van nappali idő.
- Fa nélkül fedett pihenéssel is lehet száradni, természetes lejárattal. Nincs olyan állapot, amelyből kizárólag egy ritka tárgy hozhat ki.
- A Tier 2–3 menedék az alvás elején eltávolítja a Wet-et. Ez a kültéri eső ellen nem ad immunitást.

### Az időjárás ad is valamit

- Esőben a Harmatkörte-esemény súlya ×1,5, a Vasdióé ×0,5 a növényes események kiválasztásakor. Ezek relatív súlyok, nem új jutalommennyiségek.
- Rain Collector esetén a jelenlegi esőbónusz megmarad.
- A rovaros mézgyűjtő esemény esőben ritkább: kiválasztási súly ×0,5. Ez nem jelenti, hogy a már megtalált fészket biztosan biztonságos megbolygatni.
- A csúszós átkelés saját kockázata esőben nő. Kézzel épített kapaszkodóval továbbra is lehet biztos megoldás.
- Új általános időjárás-sorsolás: 1. nap Sunny; 2–3. nap 70% Sunny / 30% Light rain; 4. naptól 60% Sunny / 30% Light rain / 10% Storm. Két egymást követő általános Storm nap nincs: előző Storm után 2:1 arányú Sunny/Rain sorsolás történik.
- A végső mentési vihar felülírja az általános időjárást, és továbbra is a megírt három helyzetből áll.

## 6. Fáradtság: a túl messzire merészkedés ára

Egy belső `strain` számláló 0-ról indul; nem külön fő stat és nem állandó HUD-sáv.

- Minden kültéren elköltött idő: +1 strain.
- Egy Go deeper döntés sikeres elindítása: további +1 strain; a későbbi következő megálló saját időtickjei emellett számítanak.
- Favágó vagy vadászó próbálkozás kezdete: további +1 strain a szokásos kültéri tick mellett. Kilépéssel nem visszavonható.
- Ha a tick végén Food vagy Water 15 vagy kevesebb: az a tick további +1 strain-t ad.
- 6 strain elérésekor Exhausted 4 tick keletkezik; a strain 0-ra áll. Újabb 6 ismét 4-re frissít, nem halmoz időtartamot.
- Egy tábori Rest 1 idő: a művelet végén strain −3 és Exhausted hátralévő idő −2, a természetes tickfogyáson felül. A tick indulásakor aktív büntetést még kifizeted.
- A Rest az Injured időtartamából is további 1 ticket levon. Mérgezést nem gyógyít.
- Alvás végén strain 0 és Exhausted megszűnik.

Így a játékos nem pusztán a három megmaradt időpontot számolja: egy elhúzódó expedíció végére gyengébben érhet el a következő találkozásig.

## 7. Veszélyes élővilág és eseményhelyzetek

Ezek eseménycsaládok a meglévő helyszíneken. Nem igényelnek nyolc új térképpontot vagy nyolc új minijátékot. A százalékok belső balanszértékek; az előnézet csak a kockázat jellegét, az eszközt és a költséget mutatja.

| Helyzet | Jel, döntés és következmény |
|---|---|
| **A törzs méze** | Riverbank/Bamboo: méz és köröző rovarok. Távol maradsz: nincs külön jutalom vagy büntetés. Füstölsz: 1 Torch felhasználásával biztosan 1 Honey. Kézzel benyúlsz: 65% 1 Honey; kudarc −6 Health, Injured 3 tick. A Torch-kártya nem használható újra ugyanabban az eseményben. |
| **A levelek őrzője** | Mangrove: apró élénk mintás béka ül a gyógynövényeken. Kikerülöd: biztosan elhagyod a foltot, zsákmány nélkül. Késsel levágod a távolabbi szárakat: 85% 2 Herb; kudarc Poisoned I. Puszta kézzel benyúlsz: 50% 2 Herb; kudarc −4 Health és Poisoned II. Nem jelenik meg váratlan békaméreg egyszerű, biztonságos „nézelődésnél”. |
| **Mozdul a korhadék** | Erdő: viaszos bogarak és felpuffadt gombák. Óvatos kerülés: nincs külön veszteség. Levélmaszkot rögtönzöl 1 Fiberből: biztos hozzáférés 1 Herbhez. Felfeszíted az üreget védelem nélkül: 60% 2 Herb; kudarc Poisoned I. |
| **Sötét víztükör** | Mangrove/Riverbank: zavaros gyökérmedence. Sietve iszol: +20 Water és biztos Poisoned I. Visszaviszed felforralni: az esemény alap idején felül +1 idő, 1 Wood; +28 Water, mérgezés nélkül. Elmész: nincs vízjutalom. A forralás teljes időigénye előre szerepel a részletpanelen. |
| **Éles zöld folyosó** | Bamboo: tüskés kúszónövény takarja a Lombfügét. Machetével megnyitod: biztos 1 Fig. Oldalt kerülővel mész: +1 idő, biztos 1 Fig. Átnyomod magad: 70% 1 Fig; kudarc −8 Health és Injured 6 tick. Az új sérülés nem erősíti visszamenőleg ugyanazt az ütést. |
| **A megcsúszó part** | Riverbank/Mangrove: sáros, meredek átkelés. Kapaszkodó 2 Fiberből: biztos átjutás. Kerülő: +1 idő, biztos átjutás. Ugrás: 85% Sunny, 70% Rain, 55% Storm; kudarc −8 Health, Wet és Injured 3 tick. Az esőmódosító ehhez az eseményhez tartozik, nem minden véletlen dobáshoz. |
| **Vér a zoknin** | Mangrove: vízben gázolás után, felismerhető esemény. A sekély átkelő használata előre 1 extra időért ezt elkerüli. Sietős gázolásnál 35% az apró sebek eseménye: −2 Health, −3 Sanity és Injured 3 tick. Nem ad külön ötödik „leeches” státuszt. |
| **Mélyebben morajlik** | Ruins pereme / erdei ösvény: zivatar előtti választás. Megállsz fedél alatt: +1 idő, nincs új esőkitettség erre az extra tickre. Továbbmész: szokásos kültéri kitettség és a következő egy átkelésre Storm-nehézség. A jelenség egyetlen mentett helyzeti jelző, a következő átkelés után lejár. |
| **A csíkos vadász nyoma** | Jungle Trail: friss állatnyom. 1 Viaszbogyó + 1 Fiber útjelzést hagy: a következő eltévedés típusú eseményt egyszer kivédi. Nem véd a jaguártól, méregtől vagy minden veszélytől. A nem ehető termésnek így is van értéke. A hatás a következő hazatéréskor lejár, nem halmozható. |

**Az esemény ideje:** az extra idő a helyszín vagy expedíciós lépés szokásos költségéhez adódik. 0 időpontba kerülő állatos encounter alapból nem lépteti a státuszokat; csak az explicit extra idő igen. Megtelt vagy túl kevés nappali idő esetén az extra idejű választás nem indítható, de a biztos elállás/kikerülés megmarad.

## 8. Encounter- és minijáték-hatás

### Kockázatos döntések

Minden kockázatos választás kap egy területet: `physical`, `mental`, `environment` vagy `none`. Egy státusz csak az arra értelmes területre hat.

Fizikai döntésnél:

`státuszbüntetés = min(25 százalékpont, Poisoned 10/15 + Injured 10 + Exhausted 10)`

`végső esély = clamp(alapesély − státuszbüntetés − alacsony-Sanity-büntetés, 10%, 95%)`

Az alacsony Sanity jelenlegi −15 százalékpontja megmarad. A képlet kizárólag eredetileg is kockázatos döntésekre vonatkozik. A biztos menekülést, 1 Torch-ért biztos elriasztást és más garantált felszereléses megoldást nem alakítjuk titokban véletlenné.

Példa 70%-os fizikai választásra:

| Állapot | Tényleges belső esély |
|---|---:|
| Egészséges | 70% |
| Poisoned I | 60% |
| Poisoned I + Injured | 50% |
| Poisoned I + Injured + Exhausted | 45%, a 25 százalékpontos státuszkorlát miatt. |
| Ugyanez Sanity <25 mellett | 30%. |

A fizikai minősítés például a lándzsás védekezés, átugrás vagy állattal való dulakodás. A romok jelképsorának megoldását nem tesszük véletlenszerűvé, és a gomba faji mérgezőségét sem változtatja meg a játékos Sanity-je.

### Ügyességi játékok

- Favágás és vadászat: Injured mellett GOOD és PERFECT félablak ×0,9; Exhausted mellett ×0,85. Együtt ×0,765; az összes negatív módosítás alsó határa ×0,75.
- A zóna középpontja és a jelző sebessége ettől nem változik. A játékos látja a szűkebb zónát; nincs siker után rejtett „mégis elrontottad” dobás.
- Fishing: Exhausted mellett a megtartó safe zone szélessége ×0,9. Az első kapás tutorialjának időablaka változatlan.
- Foraging: a mérgező és biztonságos faj azonosítása a játékos tudásán múlik; nincs elmosott kép vagy rejtett helycsere. A 8 másodperces időkeret változatlan.
- Ruins: a helyes jelképsor továbbra is mindig helyes. A státuszok csak az elköltött idő túlélési költségére hatnak.
- A minijáték induláskor rögzíti a nehézségi módosítókat. Nyitott próbában nem ugrik össze a zóna egy közben lejárt vagy keletkezett státusztól. Mentéskor ezek a módosítók is megmaradnak.

## 9. Kezelés és felkészülés

Az alábbi négy új tárgyrecepttel a jelenlegi 11 valódi tárgy 15-re nő. A táborfejlesztések továbbra is ezen felül értendők. A feldolgozott étel a Food fülön jelenik meg, nem számoljuk új felszerelésreceptnek.

| Recept | Követelmény / gyártás | Használat |
|---|---|---|
| Charcoal | Tier 0; 1 Wood + 1 idő → 2 Charcoal. | Antidote alapanyag. |
| Antidote | Tier 0; 1 Herb + 1 Charcoal + 6 Water + 1 idő → 1 adag. | 0 időért Poisoned I/II megszüntetése. Nem tölti vissza a már elveszett Health-et. |
| Bandage | Tier 0; 2 Fiber + 1 Herb + 1 idő → 1 adag. | 0 időért Injured megszüntetése, utána +4 Health. |
| Leaf Rain Cape | Tier 1; 6 Fiber + 1 Wood + 1 idő. | Birtokláskor automatikus esőkitettség-csökkentés. Ebben az MVP-lépésben nem kap külön kopásrendszert. |

Az időbe kerülő recepteknél a szokásos −4 Water / −3 Food és az aktív státuszok költsége is érvényes. Az Antidote 6 Water tehát **extra receptanyag**, nem a teljes elkészítési vízigény.

- Kész Antidote és Bandage használható a táborban nappal vagy éjszaka, illetve nyugodt expedíciós megállónál. Aktív döntés, minijáték, eredmény vagy viharhelyzet közben nem.
- A kezelés külön részletpanelről megerősítendő, és csak indokolt státusz esetén engedélyezett. Nem fogy el véletlenül egy egészséges karakteren.
- **Szükségmegoldás:** 1 Herb „Chew the bitter leaves” választással a Poisoned I hátralévő idejét 2-vel, Poisoned II-ét 1-gyel csökkenti, minimum 1-re. Nem gyógyít Health-et, és nem helyettesíti teljesen az Antidote-ot. Egy Herb egyszer használható; minimum 1 ticknél ez a választás tiltott.
- A meglévő Herbal tea nem lesz univerzális ellenszer: alapból megtartja a gyógyító szerepét, mérgezést nem töröl. Poisoned alatt nincs Health-gyógyítása; Injured mellett a pozitív Health értéke felezett, lefelé kerekítve.
- A mérgezés lejárhat kezelés nélkül is: az enyhe teljes időtartama önmagában 8, az erősé 16 Health. A fő veszély a szomjúsággal és más döntésekkel való összejátszás.

## 10. Időzítés, alvás és hatássorrend

### Normál művelet

1. Feltételek ellenőrzése és megerősítés. Ha nem indulhat el, nincs levonás vagy státuszváltozás.
2. Minden elköltött időtick elején rögzítjük az akkor aktív státuszokat.
3. Normál Food/Water fogyasztás, státuszfogyasztás és mérgezési sebzés; ezután hiány miatti Health-vesztés. Halálnál a további tickek megállnak.
4. A tick elején aktív státuszok időtartama csökken. Frissen keletkező kitettség/fáradtság-státusz csak a következő ticktől büntethet, akár ugyanazon több időbe kerülő művelet következő tickjében.
5. Az esemény közvetlen eredménye és az abból újonnan kapott státusz az esemény feloldásakor lép életbe; az új méreg nem sebzi visszamenőleg az imént elköltött összes időt.
6. Egyetlen eredményriport mutatja a végső tényleges változásokat. Előnézet, X és mentés nem ismétel hatást.

A minijátékoknál az idő már induláskor elköltődik, ahogy most is. A kísérlet végén újonnan szerzett méreg/sérülés nem alkalmazható az indulási tickre. A nehézség az induláskor rögzített.

### Alvás

1. Az alvás szokásos Water/Food/Sanity költsége egyszer levonódik.
2. Tier 2–3 menedék előbb eltávolítja a Wet-et.
3. Az éjszaka két **státuszticknek** számít. A normál nappali −4 Water/−3 Food nem fut le még kétszer; csak a státuszok extra fogyasztása/sebzése és lejárata.
4. A hiány miatti overnight Health-vesztés az összes költség után egyszer történik, a jelenlegi alvásmodellhez igazodva. Halálnál nincs gyógyítás vagy túlélési gratuláció.
5. Ha a két státusztick bármelyikében Poisoned volt aktív, aznap éjjel nincs alvási Health-visszatöltés, akkor sem, ha a második tickben lejár. Injured bármelyik tickben az aznapi Health-bónuszt felezi. A méreg megszüntetése még alvás előtt ezért értékes.
6. A meglévő tábori Sanity-/vízbónuszok megmaradnak. Exhausted megszűnik, strain 0.
7. A már működő napzáró megmutatja a túlélés utáni tényleges statokat, készletet és a megmaradt státuszokat. A Next day nem tickel újra semmit.

### Két konkrét számpélda

**Mérgezett hazafelé:** 80 Health / 70 Water / 50 Food, Poisoned I még 4 tick. Két időegységes út után, más hatás nélkül: 76 Health / 60 Water / 44 Food, Poisoned I még 2 tick. A megállónál egy már elkészített Antidote 0 időért megszünteti a mérget; a statok nem ugranak vissza a korábbi értékre.

**Túltolt expedíció:** Poisoned II + Injured + Wet + Exhausted mellett egy tick −4 Health, −7 Water, −5 Food és −1 Sanity, amíg mindegyik aktív. Egy új 10 Health-es fizikai találat Injured miatt 12-t sebez, de a méreg tickje továbbra is 4 marad. Ez már tudatos visszafordulást vagy felkészített kezelést kíván, nem érdemes folyamatosan továbbmenni.

## 11. Felület és visszajelzés

- A HUD statjai alatt egyetlen kompakt állapotsor: ikon + `4`, `6`, `3` stb. Nem készülnek nagy új panelek, amelyek eltakarják a jelenetet.
- Koppintásra pergamentes státuszlap: aktuális ismert hatás, hátralévő idő és lehetséges kezelés. Például: „Poisoned · 3 time remaining · Losing health when time passes”.
- A Wet és Poisoned külön alakú ikont kap, nem csak más színt. Poisoned II ugyanaz a szimbólum, egyértelmű II jelöléssel.
- Első megszerzéskor egy rövid magyarázat jelenik meg. Nem állítjuk meg újra ugyanazzal a bemutatóval minden találkozásnál.
- A döntési kártya változatlan, egységes méretű. A részletpanelen lehet egy sor: „Weakened by poison and injury”. A hatás nem vesz el új sort minden kártyaképből.
- Az eredményablak külön sorban jelzi: „Poisoned acquired”, „Wet refreshed”, „Injury treated”, „Exhaustion expired”, és együtt összesíti az adott művelet tényleges veszteségeit.
- A napi összesítőn a státuszok kis sorban a statok alatt, az anyagkészlet felett jelennek meg. Egészséges állapotnál ez a sor hiányzik.
- A Foraging útmutató fajismereti oldalt kap. A Journal megőrzi a felismert fajokat és a kezelések leírását az adott menetben.

## 12. Bevezetés és méltányosság

- Első nap a biztonságos bogyó, egy ismert gyógynövény és a „gyűjtés ≠ automatikus evés” szabály jelenik meg. Egy egyszeri tanító esemény 2 Herbhez juttat; a forrás és az egyszeri teljesítés mentett.
- Poisoned II források legkorábban a 3. napon jelenhetnek meg, miután a gyenge mérgezés lehetőségét már megmutatta a játék.
- Az első eső előtt/rögtön az első esőnél rövid utalás a köpenyre és a tűznél száradásra. Az eső nem áztat át azonnal egy képernyőváltáskor.
- A ritka tárgy nélküli elállás/kikerülés mindig megmarad. Ez a szűkös készletű játékos döntése, és nem ugyanaz, mint a jutalmas választás.
- A vihar három kötelező helyzetének felszerelés nélküli fallbackje nem válik állapothatás miatt rejtett esélydobássá. A túlélésükhöz szükséges Health-et külön újramérjük aktív státuszokkal is.
- A korábbi sebzéses események felülvizsgálata kötelező: ne kapjon automatikusan minden régi Health-vesztés mellé újabb státuszt.
- Nem randomizáljuk menetenként a mérgező faj színét. Újratanulás helyett a tudás legyen a játékos fejlődésének része.

## 13. Javasolt implementálási sorrend

1. **Státuszmotor:** mentett típus, fokozat, időtartam, közös tick, lejárat, gyógyításkorlátok, eredményriport. Először a meglévő veszélyes növény/sérülés eseményekkel.
2. **Élelem és tudás:** új fajazonosítók, készletbe gyűjtés, használat, előkészítés, felismerés, Journal; a mostani próbánkénti növénybiztonság kivezetése és régi sessionök migrációja.
3. **Védelem:** négy új recept, kezelési műveletek, Leaf Rain Cape, tűznél száradás.
4. **Világreakciók:** esőkitettség, strain, eseménycsaládok, esély-/minijáték-módosítók. Utána általános Storm napok.
5. **UI és art:** státuszikonok, fajonként önálló itemikon és hátteres kártyakép, eseményváltozatok; a jóváhagyott kamera és karakterreferencia használatával.
6. **Balansz:** új és régi menetek azonos seedeken, státuszos mentés/folytatás, emberi teljes menet. Csak mért eredmény után véglegesítjük a számokat.

### Kötelező ellenőrzések

- Mérgezés ténylegesen időtickre sebez; olvasás, háttérbe kerülés és újratöltés alatt nem.
- Két időbe kerülő utazás pontosan két státuszticket ad, nem egyet és nem képkockánként sokat.
- Új méreg nem sebzi visszamenőleg az esemény költségét; a gyógymód nem adja vissza a már elveszett Health-et.
- Poisoned I/II frissítés, lejárat és gyógynövényes minimum 1 tick; nincs végtelen, ingyenes időgyorsítás.
- Guaranteed választás garantált marad; fizikai módosítók nem érintik a romok helyes megoldását vagy egy növény faji tulajdonságát.
- Minijáték-mentés azonos nehézséget és azonos növénytulajdonságot állít vissza.
- Alvás nem számolja kétszer a normál nappali fogyasztást; nem éleszti fel a halott karaktert; a napzáró nem ismétli meg a sebzést.
- Régi save státuszok és fajismeret nélkül beolvasható. Régi, folyamatban lévő foraging session a saját mentett eredményével fejezhető be; az új faji szabály csak az új sessionökre érvényes.
- Eső a fedett táborban nem növel kitettséget; köpeny nem akadályozza meg a vízbe esést.
- Előzetes célértékek: egyetlen enyhe mérgezés normál készlettel ne legyen önmagában végzetes; két-három figyelmen kívül hagyott veszély jelentősen rontsa az expedíciót; előkészített kezeléssel érezhetően javuljon a túlélés.
- A győzelem több különböző új menetből is elérhető marad. A teljes sikerarányt és menetidőt a mostani, túl megengedő alaphoz hasonlítjuk; nem feltételezzük, hogy a fenti számok már kiegyensúlyozottak.

## 14. Mi marad későbbre?

Ételromlás, testsúly/hőmérséklet fő stat, külön tízféle betegség, szezonok, komplex méregkeverés, státuszonként több súlyossági fokozat, tartós profilhoz kötött botanikai fejlődés. Az első változatban csak a Poisoned kap két fokozatot; a többi státusz az időtartamával különbözik.

Az első implementálható csomag tehát: **tanulható növényvilág + négy összekapcsolt státusz + előkészítés és kezelés + reagáló időjárás/terep**, a meglévő nap- és expedíciós rendszerre építve.
