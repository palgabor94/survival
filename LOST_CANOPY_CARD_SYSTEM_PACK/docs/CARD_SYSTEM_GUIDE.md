# Lost Canopy — Card System Guide

## 1. Design cél
A Lost Canopy ne klasszikus menüalapú survival legyen, hanem **card-driven survival adventure**. A játékos szinte minden fontos döntést kártyán keresztül hoz meg.

A kártya mindig közölje a játékossal:
- **Mit csinálok?**
- **Mi kell hozzá?**
- **Mibe kerül?**
- **Mi lehet a jutalom?**
- **Mekkora a kockázat?**

## 2. Egységes képernyőstruktúra

### HUD
Mindig ugyanaz:
- Health
- Water
- Food
- Sanity
- opcionálisan alap resource counterek
- Day + Weather

### Context panel
Eventnél: cím + 1–3 sor leírás.
Craftnál: kiválasztott recipe.
Buildnél: kiválasztott upgrade.
Fishingnél: activity state.

### Scene
A képernyő középső része mindig megmutatja, mi történik a világban. Ez a játék érzelmi/vizuális része.

### Card row
Alul 3–4 nagy kártya. Mobilon egyszerre maximum 4.

## 3. Kártyatípusok

### Action Card
Event döntésekhez.
Példák: Use Torch, Use Spear, Retreat, Search Cargo.

Mezők:
- title
- art/icon
- requirement
- time_cost
- item_cost
- reward_hint
- risk_tag
- enabled/locked

### Recipe Card
Craftolható tárgy.
- item art
- ingredients
- category
- gameplay bonus
- loot tier unlock

### Build Card
Camp upgrade.
- building art
- materials
- passive effect
- unlocks
- visual camp change

### Activity Card
Fishing, hunting, foraging.
- activity art
- tool requirement
- minigame modifier
- loot pool

### Outcome Card
Esemény után rövid eredmény:
- success / failure
- kapott loot
- elvesztett item
- damage / status
- elapsed time

## 4. Card státuszok
Ajánlott vizuális tagek:
- **SAFE** — zöld
- **LOW RISK** — olív / sárgászöld
- **RISKY** — vörös
- **COSTS ITEM** — narancs
- **GOOD LOOT** — arany/barna
- **STORY** — lila
- **LOSE TIME** — kék
- **LOCKED** — szürke

A tag ne legyen pusztán dekoráció: tényleges gameplay kategóriát jelöljön.

## 5. Requirement logika
A kártya három állapotú lehet:

### Available
Minden requirement megvan. Teljes szín, kattintható.

### Available but risky
Nincs item requirement, de stat/risk alapján veszélyes. Kattintható, piros warning.

### Locked
Hiányzik az item/perk/stat. Szürkített, lock ikon, pontos hiányzó requirement.

Példa:
`USE SPEAR — Requires: Stone Spear`

Ha nincs spear, a kártya maradjon látható, de locked. Ez tanítja a játékost arra, mire lenne szüksége legközelebb.

## 6. Jobb felszerelés = háromféle előny
Minden tool upgrade lehetőleg adjon egyszerre:
1. könnyebb minigame / jobb success chance
2. több yield
3. jobb vagy új loot tier

Példa fishing rod:
- Basic Rod → small fish
- Reinforced Rod → medium fish + nagyobb timing window
- Advanced Rod → large/rare fish + rare loot chance

Példa axe:
- Stone Axe → Wood
- Improved Axe → több Wood + Hardwood chance
- Metal Axe → Hardwood + Resin + gyorsabb chopping

## 7. Inventory kapcsolat
Encounter screenen csak a releváns inventory subset jelenjen meg, ne a teljes backpack.

Jaguárnál például:
- Torch
- Spear
- Raw Meat
- Bandage

A játékos azonnal értse, miért érhető el egy kártya.

## 8. Event card rules
Minden eventnek legyen:
- legalább 1 mindig elérhető biztonságos/menekülő opció
- legalább 1 gear-alapú jobb opció
- legalább 1 kockázatosabb magasabb reward opció, ahol értelmes

Így nincs softlock, de a jó preparation jutalmazva van.

## 9. Minigame kapcsolat
A kártya választás indíthat minigame-et.

Példa:
`FISH` → fishing timing minigame
`USE SPEAR` → spear timing minigame
`CHOP TREE` → chopping timing minigame
`SOLVE SYMBOLS` → ruins puzzle

A kártya tehát nem mindig az eredmény, hanem lehet az activity belépési pontja.

## 10. Kártyák újrahasznosítása
Ugyanaz az Action Card art több eventben is használható.

Példa `USE TORCH`:
- Jaguar Encounter
- Cave Entrance
- Strange Noise Outside
- Dark Ruins

Ez jelentősen csökkenti az asset mennyiséget.
