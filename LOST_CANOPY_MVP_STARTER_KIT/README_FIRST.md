# LOST CANOPY — MVP STARTER KIT

Ez a mappa a Lost Canopy MVP fejlesztésének kiinduló csomagja.

## Rövid pitch
Egy lezuhant túlélő a dzsungelben primitív levélmenedékből indul. A játékos napi akciókkal élelmet, vizet és nyersanyagokat szerez, minigame-eket teljesít, eseményekben dönt, craftol, fejleszti a tábort, új helyszíneket nyit meg, majd összegyűjti egy vészjeladó alkatrészeit. A végső cél a jeladó aktiválása és az utolsó nap túlélése a mentésig.

## Az MVP vizuális iránya
A véglegesített irány a `02_art/accepted/` mappában található.

**Master style reference:** `02_starter_camp_style_master.png`

Kulcsszavak:
- high-angle isometric / top-down
- egyszerű low-poly jellegű 2D illusztráció
- nagy, jól olvasható formák
- kevés apró részlet
- flat / soft shading
- nincs erős fekete comic outline
- mobilon olvasható UI
- meleg homok/barnák + dzsungel zöldek + türkiz víz

## MVP fő loop
`Camp → akció kiválasztása → helyszín/event/minigame → loot → vissza a táborba → craft/build → stat management → sleep → következő nap`

## MVP vége
A játékos összegyűjti a szükséges rádió/vészjeladó alkatrészeket, megépíti és aktiválja az Emergency Beacon-t, majd túléli a final storm napot. Ezután RESCUED ending.

## Első fejlesztési sorrend
1. Base screen + statok + nap/idő.
2. Inventory + resource rendszer.
3. Explore map + location rendszer.
4. Event/choice engine.
5. Craft/build rendszer + camp stage-ek.
6. Fishing minigame.
7. Foraging / chopping / hunting / ruins minigame-ek.
8. Save system + balancing.
9. Rewarded revive + rewarded supply drop + remove ads IAP.
10. Analytics és soft launch.

## Mappa tartalma
- `01_docs/` — game design, art bible, UX, monetizáció
- `02_art/accepted/` — elfogadott vizuális referenciák
- `02_art/references/` — inspirációs képek; nem másolandók 1:1
- `03_prompts/` — konzisztens asset generálási promptok
- `04_data/` — MVP adatkezdőkészlet CSV-ben
- `05_technical/` — javasolt implementációs struktúra
- `06_notes/` — scope és döntési log
