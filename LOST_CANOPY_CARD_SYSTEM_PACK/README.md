# Lost Canopy — Card System Visual Pack

Ez a csomag a Lost Canopy MVP **kártya-alapú UI/gameplay rendszerének vizuális és fejlesztési referenciája**.

## Fő irány
A játék központi interakciója mindenhol ugyanarra a mintára épül:

**Scene / helyszín → helyzet vagy kiválasztott objektum → 3–4 nagy kártya → requirement / cost / risk / reward → outcome**

A rendszer célja, hogy az Explore, eventek, craft, build, forage, fishing és night eventek ne különálló UI-k legyenek, hanem ugyanannak az egységes kártyanyelvnek a változatai.

## Referencia képek
A `references/screens/` mappában találhatók:

1. `01_jaguar_encounter.png` — inventory- és gear-alapú encounter
2. `02_crafting_cards.png` — recipe card / craft rendszer
3. `03_build_upgrade_cards.png` — camp build / upgrade kártyák
4. `04_herb_patch_event.png` — resource gathering event
5. `05_plane_wreck_event.png` — salvage/story event
6. `06_night_event.png` — camp/night encounter
7. `07_fishing_screen.png` — activity/minigame screen
8. `08_blocked_path_event.png` — obstacle/choice event
9. `09_home_camp_ui.png` — fő camp/home UI referencia

## Dokumentáció
- `docs/CARD_SYSTEM_GUIDE.md` — a teljes kártyarendszer szabályai
- `docs/SCREEN_BREAKDOWN.md` — screenenkénti működés
- `docs/IMPLEMENTATION_NOTES.md` — ajánlott adatmodell és technikai felépítés

## Példa data
A `data/examples/` alatt JSON minták vannak eventekhez, craft receptekhez és build kártyákhoz.

## Style lock
- high-angle isometric / top-down
- egyszerű low-poly / flat-shaded formák
- kevés apró részlet
- erős, tiszta silhouette
- mobilon jól olvasható nagy kártyák
- jungle green / earth brown / sand / blue palette
- sötét, lekerekített info panelek
- kártyánként egy nagy ikon vagy mini-illusztráció
- minden döntésnél látszódjon a **requirement + consequence + risk/reward**

Ezt a mappát érdemes a projekt gyökerében `design/card_system_reference/` alá bemásolni, és a UI implementációt ezekhez a képekhez igazítani.
