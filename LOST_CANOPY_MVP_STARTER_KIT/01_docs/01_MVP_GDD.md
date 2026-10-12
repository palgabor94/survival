# Lost Canopy — MVP Game Design Document

## 1. Játék típusa
Mobilos survival / roguelite / decision game rövid skill-alapú minigame-ekkel és látványos base progressionnel.

Nem open world. A világ helyszínekre és eseményekre bontott. A játék fő vizuális központja a folyamatosan fejlődő tábor.

## 2. Játékoscél
A játékos feladata:
1. életben maradni;
2. alap felszereléseket craftolni;
3. fejleszteni a tábort;
4. új területeket megnyitni;
5. megtalálni a vészjeladó alkatrészeit;
6. megépíteni és aktiválni az Emergency Beacon-t;
7. túlélni az utolsó napot a mentésig.

Egy teljes sikeres MVP run célideje: kb. **30–60 perc**.

## 3. Fő statok
- **Health** — 0-nál game over.
- **Water** — akciókkal és idővel csökken; 0-nál gyors health loss.
- **Food** — idővel csökken; 0-nál health loss és gyengébb teljesítmény.
- **Sanity** — veszélyes eventek, éjszakák, sérülés csökkentheti; alacsonyan rosszabb event modifier.

### Status effectek
- Poisoned
- Injured
- Wet
- Exhausted

MVP-ben ezek külön státuszok, nem külön teljes stat barok.

## 4. Napstruktúra
Egy nap kb. **5–6 akciópontnyi időből** áll.

Példák:
- Forage: 1–2 időegység
- Fishing: 2
- Explore: 2–3
- Craft: 1
- Build: 1–2
- Rest: 1–2

Nap végén Night Phase → random night event → Sleep → következő nap.

## 5. Camp progression
### Camp Tier 0 — Crash Shelter
- leaf lean-to
- bedroll
- campfire
- 1 crate
- lantern

### Camp Tier 1 — Basic Refuge
- stabilabb shelter
- storage
- egyszerű workbench
- improved bed

### Camp Tier 2 — Established Camp
- részleges fa platform
- water collector/barrel
- drying rack
- cooking station
- több storage

### Camp Tier 3 — Rescue Base
- nagyobb refuge
- advanced workbench
- radio/beacon corner
- proper bed
- improved cooking/water system

A fejlesztések **vizuálisan megjelennek** a base screenen.

## 6. Helyszínek
### Camp
Hub, craft, build, rest, inventory, napi felkészülés.

### Riverbank
Water, wood, fiber, basic fish, herbs.

### Fishing Pond
Jobb halak, ritka fogások, fishing minigame.

### Plane Wreck
Metal scrap, wire, battery, radio parts, story logok.

### Ancient Ruins
Puzzle, ritka materialok, final beacon component.

### Átmeneti event helyszínek
- Broken Bridge
- Jungle Trail
- Cave Entrance
- Fallen Tree

## 7. Progression gate-ek
A jobb eszköz nem csak könnyebbé teszi a minigame-et, hanem:
1. több lootot ad;
2. jobb loot tier-t nyit;
3. bizonyos resource-okat csak megfelelő tool-lal lehet megszerezni.

Példák:
- Basic Axe → Wood
- Improved Axe → több Wood + Hardwood chance
- Metal Axe → Hardwood + Resin

- Basic Rod → Small Fish
- Reinforced Rod → Medium Fish + rare chance
- Advanced Rod → Large Fish + Rare Catch

- Bare Hands → Berry / Fiber
- Knife → Herbs / Roots
- Machete → Rare Plants + Dense Jungle access

## 8. Push-your-luck exploration
Expedíció közben loot után a játékos választ:
- **RETURN TO CAMP** — biztosan hazaviszi a lootot.
- **GO DEEPER** — jobb loot, magasabb danger.

Danger több lépcsőben nő. Magas danger mellett nagyobb az esély:
- injury
- snake
- jaguar
- weather event
- item loss

## 9. Győzelem
Szükséges final komponensek:
- Battery
- Wire
- Metal Parts
- Radio Module
- Power Cell / Beacon Core

Az utolsó ritka komponens az Ancient Ruins progression végén szerezhető meg.

A játékos craftolja az **Emergency Beacon**-t → aktiválja → jön a **Survive Until Rescue** final nap → siker esetén **RESCUED** ending.

## 10. Vereség
Health 0 → run vége.
Lehetséges okok: dehydration, starvation, poison, injury, animal attack.

Run végén Survival XP jár meta progressionre.
