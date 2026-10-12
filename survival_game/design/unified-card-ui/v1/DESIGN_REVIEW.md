# Lost Canopy — UI-áttekintés és tervezett kártyarendszer

## A tervezési kör célja

A meglévő játék képernyőinek közös vizuális nyelvet adni a `LOST_CANOPY_CARD_SYSTEM_PACK` alapján. A v1 képek előzetes látványtervek; a Flutter UI átírása későbbi munkaszakasz. A felülvizsgálat a UI-kódból, a rendelkezésre álló screenshotokból és a referencia-csomagból készült; ebben a körben teszteket nem futtattunk.

## Mit mutatnak a jelenlegi képernyők?

| Terület | Jelenlegi eltérés | Tervezett irány |
|---|---|---|
| Tábor | A `CampActionCard` saját megjelenést használ; a többi képernyő `ActionCard` kártyái más formanyelvet követnek. | Azonos keret, illusztráció- és címelhelyezés; a hub rövidebb tartalmú változatot kap. |
| Események | Az illusztrált döntések helyén többnyire általános Material ikonok vannak; a nagy `StoryHeader` sokat takar a háttérből. | Rövid, kompakt kontextuspanel; nagy tárgy-/akcióillusztrációk; látható helyzet és szereplők. |
| Expedíció | A loot, veszély és magyarázat egy nagy panelben szerepel. | Rövid loot- és danger-sáv, külön látható költség, két jól elkülönülő döntési kártya. |
| Craft / Camp | A hagyományos AppBar, TabBar és lista más képernyőstruktúrát ad; az eszközök nagyrészt egyszerű piktogramok. | Közös HUD, festett eszközök, kompakt receptadatok, kijelölt recept és tábor-előnézet. |
| Térkép | Nagy node panelek és alsó részletező blokk foglalnak helyet. | Kisebb helyszínjelölők, rövid kiválasztott-helyszín sáv és ugyanaz a kártyás döntési felület. |
| Horgászat | Külön fejléc és általános gombok; a bevezető szöveg a jelenet aljára kerül nagy panelben. | Közös HUD; rövid eszköz/csali állapot; illusztrált indulás/visszatérés kártyák; fárasztáskor kompakt mérőpanel. |
| Inventory | Főleg szöveges erőforrás- és eszközsorok. | Közös tárgycsempék, jól látható mennyiség és kijelölt fogyasztható tárgy. |
| Outcome / Game Over / Journal | A hagyományos dialógus és gomb megjelenése eltér az akciókártyáktól. | Közös eredmény-/naplópanel, festett tárgyikonok, egységes folytatás/vissza kártya. |

## A közös képernyőkeret

1. **HUD:** logó nélkül. Bal fent nap, időjárás és hátralévő idő; jobb fent Health, Water, Food, Sanity. A statikon a szám bal oldalán, ugyanabban a felső sorban van; alatta jobbra igazított vékony értékcsík. A nyersanyagok a statok alatt, jobbra igazítva jelennek meg.
2. **Kontextus:** rövid cím és legfeljebb 1–2 sor helyzetleírás. A teljes magyarázat később részletező nézetben olvasható; a látható döntéshez szükséges költség/feltétel itt sem veszhet el.
3. **Jelenet:** a központi szereplő, helyszín vagy építmény maradjon jól látható. A sötétítés a HUD és kártyák mögött legyen erősebb, a jelenet közepén enyhe.
4. **Releváns információ:** csak az adott döntéshez tartozó felszerelés, loot vagy veszély. Teljes Inventory ne kerüljön minden encounter fölé.
5. **Kártyasor:** legfeljebb 3–4 döntés. Három rövid kártya egy sorban; négy összetettebb választás kis mobilon 2×2-ben. Az Inventory gyorsgomb a kártyák fölött marad.

## Kártyák közös anatómiája

**Illusztráció → rövid cím → feltétel → költség / következmény → státuszcímke.**

- Közös lekerekített sziluett, visszafogott dupla keret és árnyék, azonos belső térközök.
- Az illusztráció nagy, egyszerű low-poly / flat-shaded tárgy vagy mini jelenet legyen. A festett játékikon és az általános rendszerpiktogram ne keveredjen ugyanazon a tartalmi szinten.
- A hub kártyái rövid, színezett felületű változatok; az összetettebb eventek világos homokszínű adatmezőt is használhatnak. A keret, sorrend és státuszcímke ettől még közös.
- A kiválasztott kártya fényesebb keretet kap; a megnyomás nem változtatja meg a környező elemek méretét.
- A zárolt opció látható marad, deszaturált illusztrációval, lakattal és a konkrét hiánnyal. A hiányzó feltétel szövege nem halványulhat olvashatatlanná.
- A READY, OWNED, SAFE, RISKY és LOCKED feliratok tényleges játékállapotból származzanak. Az egyes színek önmagukban nem helyettesítik a feliratot vagy ikont.

| Színcsalád | Szerep |
|---|---|
| Dzsungelzöld | Gyűjtés, biztonságos lehetőség, elérhető cselekvés |
| Homok / földbarna | Eszközök, receptek, építés |
| Folyókék | Utazás, visszatérés, időt érintő navigáció |
| Rozsdavörös | Veszély, kockázatos következmény |
| Szürkített földszín | Hiányzó feltétel vagy zárolás |
| Krém | Cím és olvasható szöveg a sötét panelen |

## Mobilméretek az implementációhoz

A képek vizuális arányokat szemléltetnek, nem pixelpontos specifikációk. A Flutter-elrendezést 390×844 logikai pixelből kiindulva, kisebb kijelzőre és nagyított szövegre is adaptálni kell.

- Külső margó: 12–16; kártyák közötti hézag: 8–12; belső térköz: 4/8 alapú.
- Minden tappolható felület érje el a 48×48 logikai pixelt, a kis HUD-ikonokhoz is nagyobb érintési terület tartozzon.
- Kártyacím: jellemzően 15–18; feltétel/költség: 12–14. A hosszú cím tördelhető, a fontos költség nem tűnhet el levágással.
- Nagyított szövegnél a kártyák váltsanak egymás alá helyezett, vízszintes elrendezésre. A megfelelő görgetési margóval minden döntés elérhető maradjon.
- SafeArea és rendszer-navigációs hely szükséges a fix alsó kártyákhoz.
- A generált képeken látható számok/szövegek bemutató adatok; a végleges UI az aktuális játékadatokat rendereli.

## Javasolt implementációs sorrend

1. Közös HUD, panel-, keret-, szín- és tipográfia-tokenek.
2. Az `ActionCard` és `CampActionCard` közös vizuális alapra hozása; hub, choice, recipe, build, activity és outcome változatokkal.
3. A szükséges festett ikonok külön átlátszó assetként való elkészítése. A mockupból származó beégetett felirat ne legyen futásidejű UI.
4. Tábor és `SceneLayout` egységesítése, a nagy `StoryHeader` tömörítése.
5. Craft / Build és Explore átállítása a közös keretre.
6. Horgászat, Inventory és a dialógusok egységesítése.
7. Külön ellenőrzési kör: kis kijelző, nagy szöveg, zárolt/kiválasztott állapot, valódi játékköltségek, friss screenshotok.

## Újrafelhasználható art-lista a következő körhöz

Elsőbbség: kalapács és fejsze, kés, lándzsa, fáklya, bot és úszó, csali, hal, víztároló, menedék, hátizsák, visszatérési nyíl és ösvény. A stat- és alapnyersanyag-ikonok meglévő családját meg kell tartani. Ezek a mockupokban már vizuálisan szerepelnek, de nem készültek belőlük külön, átlátszó, alkalmazásba importált ikonfájlok.

## Tervezési határ

Az UI-terv nem ad hozzá craft queue-t, új lootot, XP-t vagy új beacon-funkciót. A referencia-csomag játékötletei és a kész kód külön állapotot jelentenek; az implementáció során csak létező választásokat és adatokat szabad aktiválni. A guide, restart- és fishing-exit megerősítők a napló/eredménypanel közös keretét és a jól olvasható, kompakt döntési kártyákat kapják.
