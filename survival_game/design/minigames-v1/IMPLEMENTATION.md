# Minijátékok bekötése · 2026-10-13

Mindhárom jóváhagyott minijáték játszható. [Tényleges gameplay képek](../../screenshots/minigames-v1/index.html).

## Elérés

A tábor **Menu → Gather around camp** menüjében Wood chopping, Foraging és Hunting választható. A meglévő három fő tábori akció megmaradt. Hét erdei esemény új, választható minijátékot kínál: berry_patch, fallen_branches, hardwood_grove, herb_glade, bamboo_shoots, river_roots, bamboo_tangle. Az eredeti választások is működnek.

A belépőképernyő ingyenes; START egyszer számolja el az időt. Táborból 1 nappali idő; eseményből az esemény függő akcióköltsége, legalább 1 idő. Minden időegység a meglévő szabály szerint 4 Water és 3 Food; az ellátmányhiány a meglévő egészségvesztést okozza. Ha ez halálos, nincs további játék vagy jutalom.

## Szabályok

| Játék | Interakció | Eszköz | Utólag elszámolt eredmény |
|---|---|---|---|
| Favágás | 3 időzített ütés, 12 másodperces határ, 0,5 másodperc ütési szünet | Használható Stone Axe | GOOD: 2 fa; PERFECT: 3 fa; MISS: 0. Két PERFECT további 1 Hardwood; három PERFECT további 2 Hardwood. |
| Foraging | 8 másodperc, legfeljebb 3 különböző növény, öt lapozható kártya | Bogyó/fiber kézzel; herb/gomba kés vagy machete; ismeretlen növény machete | Bogyó +7 Food; fiber 2; herb 1. Gomba +9 Food vagy −6 Health; ismeretlen növény 2 Herb vagy −8 Health. |
| Hunting | Mozgó, külön RGBA vaddisznó, 1 időzített dobás, 12 másodperc | Használható Stone Spear | GOOD: 2 Raw Meat; PERFECT: 3; MISS/időlimit dobás nélkül: 0. |

A GOOD/PERFECT zóna közös: a középtől legfeljebb 0,18/0,06 normalizált távolság. Favágásnál 1,6, vadászatnál 1,8 másodperces oda-vissza ciklus. Az időzítési visszajelzés látható, a konkrét jutalom és a növények veszélyessége csak az eredmény-popupban derül ki. A gomba/ismeretlen növény biztonsága a session létrehozásakor dől el, mentődik; visszatöltés nem sorsolja újra.

A balta és a lándzsa 10 állapotponttal indul. Egy próbálkozás kopása 1 + az elhibázott ütések/dobások száma; üres/korán befejezett próbálkozás is minimum 1. Nulla állapotnál START zárolva. A műhely a meglévő recept anyag- és időköltségével javítja teljesre; teljes eszköz nem javítható újra. Régi mentésben a meglévő eszköz teljes állapotú. Kés/machete/bot kopását ez a mérföldkő még nem vezeti be.

## Folyamat és mentés

A [balansz első lépése](../balance-stage1/REPORT.md) óta a sima baltás/lándzsás eseményválasztások is koptatnak 1 állapotpontot, siker és kudarc esetén is. A minijáték megnyitása nem koptat; befejezése egyszer számolja el a fenti minijátékos kopást. A törött eszköz a sima választáshoz sem használható.

- Ready → START → active → eredmény → tábor/expedíció/éjszaka/game over.
- Ready BACK ingyenes; eseményből az eredeti döntéshez tér vissza.
- PAUSE, rendszer-visszalépés, kilépési megerősítés és app háttérbe kerülése megállítja az időt és a célpontot. Visszatérés után explicit RESUME kell.
- Aktív kilépés megerősített, nem adja vissza az időt. A már elért ütések/növények eredménye megmarad.
- START, választás, ütés és szünet azonnal menthető állapotot küld; az aktív idő állása másodpercenként checkpointot kap. Visszatöltött aktív kör szünetelve nyílik meg. A félbeszakadt másodperc legfeljebb a legutóbbi checkpointig áll helyre.
- A jutalom egyszer kerül a GameEngine-be; utána csak az olvasatlan eredmény marad mentve. Ismételt tap vagy report-visszatöltés nem ad új zsákmányt.
- Expedíción a jutalom a hordott zsákmány része. Az utolsó nappali idő utáni eredmény a meglévő éjszakai ágra vezet. A végső mentési vihar alatt nem indítható gyűjtés.

## Képek és UI

Hat jóváhagyott asset került az assets/art mappába változtatás nélkül: három jelenet, két 3:2 növénykártya, egy átlátszó vaddisznó. Forrás és hash: assets/art/minigames_manifest_v1.json. A horgászat háttere változatlan.

Közös kompakt HUD; alul a vezérlők. Három egyforma növénykártya látszik, maximum 160 pontos szélességgel, 3:2 képpel; a többi swipe-pal vagy nyíllal érhető el. A kártyasor magassága az eszközfeltételnek és a nagyobb szövegnek is helyet ad. A műhely jelzi a balta/lándzsa állapotát és a javítás lehetőségét.

## Ellenőrzés

A gathering_test.dart a költséget, időzítést, eszközkaput/kopást/javítást, mentést, rejtett növényeredményt, megszakítást, egyszeri jutalmat, expedíciós zsákmányt, halált és éjszakai átmenetet ellenőrzi. A gathering_widget_test.dart tényleges tapokkal ellenőrzi az elérést, választást, időlimitet, szünetet, lifecycle-t, mentett kör folytatását és kilépést; 375 px mobilon, 844×390 fekvő nézeten és 150% szöveggel is.

A hosszú seedelt szimulációk az új minijátékokat is kezelik. A screenshotok tényleges production widgetekből készülnek, előkészített eszközökkel/állapottal; készülékes teljesítmény- vagy balanszmérést nem helyettesítenek. Tartós státuszok, fejlett eszközök és ritka zsákmány későbbi mérföldkő.
