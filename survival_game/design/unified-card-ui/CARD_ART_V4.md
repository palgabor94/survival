# Lost Canopy — kártyagrafika v4

2026-10-12 · Az ADD WOOD felhasználói referenciakártyához igazítva.

**Aktuális változat: [35 saját hátteres kártyaillusztráció, implementálva és tesztelve](CARD_ILLUSTRATIONS_V1.md).** Az alábbi V4 leírás a korábbi atlaszos megjelenítést dokumentálja.

A kártyáknak egyetlen világos külső kerete van, egyetlen lekerekítéssel. Nincs belső szegély vagy a kép körül sötét keretsáv: a kép és a szövegmező a külső keretig kitölti a felületet.

Az álló kártyák felső része hátteres tárgyillusztráció, alul világos, tónushoz igazított szövegmező található. A képi felület aránya minden kártyán 3:2, a kártya szélessége legfeljebb 160 logikai pixel, teljes szélességű szülőben is. A vízszintes popupgombok képe oldalt marad, ugyancsak 3:2 aránnyal; ezek teljes szélességének felső határa 320 logikai pixel.

A generált lombos hátteret csak a megjelenítésben sötétítjük 35%-os fekete szűrővel. A tárgyrajzot ez nem érinti, így a zöld tárgyak is jobban elkülönülnek a lomboktól. A fa kártyaképe rönkköteg; a HUD-ban a kompakt farönk marad.

A három atlasz 32 különböző ikonjához egyedi forrástéglalap tartozik. Megszűnt az azonos cellamargóval történő kivágás, amely különösen a széles tárgyaknál, illetve a vízszűrő és esőgyűjtő tetején csonkolta a rajzot. A kivágás és az aránytartó illesztés közös `CardArt` komponensben történik, a HUD és a shortcutok is ezt használják. Az eredeti atlaszfájlok megmaradtak.

Az eventkártyák egyetlen lapozható sorban jelennek meg. A sor minden kártyája azonos magasságú, legalább 152 logikai pixel; a szélesebb képi felület vagy nagyobb betűméret szükség esetén növeli ezt. Rövid akciónév és meglévő követelmény jelenik meg, előzetes jutalom, eredmény vagy sikeresély nélkül. A teljes eredeti akciónév tooltipben is elérhető. A választás tényleges eredménye az utána megjelenő popupba kerül.

A többi álló kártya szöveges részének magassága a tartalomhoz igazodik, a képarány állandó. Normál 390 pixeles mobilnézetben továbbra is három eventkártya látható egyszerre.

Elkészült egy saját háttérrel generált fáklyás minta, kizárólag külön előnézethez. A teljes új illusztrációkészlet és annak játékba illesztése a felhasználó mintára adott visszajelzése után következik. [Fáklyás minták](../../screenshots/card-illustration-example-v1/README.md).

[Az új kártyák és az összes ikon galériája](../../screenshots/card-art-v4/index.html) · [Teljes képernyőgaléria](../../screenshots/unified-ui-v1/index.html) · [A háttér pontos generálási promptja](../../assets/art/CARD_FOLIAGE_PROMPT.md).

A galériák tényleges Flutter-widgetek screenshot-exportjai. Az automatizált játék- és widgetteszteket, `flutter analyze` futtatást, alkalmazásbuildet és készülékes ellenőrzést a felhasználó korábbi kérése szerint nem indítottuk el.
