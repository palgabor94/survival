# Lost Canopy — izometrikus expedíció és encounter

**Aktuális esemény-UI: [rövid, fix magasságú kártyák és utólagos eredmény-popup](../event-choices-v3/index.html).**

**2026-10-12 · 6 tényleges Flutter-képernyőkép**

[Galéria](index.html) · [Teljes frissített játékgaléria](../unified-ui-v1/index.html)

Új felülnézeti, izometrikus hátterek. Az encounter négy kártyája egyetlen vízszintesen görgethető sorba került, 390 px szélességnél három egyidejű kártyával, nyilakkal és lapozásjelzővel. A hosszú helyzetleírás információgombbal megnyitható; a kártyákon a v3 szabály szerint csak akció és feltétel látszik; az eredmény a választás utáni popupban jelenik meg.

1. [Expedíció — izometrikus nézet](01-expedition.png) — Új felülnézeti folyópart, tömörebb helyzetpanel.
2. [Encounter — egyetlen kártyasor](02-encounter.png) — Három kártya látszik egyszerre, a negyedik lapozható.
3. [Encounter — következő kártya](03-encounter-next.png) — Fix magasságú akciókártyák, csak névvel és feltétellel.
4. [Encounter — szélesebb kijelző](04-encounter-wide.png) — 520 px széles nézetben mind a négy kártya egyszerre látszik.
5. [Encounter — helyzetleírás](05-encounter-details.png) — Az információgombbal megnyitható teljes leírás.
6. [Encounter — visszalapozás húzással](06-encounter-swipe-back.png) — A kártyasor ujjmozdulattal is böngészhető.

Az exportáló a jobbra lapozást, a helyzetleírás megnyitását/bezárását és a húzással történő visszalapozást is végrehajtja. Ez screenshot-export, a teljes tesztkör továbbra is hátravan. Újragenerálás: `LOST_CANOPY_CAPTURE_SCENES=1 python3 screenshots/tools/capture_unified_ui.py`.

Hátterek: [riverbank_isometric.png](../../assets/art/riverbank_isometric.png), [jaguar_encounter_isometric.png](../../assets/art/jaguar_encounter_isometric.png). A beépített image_gen eszközzel készültek; [pontos promptok és referenciák](../../assets/art/ISOMETRIC_SCENE_PROMPTS.md).
