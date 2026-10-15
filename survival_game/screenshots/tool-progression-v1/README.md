# Eszközprogresszió — működő játék

2026-10-15 · Tényleges Flutter UI-k 390×844 logikai méreten, 2× PNG-ben. Előkészített készlettel és mentésből megnyitott eseményekkel; a javítás és favágás valódi motorakciót hajt végre. Ezek nem a korábbi koncepcióképek.

1. [Craft — balták](01-workshop-axes.png)
2. [Balta gyártásának részletei](02-axe-details.png)
3. [Craft — lándzsák](03-workshop-spears.png)
4. [Items — felszerelés](04-items-gear.png)
5. [Javítás megerősítése](05-repair-confirmation.png)
6. [Javítás valódi eredménye](06-repaired-outcome.png)
7. [Favágás felszerelése és költsége](07-chopping-loadout.png)
8. [Három balta közötti választás](08-axe-selection.png)
9. [Favágás valódi eredménye és az új statmegjelenítés](09-chopping-outcome.png)
10. [Jaguár — a felszerelt lándzsa akciója](10-jaguar-choices.png)
11. [Lándzsás döntés: eszköz, esély, sérülés hátránya](11-spear-decision.png)
12. [Új vaddisznóválasztás, lapozható sorban](12-boar-spear-choice.png)

[Mechanika, mentés és validáció](../../design/tool-progression-v1/IMPLEMENTATION_HU.md).

Újrarögzítés az app könyvtárából:

```sh
LOST_CANOPY_CAPTURE_TOOLS=1 LOST_CANOPY_CAPTURE_OUTPUT=screenshots/tool-progression-v1 python3 screenshots/tools/capture_unified_ui.py
```
