# Dzsungel-ökológia — megvalósítás

2026-10-15. A terv első játszható változata be van kötve a Flutter-játékba.

## Mi működik?

- Négy mentett állapot: Poisoned I/II, Injured, Wet és Exhausted. Kizárólag elköltött játékidőre hatnak. A menü, képernyőváltás és mentés nem lépteti az időt.
- Közös hatássorrend: költség → idő és meglévő státuszok → esemény eredménye → új státusz. A halott karakter nem kap utólag gyógyító jutalmat.
- A fizikai kockázatok állapotbüntetése legfeljebb 25 százalékpont. A biztos választás biztos marad. A rejtvénymegoldás nem kap rejtett dobást.
- Nyolc állandó tulajdonságú növényi élelem és elkészített gyökér. Az új gyűjtés adagokat tesz a készletbe, nem etet automatikusan. A korábban mentett, folyamatban lévő növényes próbák a saját régi eredményükkel fejezhetők be.
- Fajismeret: Parázsbogyó kezdettől ismert; vizsgálat vagy fogyasztás után a többi faj is bekerül a Journal részbe. Vizsgálat: egy minta és egy idő. Gyökér-előkészítés: egy fa, egy idő, legfeljebb három adag.
- Új receptek: faszén, ellenszer, kötszer, levélköpeny. Az első három többször gyártható készlet, a köpeny birtokolt felszerelés.
- Ellenszer és kötszer a táborban vagy nyugodt expedíciós megállónál használható. Gyógynövényes elsősegély rövidíti a mérget, de nem törli az utolsó tickjét. A hal, nyers hús és tea elkészítése továbbra is tábori művelet.
- Esőkitettség, köpenyvédelem, tűznél szárítás, terhelés, pihenés és két éjszakai státusztick. Az alvás a szokásos nappali költséget nem vonja le ismét.
- Új időjárássorsolás és esőfüggő növényes eseménysúlyok. A végső mentési vihar elsőbbséget élvez.
- Tizenkét új eseménybejegyzés: három élelemforrás és a terv kilenc veszély-/felkészülési eseménycsaládja. Mindenhol van külön költség nélküli elállás. Az erős békaméreg és a Holdkalap legkorábban a harmadik naptól jelenik meg.
- Az útjelző egyszer segít eltévedésnél; a következő átkelés viharmódosítója külön mentett jelző. Hazatéréskor mindkettő lejár.
- A favágás/vadászat időablaka és a horgászat zónája rögzített, menthető állapotmódosítót használ. A sikeres ügyességi eredmény után nincs újabb rejtett dobás.

## Felület és képek

A pergamentes UI megmaradt. A HUD kis, megnyitható állapotikonokat kapott. Az Items részletlapról tanulható faj, fogyasztható étel, kezelhető állapot és készíthető gyökér. A tűznél szárítás külön megerősítést kér. A Journal és a gyűjtési útmutató ismerteti az új szabályokat. Az eredmény és napzáró a tényleges változásokat és a megmaradt állapotokat mutatja.

A kártyák továbbra is egységes, 112×172-es alapméretűek; a részletek külön panelen vannak. A három új atlasz eredeti képe rendereléskor kerül kivágásra: hátteres 3:2 kártyaképek és külön átlátszó tárgy-/státuszikonok. A békás jelenet a jóváhagyott kamerát és karaktert használja.

**Valódi Flutter-képernyőképek:** [screenshots/survival-ecology-v1](../../screenshots/survival-ecology-v1/README.md).
**Korábbi látványtervek:** [ui](ui/README.md).
**Generálási promptok:** [ART_GENERATION.md](ui/ART_GENERATION.md).

## Ellenőrzés és korlát

A teljes tesztcsomag és a célzott állapot-/UI-tesztek eredményét a screenshot README rögzíti. A régi mentések betöltését, egyszeri elszámolást, alvást, ismételt tárgyhasználat tiltását, megőrzött minijáték-módosítókat és kis képernyős/nagy betűs nézeteket is ellenőriztük.

Két meglévő, erőforrásokat ténylegesen megszerző végigjátszás seedje: 42 és 77. A tesztjátékos az új, biztonságos élelmeket is fogyasztja. Ezek a tesztek pontos minijáték-vezérlést használnak: a teljesíthetőséget igazolják, az emberi játék nehézségét és végleges balanszát önmagukban nem. Következő lépés a többféle döntési stratégiát és hibázó ügyességi játékost mérő balanszfutás, illetve telefonos próba.

Nem került be ételromlás, új fő stat vagy külön betegségrendszer; ezek a tervben is későbbre maradtak.
