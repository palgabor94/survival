# Napzáró képernyő – látványterv

[Mobil látványterv](01-day-survived.png), 390 × 844 logikai méretben.

A meglévő pergamentes felületet használja sötétített táborháttérrel. Tartalma: lezárt nap, túlélés visszajelzése, három rövid napi történés, négy záró stat, következő tábori cél és Next day gomb. A képen szereplő események és értékek szemléltető adatok.

Ez egy külön Flutter koncepció, a játék napváltásába még nincs bekötve. A tervezett helye az éjszakai események és az alvás lezárása után, az új nap játékának megkezdése előtt van. A későbbi bekötéshez a napi események összesítését menthető állapotként kell kezelni, hogy folytatáskor se vesszen el és ne jelenjen meg kétszer.

Újrarenderelés: `python3 design/day-end-concept-v1/render.py`.
