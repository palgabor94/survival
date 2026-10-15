# Vezetett első menet — bekötés

2026-10-15. A tutorial a valódi app legelső, friss meneténél ajánlható fel. A későbbi új meneteknél nincs automatikus ismétlés. A meglévő aktív mentésekbe nem kerül utólag kezdőablak.

A GUIDE MY FIRST DAY elfogadja, a PLAY WITHOUT HELP átugorja. A döntés, az összecsukás, a hat ellenőrzőpont és az egyszeri nyitóesemények a normál, egyben mentett v3 snapshot részei. A profil külön tárolja az első döntést és a befejezést; régi profilnál az új mező hiánya már kezelt első indítást jelent. A teljesített tanítás a Guide alatt újraolvasható, a félbehagyott, eredetileg elfogadott tanítás ugyanabban a menetben folytatható. Új menetben csak a referenciajegyzetek érhetők el.

## Tényleges működés

- Hat valódi tranzakció: élelmiszer szerzése, biztonságos étkezés, új eszköz készítése, érvényes indulás, élve hazaérkezés és túlélt éjszaka.
- A menük megnyitása, sikertelen craft és pakolásból visszalépés nem teljesít célt.
- Az elfogadott vezetés egyszer használja a meglévő berry_patch, river_supplies és fire_dying nyitóhelyzeteket. A választások, költségek és jutalmak a rendes motorból jönnek. Mentés után nem választható újra ugyanaz a függő jutalom.
- Nincs tutorial-kezdőbónusz, ingyenes craft, statvédelem vagy külön XP.
- A Later összecsuk, a Skip guide leállít; a Guide menü az eredeti elfogadott menetben visszakapcsolhatja. Más sorrend nem blokkolja a játékot, későbbi napokon is folytatható a hiányzó feladat.
- Pergamenes coach a tábori vezérlők előtt, az Items panelen, a craft/pakolás görgethető tartalmában és az expedíciós/éjszakai jelenetben. A segítség a layout része, nem takarja el a gombok érintési területét. Kis magasságnál korlátozott magasságú, görgethető szöveg. Nincs új pulzáló vagy lapozó animáció.
- Eredményolvasáskor a coach nem jelenik meg. A rendes napzáró után külön egyszeri lezáró üzenet jön, és annak olvasatlan állapota is menthető.

A korábbi horgászat-/gyűjtés-/romsúgók, betegségek első eredménybeli magyarázatai és készletkezelő képernyők megmaradnak. A tervben leírt összes későbbi helyzethez még nem készült új, profilban tárolt automatikus coach; ez a bekötés a hatlépéses első menetre vonatkozik.

## Ellenőrzés

**462 teszt sikeres, 0 hiba, 0 kihagyás; analyzer tiszta.** A natív Flutter-tesztfuttató futtatta a teljes repository tesztkörét. Tizenkét tutorialteszt: teljes normál költségű nap köztes mentésekkel; első döntés; skip; collapse/resume; régi mentés; egyszeri nyitás; új menet; egyszeri lezáró üzenet; 320×568, 844×390, 375×667 és 2× szövegű camp/craft/pack.

A készülékes újratelepítés/process-kill ellenőrzést ez nem helyettesíti. A teljes rendszer nehézségének újramérése külön következő munka, itt nem változtak a balanszszámok.

[12 tényleges képernyőkép](../../screenshots/first-day-tutorial-v1/README.md). A motor konstruktorának `offerFirstRunGuide` kapcsolóját a valódi app új motor létrehozásakor kapcsolja be. Az injektált teszt-/screenshotmotorok ezt explicit kérik, így a régi előkészített állapotokat nem változtatja meg a kezdőablak.
