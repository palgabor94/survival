# Megmentés mérföldkő — látványterv és megvalósítási szerződés

2026-10-12. A meglévő egységes HUD, 3:2 kártyaképek, egyetlen világos keret, legfeljebb 160 px álló kártyák és közös sormagasság a kiindulás.

[Generált képernyőterv](ui-concept-v1.png): romok érkezése, puzzle, eredmény-popup, beacon-előkészítés, végső vihar és megmentés. A terv illusztratív szövege helyett a tényleges alkalmazás natív szöveget és gombokat használ.

## Képernyők

| Képernyő | Elrendezés / interakció |
|---|---|
| Ancient Ruins / Plane Wreck | Magas izometrikus jelenet, közös kompakt felső HUD és helyzetpanel, egyetlen lapozható kártyasor alul. Nincs előre kiírt jutalom vagy kockázati százalék. |
| Stone Seal puzzle | A romjelenet marad a háttér. Rövid felső mintasor, három azonos méretű forgatható kőlap, név és forgatásjelzés; alsó Align/Leave kártyák. A forgatás nem fogyaszt időt, a beadás 1 nappali idő. Mind a célminta, mind a kőlapok szemantikusan felolvashatók. |
| Beacon előkészítés | Tábori háttér, kompakt alkatrészlista mennyiséggel, forráshely megnevezésével és kész/hiányzik jelzéssel. Assemble/Activate és Back kártyák; a szükséges műhely/térkép külön elérhető. Aktiválás előtt a játék jelzi a másnapi végső vihart. |
| Eredmény-popupok | A meglévő OutcomeDialog, tényleges stat/készletváltozásokkal. Sikertelen és halálos döntés után is megjelenik. |
| Végső vihar | Saját sötétebb, esős izometrikus tábor és látható jeladó. Három egymást követő helyzet, helyzetenként egy lapozható kártyasor. Csak a döntés és követelménye látszik előre. |
| RESCUED | Saját izometrikus megmentésjelenet, rövid felső fejléc, kompakt alsó menetösszesítő és korlátozott méretű New Run kártya. A sikeres végállapot mentve marad; új menet csak megerősítés után indul. |

## Játékfolyam

Plane Wreck → Battery/Wire/Metal Parts/Radio Module → Machete + Tier 2 → Ancient Ruins puzzle → Beacon Core → Tier 3 → Emergency Beacon építés → jeladás → éjszaka → három végső viharesemény → RESCUED.

Az alkatrész-események prioritásosak, amíg hiányzik az adott komponens. Elvesztett zsákmány újra megszerezhető. A puzzle elhagyható és újrapróbálható. A régi v1 mentések kiegészítő mezőkkel folytathatók; puzzle-minta és lapállás, jeladás, viharhelyzet és sikeres végállapot külön mentődik.

Az új képek a jóváhagyott jaguáros referencia egyszerű, facettált art style-ját és magas izometrikus kameráját követik. A képi felső/alsó negyed környezet marad a natív UI számára.


A kis komponens-, inventory- és eredményikonok külön átlátszó PNG-ket használnak. A nagy kártyaillusztráció saját hátterét megtartja. [Itemikon-promptok](../../assets/art/ITEM_ICON_PROMPTS_V1.md).
