# Játszható első nap és helyzetfüggő tutorial — terv

2026-10-15 · A felhasználó új sorrendje: **tutorial → balansz → záró készülékes ellenőrzés**. Ez felülírja a korábbi „balansz, majd vezetett első nap” sorrendet. Ez a dokumentum bekötés előtti terv; a látványtervek még nem jelentenek működő tutorialt.

## Alapelv

Az első napot valóban a játékos játssza végig. Az útmutató egy rövid aktuális célt ad, megmutatja a hozzá tartozó meglévő gombot, és a valóban sikeres művelet után lép tovább. Nem egy sorozat előre lapozható szövegablak, és a Next megnyomásából nem következtet teljesítésre.

Az alapfogalmak: döntésre telik az idő; gyűjtésből tárgy lesz, nem azonnali étkezés; az eszközöket elkészítjük; a tábori készlet és a hordott csomag különbözik; az expedícióból haza lehet térni; a nulla nappali idő után még éjszakai döntés és alvás következik. A megmentés távoli célját egy mondat jelzi; a profil/XP, minden recept és minden minijáték nem része az első képernyőnek.

## Bekapcsolás, átugrás, visszatérés

Első új, üres profilnál Day 1-en egy Welcome panel kínál **GUIDE MY FIRST DAY** és **PLAY WITHOUT HELP** választást. A játékos mindkét esetben ugyanazt a normál kezdőkészletet és statokat kapja. A döntés elmentődik; újraindítás nem nyitja meg ismét.

A coach kártyán **1/6**, egy rövid cél és legfeljebb két mondat szerepel. **Later** összecsukja egy kis „First-day guide” jelzéssé; ez nem számít skipnek vagy teljesítésnek. **Skip guide** kikapcsolja a vezetést, nem jár érte büntetés és nem írja át a készletet. A Guide menüből folytatható a félbehagyott tanítás. A már ismert magyarázatok szabadon újraolvashatók; a gyakorlás nem írja át az aktív menetet.

Régi aktív mentést nem indítunk újra és nem kapcsolunk rá automatikusan Day 1-es vezetést. A Guide-ban ott is olvashatók a súgók. Tapasztalt profil új menete alapból normál; kérhető újra vezetés. A kiválasztott perk nem vész el és nem vált vissza No Perkre.

## A hat ellenőrzőpont

| Pont | Megtanulandó | Valós teljesítési feltétel |
|---|---|---|
| 1. Gather | A kártyára koppintás részleteket nyit; a választás költ időt | Befejezett gyűjtési döntés, tényleges élelemtárggyal a készletben |
| 2. Eat | A zsákmányt külön meg kell enni | Sikeres, biztonságos étkezési tranzakció; a puszta Items-megnyitás nem elég |
| 3. Craft | Receptigény és megerősítés, költség egyszer | Az első valóban elkészült eszköz, normál receptből |
| 4. Pack | Tároló otthon, hátizsák útközben; eszköz külön | Érvényes csomaggal megerősített valódi indulás |
| 5. Return | Csak a vitt készlet érhető el; bármikor lehet hazatérni döntési ponton | Új zsákmánnyal vagy nélküle tényleges hazaérkezés és automatikus kirakodás |
| 6. Survive the night | 0/6 nem halál; éjszakai döntés, majd alvás és összesítő | Valóban túlélt éjszaka és Day 2; halálos éjszaka nem teljesíti |

Nem kötelező sorrendzár: a valóban már teljesített pontok kipipálhatók. A craft és expedíció felcserélhető, ha a készlet ezt indokolja; például Scavenger Kit mellett előbb fáért kell indulni. Nem tiltjuk le a többi képernyőt, és egy már elkészített eszközt nem kérünk újra elkészíteni. Ha valaki elhasználja/elveszti az ajánlott alapanyagot, a coach a következő elérhető gyűjtést ajánlja, nem ad ingyen pótlást.

## Normál kezdőkészlettel végigjátszható mintanap

A jelenlegi motor adataival, No Perk mellett:

1. **Forage → berry_patch / gather**: 1 idő; két Ember Berries és egy Fiber. Marad 5/6. A jutalom előre nem kerül a kártyára.
2. **Items → Ember Berries → Eat**: 0 idő; egy adag elfogy. Marad 5/6, az eredményben látszik a változás.
3. **Craft → Torch**: a normál recept 1 Wood +1 Fiber +1 idő; marad 4/6. Nem oktatói ingyenes eszköz.
4. **Map → Riverbank → Pack**: egy megmaradt bogyóadag és egy gyógynövény két helyet használ; a Torch külön gear. A játékos szabadon módosíthatja.
5. **Leave camp → river_supplies / rod_materials**: 2 idő; marad 2/6. Eredmény, majd **Return to camp**; a kirakodás automatikus, visszatéréskor nincs újabb utazásdíj. A táskánál ismert utazási költség látszik, a döntés zsákmánya csak utólag.
6. Két normál **Rest** vagy más elérhető 1 időnyi művelet: elfogy a maradék nappal. **fire_dying / torch**, majd **Sleep**. A fáklyás döntés normál követelménye és felhasználása marad. Következik a valódi napzáró és Day 2.

A bemutató renderere ezt a mintanapot a meglévő játékmotorral, rögzített eseményválasztás mellett ellenőrzi. Az útvonal 6 nappali időt költ, normál jutalmakkal; nem igényel külön kezdőbónuszt. Az alapvető statok a pillanatnyi recept/élelem/adatváltozásokhoz kötődnek; a tutorial ne másolja őket konstans szövegbe. A későbbi balanszváltoztatások után ezt a szerződéses útvonalat újra kell futtatni.

**Javasolt vezetett nyitás:** a vezetést választó új játékosnak az első tényleges Forage a meglévő berry_patch eseményt, az első Riverbank-megálló a river_supplies eseményt, az első éjszaka a fire_dying eseményt használja. Ugyanazokkal a normál választásokkal, költségekkel és eredményekkel. Csak a nyitó bemutatóhelyzet rögzített, nem adunk láthatatlan statvédelmet vagy utólagos gyógyítást. Az RNG-választásokat és az egyszer felhasznált nyitójelzőket menteni kell; visszatöltéssel nem jár ismételt bemutató/jutalom.

A játékos választhat másik lehetőséget vagy kiléphet a vezetésből. Ettől kezdve a coach az állapothoz igazodik. Ha mélyebbre indul vagy új napot kezd a hiányzó pontok előtt, a tanulás folytatható; a „first day” célból nem lesz menetet blokkoló határidő. Halálnál a normál összesítő jön, opcionális újrakezdési ajánlattal; nincs automatikus feltámasztás vagy reset.

## Felületi működés

A már elfogadott pergamen, sötétzöld hangsúly és normál kártyaméretek maradnak. Kis coach lap a jeleneten, a célgomb felett vagy mellett, egyértelmű mutatóval. A célt nem fedheti le; telefonon a cél RenderBox-területe alapján választott fenti/lenti pozíció kell, nem rögzített pixelkoordináta. Keskeny/fekvő nézet és nagy betű esetén rövid, görgethető alulról nyíló panelre válthat, de a fő célgomb maradjon elérhető.

A kis segítség nem sötétít el állandóan minden más UI-t, és nincs villogó/sárga kijelölés. Csökkentett animációnál nincs pulzálás. A cél és következő feladat szövegesen is szerepel, képernyőolvasóval követhető. Minden háttér és ikon meglévő, stílusban illeszkedő asset; nem kell új karaktert vagy jelenetet generálni.

Az eredmény-popup, döntés megerősítése és minijáték alatt a coach vár; nem nyitunk még egy magyarázó popupot ezek tetejére. A felhasználó bezárja az eredményt, és csak a következő nyugodt képernyőn jön a következő cél. Egyszerre egy aktív tanítás. A véletlen visszalépés nem fogyaszt időt és nem lépteti előre a tutorialt.

## Későbbi, első használathoz kötött magyarázatok

| Helyzet | Rövid tanítás |
|---|---|
| Első horgásztó | A meglévő horgásztutorial és ingyenes Try it first. Nyomva tartás/elengedés, akasztás, utána faj és keep/release. |
| Első favágás/vadászat/növénygyűjtés | A meglévő útmutató közvetlenül a valódi indítás előtt; a visszaolvasás ingyenes, a fő indítás normál költségű. |
| Első ismeretlen élelem | Study / prepare / eat különbség; a veszély ismert tulajdonság lehet, de a véletlen kimenet nincs előre leleplezve. |
| Első Poisoned / Injured / Wet / Exhausted | Egyetlen rövid állapotsúgó és az aktuálisan használható kezeléshez vezető link. Az ismeretlen, még nem történt hatásokat nem állítjuk be előre. |
| Első kopott/törött eszköz | Állapot és javításköltség, másik eszköz választása. A javítás nem új craft-XP. |
| Első megtelt csomag | Tárgymennyiség és helyigény; kiválasztás, pontos elhagyási megerősítés. Az X nem dob el semmit. |
| Első mentési komponens / rom / jeladó | A hazahozatal célja, kőtárcsák útmutatója, majd a mentési feltételek ott, ahol relevánsak. |
| Első menetlezárás | A tényleges összesítőn rövid XP/profil magyarázat; nincs XP-bónusz a tutorialért. |

A Guide menü kap egy **FIRST-DAY GUIDE** sort és „Learned” listát. Az egyes magyarázatok később is elérhetők; a rövid helyzetfüggő súgók egyszeri automatikus megjelenését profilban tároljuk. A tényleges aktív lépés, collapse állapot és befejezett menetcélok az aktuális menethez tartoznak.

## Mentés és bekötési sorrend

`TutorialProgress` javasolt mezői: verzió, enabled, accepted/skipped, completed checkpoint ID-k, nyitóesemény-jelzők, collapsed, várt képernyő/akció. A profil külön tárolja a már bemutatott helyzetfüggő súgó-ID-ket és a completedFirstDay állapotot. A meglévő, egyben írt profil+menet mentésben helyezkedjen el; ne legyen új, ettől független tároló. A jelenlegi háromas mentés új opcionális mezőkkel bővíthető, régieknél letiltott automatikus vezetési alapértékkel.

1. Tutorialmodell, stabil akcióazonosítók és állapotból számolt következő feladat; mentés/skip/resume.
2. Welcome és kis coach elemek a valódi képernyőkön. A rögzített nyitás csak a vezetést kifejezetten választó új menetnél aktív.
3. Items, craft, csomag és expedíció pontjainak tranzakciós megfigyelése; normál játék és XP változatlan szabályokkal.
4. Első éjszaka, Day 2 visszajelzés és a későbbi súgók elsőhasználati kapui.
5. Teljes tesztkör és tényleges screenshotok. **Csak ez után kezdődik a teljes balanszmérés.**

Ellenőrzés a bekötéskor: teljes mintanap normál költségekkel; más kezdőperkek; eltérő sorrend és elköltött alapanyag; visszalépés/skip/collapse/resume; régi mentés; eredményolvasás alatti szünet; hat pont után nincs újraaktiválás; beállított nyitóesemény egyszeri; halfogásgyakorlás nem ad XP-t; mérgezés vagy halál nem szorít tutorialhurokba; kis telefon/fekvő/2× betűméret/reduced motion. A segítő szöveg a motor aktuális adatait használja, ezért a balanszváltozás nem hagyhat elavult költséget a tutorialban.
