# Lost Canopy — saját hátteres kártyaillusztrációk v1

2026-10-12 · A teljes készlet jóváhagyva és implementálva.

**35 külön illusztráció** készült az összes jelenlegi kártyatárgyhoz. A jóváhagyott fáklya, lándzsa, rönkök, hal és visszavonulás képe megmaradt; további 30 kép külön imagegen-hívással készült. A Forage új képet kapott, középre helyezett bogyócsoporttal. A főtárgyak mindkét tengelyen középre komponáltak, saját, hozzájuk illő, sötétebb háttér előtt.

[Teljes kártyagaléria](../../screenshots/card-illustrations-v1/index.html) · [Friss 30 mobilképernyő](../../screenshots/unified-ui-v1/index.html) · [10 új expedíciókép](../../screenshots/expansion-v1/index.html).

## Méretek és közös megjelenítés

- Minden illusztráció 1536 × 1024 PNG, **3:2 képaránnyal**. A képekben nincs kártyakeret vagy felirat; ezek natív Flutter-elemek.
- Az álló kártyák szélessége legfeljebb **160 logikai pixel**, a vízszintes popupkártyáké legfeljebb **320**. Teljes szélességű szülőben is megtartják ezt.
- A képi ablak mindig **3:2**, középre igazítva. A vízszintes kártyák képe 96 × 64; a betöltés 720 × 480 dekódolási méretet használ.
- Egy világos külső keret és egy lekerekítés maradt. A kép és a szöveges mező a keretig tölti ki a kártyát.
- Az eseménykártyák egyetlen lapozható sorban, egyenlő magassággal jelennek meg: legalább 152 pixel, nagyobb képszélességnél vagy szövegméretnél egységesen magasabb változat.
- Normál 390 pixeles mobilon három eseménykártya látszik egyszerre; a további lehetőségek lapozhatók. Az eseménykártyák csak az akciót és az aktuális követelményt közlik. Jutalom, statváltozás és sikeresély csak a választás után, a tényleges eredményablakban jelenik meg.

Az `ActionCard` az explicit `image` után a központi `cardIllustrationFor` tárgyjegyzékből választ. A `wood` tárgy a rönkköteges `firewood` illusztrációt használja. Az ismeretlen tárgyaknál a korábbi `CardArt` megjelenítés marad tartalék. A kis HUD-, nyersanyag- és shortcutikonok továbbra is a meglévő `hud_atlas.png`, `card_art_atlas_v2.png` és `camp_objects_atlas.png` fájlokból töltődnek be.

A háttér sötétebb tónusa már az új illusztráció része; nem kerül külön fekete réteg a teljes tárgyra. A korábbi sötétített lombos háttér az ismeretlen tárgyak tartalék megjelenítésében maradt meg.

## Új tartalom

A katalógus 21-ről **28 eseményre**, a térkép 5-ről **7 helyszínre** bővült. A Bamboo Grove a 2. naptól, a Mangrove Shallows az 1. táborszinttől érhető el. Mindkét út kezdeti és mélyebb gyűjtési eseményt kapott. Új encounterek: krokodil a sekély vízben, darázsfészek, zsákmányt fosztogató majmok. A két új helyszín és a három találkozás saját izometrikus hátteret használ.

Javítva a hordott zsákmány nyilvántartása: ha egy útközben begyűjtött alapanyagot már elhasználtunk, a zsákmány elvesztése nem vonja le még egyszer. A kiinduló tábori készlet is megmarad.

## Ellenőrzés és források

**179 teszt sikeres, 0 hiba; analyzer tiszta.** A tesztek kis és fekvő képernyőt, kétszeres szövegméretet, a kártyaszélességet és képarányt, valamint teljes játékfolyamokat ellenőriznek. [Részletes tesztjelentés](VALIDATION_2026_10_12.md).

- [Pontos generálási promptok](../../assets/art/CARD_ILLUSTRATION_FULL_PROMPTS.md)
- [Képek forrásjegyzéke](../../assets/art/card_illustration_manifest_v1.json)
- [Új jelenethátterek promptjai](../../assets/art/EXPANSION_SCENE_PROMPTS.md)
- [Kártyajegyzék](../../lib/ui/card_illustration.dart)
- [Közös kártyakomponens](../../lib/ui/action_card.dart)

A natív screenshotok az implementált Flutter-widgetekből készültek. Készülékes ellenőrzés és kiadási build ebben a körben nem készült.
