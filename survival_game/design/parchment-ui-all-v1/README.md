# Teljes pergamenes UI koncepció

A felhasználó elfogadta a pergamenes craft irányt, a sárga kijelölés helyett zöldet kért. A módosított eredeti generált terv: 01-craft-green-selection.png.

47 natív Flutterben szerkesztett statikus látványterv készült ugyanazzal a papírtextúrával, a meglévő jelenetképekkel és tárgyikonokkal. Ezek önálló tervek, nem a játék átépítése. A pontos nézetlista és szemléltető tartalom a manifest.json fájlban szerepel.

## Közös sablon

- 390×844-es mobilnézet, 3× PNG export.
- Minden kártya 112×172. A címhely 32, a kép 108×72 (3:2), a rövid info 22, az állapotsáv 26 magas; fennmaradó tér minden kártyán azonos.
- Három kártya egy sorban, 8-as hézaggal. Egyetlen kártya sem nyúlik ki.
- Sötétzöld kijelölés, egy kis zöld pipa. Azonos keretvastagság kijelölve is.
- Hosszú költségek és felszerelésfeltételek külön részletezőbe kerülnek.
- Egységes pergamenpanel és zöld X, külön vissza-kártya nélkül.
- Fő művelet sötétzöld gombon, másodlagos művelet visszafogott kerettel.
- Statjelzők a korábban generált külön PNG-k; kis tárgyikonok a játék meglévő háttér nélküli ikonjaiból.
- A játékos a táborban a meglévő regisztrált karakterréteggel szerepel.

## Lefedettség

Tábor 0–3 és éjszaka; Items Materials/Food/Gear; Craft és Camp; menü, napló, útmutató, gyűjtésválasztó; esemény- és craft-eredmény; éjszakai összesítő; új játék, szünet, megszakítás és horgászatból visszatérés; jelenetinfó, vereség; öt tutorial; térkép és célpont; expedíció; hat encounter; éjszakai esemény; horgászat indítás és tekerés; favágás, növénygyűjtés, vadászat; romok; jeladó; végső vihar; sikeres mentés.

Az encounter-kártyák az aktuális events.json első három választását mutatják rövidített nevekkel, a negyedik vízszintes görgetéssel jelenne meg. A kártyák nem mutatnak előre jutalmat. További történeti események és minden eredmény ugyanazokat az esemény/eredmény sablonokat használnák. Ez UI-sablonlefedettség, nem minden véletlen játékmenet-állapot exportja.

A képek készletei és statjai szemléltetők, nem egy összefüggő végigjátszás. A napló mérföldkőrésze és egyes tutorial-navigációk javasolt bővítések. A hosszú vagy sok választásos listák a végleges felületen görgethetők, a fejléc helyben marad. Nagy rendszerbetűhöz egységesen nagyobb közös sablon és kevesebb oszlop szükséges. A kis rajzolt papíregyenetlenség a generált mesterképen látható; a natív exportok pontos méretű panelgeometriát mutatnak.

## Export

`python3 design/parchment-ui-all-v1/render.py`

A renderer minden képnél ellenőrzi a Flutter renderhibákat. A teljes sorozatot áttekintőképeken vizuálisan ellenőriztük. A játék tesztjeit ez a tervezési feladat nem futtatja.

## Generált elemek

Built-in image_gen készítette a zöldre cserélt kijelölésű craft mesterképet és a paper-texture.png papírtextúrát. A jelenetképek és tárgyrajzok meglévő játékassetek. A generálási promptok a PROMPTS.md fájlban.
