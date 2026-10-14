# Lost Canopy — camp-style encounterek

[Hat képes galéria](index.html): öt új generált kép és a korábban jóváhagyott jaguár.

Az első öt imagegen-hívás a tábori stílusreferenciát és az állandó karakterlapot kapta. A vaddisznó v3 kamerareferenciája az új jaguáros v3 kép; a vaddisznó v2 csak az állatot és környezetet rögzíti, a karakterlap továbbra is csatolva van. Álló, átlátszatlan 9:16 PNG-k, külön változatok; az eredeti fájlok megmaradtak; 2026-10-13-án az új változatokat bekötöttük a játékba.

| Encounter | Saját környezet | Kép |
|---|---|---|
| Kígyó | Páfrányos sziklaszoros | [snake_encounter_camp_style_v1.png](snake_encounter_camp_style_v1.png) |
| Vaddisznó | Napsütötte, agyagos bozóttisztás | [boar_encounter_camp_style_v3.png](boar_encounter_camp_style_v3.png) |
| Krokodil | Sekély mangroveág, homokos parttal | [crocodile_encounter_camp_style_v1.png](crocodile_encounter_camp_style_v1.png) |
| Darazsak | Bambuszliget, alacsony fészkes ággal | [hornet_encounter_camp_style_v1.png](hornet_encounter_camp_style_v1.png) |
| Majmok | Gyümölcsös liget, kidőlt fával | [monkey_encounter_camp_style_v1.png](monkey_encounter_camp_style_v1.png) |

[Pontos promptok](PROMPTS.md) · [Referencia, forrás, méret, SHA-256](manifest.json) · [Állandó karakter és stílus](../ART_DIRECTION.md).

Az öt kimenetet vizuálisan átnéztük: egységes karakter és egyszerű facettás stílus, különböző vízparti/bambuszos/sziklás/bozótos/gyümölcsös környezet; felismerhető állatok, a darazsak keskeny derékkal és csíkos potrohhal. A PNG-fejlécek egyező méretarányt igazolnak. Ezek képanyagok, még nem gameplay screenshotok; kód és játékmenet nem változott, ezért ebben a körben nem futott új tesztkör.


## Vaddisznó v2 — kamerajavítás

A felhasználói visszajelzés szerint a v1 kamera túl alacsony volt. A [v2 kép](boar_encounter_camp_style_v2.png) magas, felülről néző izometrikus szöget használ: a talaj tölti ki a képet, a fejek és a disznó háta erősebben látszik felülről. A bozótos környezet és a tábori stílus megmaradt. A karakterlap itt is csatolva volt. [Pontos javítási prompt](BOAR_CAMERA_V2_PROMPT.md). A v1 külön korábbi változatként megmaradt; a v2 korábbi változatként megmaradt.

## Vaddisznó v3 — egyező jaguárkamera

A v2 kameráját a felhasználó túl magasnak találta. A [v3 kép](boar_encounter_camp_style_v3.png) közvetlen kameraszög-referenciája a jóváhagyott jaguáros v3. Megmaradt az agyagos bozótos környezet és az állandó karakter. [Pontos prompt](BOAR_CAMERA_V3_PROMPT.md). A galéria most a v3-at mutatja. A felhasználó 2026-10-13-án folytatást kért; mind a hat encounter és a hét további helyszín bekötve. [Teljes galéria](../world-camp-style-v1/index.html).

## Bekötés, 2026-10-13

A vaddisznó kiválasztott változata v3; a többiek a jóváhagyott v1, a jaguár a jóváhagyott v3 forrásából került a production assetek közé. Az új verziókat a játék adatfájljai és UI-ja használja. [Bekötési jegyzék](../../assets/art/camp_style_refresh_manifest_v1.json).
