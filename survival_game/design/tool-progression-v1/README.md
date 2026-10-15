# Lost Canopy — balták és lándzsák

2026-10-15 · **Az elfogadott koncepciók archívuma; azóta elkészült a bekötés.** [Működő szabályok és validáció](IMPLEMENTATION_HU.md) · [12 tényleges screenshot](../../screenshots/tool-progression-v1/README.md). Az alábbi képek továbbra is a tervezési állapotot mutatják. Az elfogadott pergamentes felülettel, egyforma 112×172-es kártyákkal és 3:2 képablakokkal. A képek a játék Flutter-komponenseiből kirajzolt, előkészített állapotú koncepciók, nem működő gameplay screenshotok.

**[Mind a 9 képernyő egy képen](00-overview.png)** · **[Pontos mechanika és költségek](PLAN_HU.md)**

## Képek sorrendben

1. [Craft — három balta](01-workshop-axes.png)
2. [Craft — három lándzsa](02-workshop-spears.png)
3. [Balta fejlesztése — előnyök, feltételek és költségek](03-axe-crafting-details.png)
4. [Items — lándzsaválasztás és állapot](04-items-gear.png)
5. [Javítás megerősítése](05-repair-confirmation.png)
6. [Favágás előnézete, felszerelt baltával](06-chopping-loadout.png)
7. [Jaguár encounter — három egységes kártya](07-jaguar-encounter.png)
8. [Lándzsás döntés — teljes esély és sérülési hátrány](08-spear-decision-details.png)
9. [Favágás utáni eredmény és kopás](09-chopping-outcome.png)

## Javasolt fejlődés

| Család | Alap | Tier 1 | Tier 2 |
|---|---|---|---|
| Balta | Stone Axe · 10 állapot | Reinforced Axe · 16 | Salvage Axe · 24 |
| Lándzsa | Stone Spear · 10 állapot | Hunting Spear · 16 | Salvage Spear · 24 |

A jobb balták a tartósság mellett kicsit szélesebb GOOD zónát és próbánként +1/+2 Woodot kapnak, ha volt sikeres csapás. A Salvage Axe ügyes favágásnál extra Hardwoodot ad. A jobb lándzsák könnyebb GOOD időzítést és csak a lándzsás fizikai döntéseken +8/+15 százalékpontot adnak. A PERFECT továbbra is ügyesség kérdése.

A három egyforma kártya mindig rövid marad. Koppintásra jelennek meg a költségek és előnyök, majd külön Craft / Equip / Repair / Confirm művelet következik. Az esemény jutalma csak utólag jelenik meg. A 08-as terv sérült játékost szemléltet: 70% alap + 8 pont fegyver − 10 pont sérülés = 68% aktuális esély.

2026-10-15-ös korrekció: az eredmény víz/étel sorai a kiemelt fogyást mutatják (−4 Water, −3 Food), alattuk külön a megmaradt értéket és progress bart. Az idő külön óraikonnal, hátralévő és elhasznált időként látszik; nincs három számból álló nyilas képlet.

## Grafika és ellenőrzés

[Új, 9 cellás atlasz](assets/tools-atlas-v1.png) · [Built-in imagegen prompt, referencia és forrás](PROMPTS.md). A korábbi artok megmaradtak. Az atlasz csak tárgyakat tartalmaz; a hátterek a meglévő helyszínképek. A miniatűr rendszerikonok meglévő átlátszó ikonok; az új eszközök saját átlátszó kis ikonjai a bekötési körben készülnek.

A kilenc 390×844-es koncepció natív Flutterben, 3× PNG méretben készült, a renderelés widgetkivétel nélkül lefutott. Külön 1440×3280-as összesítő készült. Ez a vizuális és mechanikai tervezés körének ellenőrzése; nem helyettesít implementálási regressziós vagy készülékes tesztet. A játék működését ez a változás nem módosítja.

Újrarajzolás az app mappájából:

```sh
python3 design/tool-progression-v1/render.py
```

A vezetett első nap továbbra is az MVP utolsó fejlesztési lépése.
