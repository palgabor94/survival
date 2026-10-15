# Horgászati progresszió — valódi mobilképernyők

2026-10-15 · 390×844-es Flutter-nézet, 2× exportfelbontás. Az alkalmazás tényleges komponensei; előkészített felszereléssel és determinisztikus motorfutásokkal. A fogások a valódi csali-/halfaj-sorsolásból és sikeresen végigvezérelt fárasztásból származnak.

1. [Csali- és botválasztás](01-loadout.png)
2. [Rovarcsali részletei](02-insect-bait-details.png)
3. [Három külön bot](03-rod-selection.png)
4. [Fárasztás](04-reeling.png)
5. [Pataki ezüsthal](05-stream-silverfish.png)
6. [Ritka hal első felfedezése](06-first-rare-catch.png)
7. [Veszélyes hal fogása](07-dangerous-catch.png)
8. [Nyers hal részletlapja](08-fish-item-details.png)
9. [Biztonságos előkészítés megerősítése](09-prepare-confirmation.png)
10. [Elkészített étel eredménye](10-prepared-outcome.png)
11. [Előkészítetlen hal: külön megerősítés](11-unsafe-confirmation.png)
12. [Mérgezés tényleges eredménye](12-poison-outcome.png)
13. [Halfajok a Journalban](13-fish-journal.png)
14. [Mentett, szüneteltetett dobás](14-paused-cast.png)
15. [Új bot- és csalireceptek](15-new-gear-recipes.png)

A fogási ablak X gombja elteszi az ablakot, nem engedi el és nem adja hozzá a halat. A fogás mentve marad, amíg a játékos dönt. A fajnév, hossz, súly és méretkategória az eredményen jelenik meg. A kártyák alapmérete egységesen 112×172, képarányuk 3:2; a kis ikonok átlátszó hátterűek.

Újraexportálás:

```sh
LOST_CANOPY_CAPTURE_FISHING_PROGRESSION=1 LOST_CANOPY_CAPTURE_OUTPUT=screenshots/fishing-progression-v1 python3 screenshots/tools/capture_unified_ui.py
```
