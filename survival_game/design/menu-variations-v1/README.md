# Főmenü — három új háttérváltozat

**2026-10-16: a jóváhagyott változatok bekötve.** [Működés és validáció](IMPLEMENTATION_HU.md) · [12 tényleges screenshot](../../screenshots/main-menu-v1/README.md). Az alábbiak a korábbi tervezési kör archivált leírásai.

2026-10-16 · Mindhárom háttér elfogadva. Frissített kezdőgomb: teljes világos pergamenes felület, sötétzöld felirat és nyíl, külön árnyék. Látványtervek, nincsenek bekötve. A splash jóváhagyott ösvényképe változatlan.

[Mindhárom ugyanazzal a pergamenes UI-val](00-overview.png)

| Változat | UI-előnézet | Tiszta generált háttér |
|---|---|---|
| A — teljes dzsungeltérkép | [Menü](A-world-map.png) | [Háttér](art/A-world-map.png) |
| B — folyóvölgy | [Menü](B-river-valley.png) | [Háttér](art/B-river-valley.png) |
| C — ködös romvidék | [Menü](C-misty-ruins.png) | [Háttér](art/C-misty-ruins.png) |

Az A az egész kalandot mutatja, kisebb léptékű helyszínekkel. A B egyetlen folyóvölgyet emel ki, tisztább képi hierarchiával. A C a rejtett romokat és a felfedezés hangulatát helyezi előtérbe. Tábor és karakter egyik képen sincs.

A három háttér a beépített image_gen eszközzel, három önálló generálásban készült; a csatolt játékbeli képek stílus- és környezetreferenciák voltak. [Teljes promptok](PROMPTS.md). Az eredetik megmaradtak a generáló mappájában; a projekt saját PNG-másolatokat tartalmaz. A logó és a gombok külön UI-rétegek, nincsenek a hátterekbe égetve.

A natív Flutter-előnézetek 390×844 logikai méretűek, 3× PNG-ként. Mindhárom terv elrendezése ellenőrizve 320×568, 844×390, 375×667 / 2× szöveg mellett; analyzer tiszta. A játék logikája és navigációja nem változott.

```sh
python3 design/menu-variations-v1/render.py
```

## Elfogadott váltakozás

A főmenü mindhárom hátteret használja majd. Menümunkamenetenként egy kép: A → B → C → A, az utolsó választás mentésével, így új appindításkor is folytatódhat a sorozat. A menü használata közben nem cserélődik a háttér; nincs automatikus képváltás a gomb megérintése közben. A splash külön ösvényképe marad.

A fő akció (Begin / Continue journey) mindhárom háttéren ugyanazt az elkülönülő gombot használja. Az új előnézetek ezt a javítást mutatják; a rotáció éles bekötése még hátravan.

A legutóbbi korrekció szerint a fő akciógombnak nincs zöld kitöltése: a pergamen végig látszik, csak a felirat és a nyíl sötétzöld.
