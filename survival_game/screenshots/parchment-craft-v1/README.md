# Pergamentes UI – első megvalósított felületek

Az appban bekötött Craft és Camp fejlesztés, illetve Items Materials / Food / Gear. A kártya koppintásra részleteket nyit; kizárólag a panel megerősítése ad vissza parancsot a tábornak. A tábor végzi a tranzakciót, mentést és eredményablakot. A részletek olvasása és az X nem fogyaszt erőforrást.

Közös komponensek: lib/ui/parchment_components.dart. Normál szövegméretnél 112×172 kártyák, minden képen 3:2 arány; cím, rövid info és állapot fix helyet kap. Részleges sor középen, nincs kinyújtott Bait. Nagy rendszerbetűnél az összes kártya azonos mértékben nő. Fejléc és fő gomb helyben marad, hosszú tartalom görgethető. A többi képernyő még a korábbi UI-t használja.

Screenshotok: python3 screenshots/parchment-craft-v1/capture.py. A natív export az app valódi widgetjeit fotózza, és ellenőrzi a nyitást, bezárást, lockokat, megerősítést, egyenlő méreteket és a camp által végzett tárgyhasználatot.

Ellenőrzés: 14 camp_widgets + 15 expedition_widgets teszt sikeres. Kis mobil, landscape és 2× rendszerbetű is szerepel. Natív runner a meglévő tesztdeklarációkat hajtja végre, hálózati tesztfuttató nélkül.
