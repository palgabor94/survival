# Minijáték látványtervek · v1

[Galéria](index.html) · [Részletes terv](DESIGN.md) · [Promptok](PROMPTS.md) · [Ellenőrzés](validation.json)

- Favágás: indítás, időzítés, tökéletes/hibás ütés, sikeres/sikertelen eredmény, szünet, kilépés, eszközhiány.
- Növénygyűjtés: indítás, választás, kijelölés, második kártyalap, sikeres/kockázatos eredmény, időlimit, szünet, kilépés, eszközhiány.
- Vadászat: indítás, célzás, tökéletes/hibás dobás, sikeres/sikertelen eredmény, szünet, kilépés, eszközhiány.

28 mobil állapotterv és 9 adaptív változat (375 pontos mobil, fekvő nézet, 150% betűméret). A PNG-k valódi Flutter komponensekből renderelt, különálló design-előnézetek. A jóváhagyott körök már játszhatók a játékban: [bekötési dokumentáció](IMPLEMENTATION.md), [tényleges gameplay screenshotok](../../screenshots/minigames-v1/index.html). Ez a galéria az eredeti látványterveket őrzi.

A `assets/` könyvtár hat kiválasztott generált képet tartalmaz: három 941×1672 hátteret, két 1536×1024 kártyaképet és egy RGBA vaddisznó-sprite-ot. A sprite első változata is megmaradt korábbi próbának; a tervek a v2-t használják. Minden generálás a built-in image_gen eszközzel készült. A pontos promptok és referenciafájlok a PROMPTS.md-ben és manifest.json-ben vannak.

## Újrarenderelés

Az alkalmazás gyökeréből, a már telepített Flutter SDK-val:

```sh
python3 design/minigames-v1/tools/render_previews.py
python3 design/minigames-v1/tools/build_gallery.py
```

Az exporter nem indít gameplay-teszteket, nem ír játékmentést és nem használ GameEngine-műveleteket. A komponensek a meglévő app UI-jából származnak, a speciális minigame-vezérlők tervezési mockupok.
