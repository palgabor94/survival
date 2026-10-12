# Kártyamagasság — javítás és ellenőrzés

2026-10-12.

Az expedíción a Return to Camp kártya rövidebb volt a Go Deeper kártyánál, és középre igazítva más magasságban kezdődött. Az ActionCard külső Align-ja fellazította a CardDeck egyenlő magasságú sorának szoros függőleges korlátját.

A közös sor most jelzi a kártyának, hogy a már méretezett slotot töltse ki. Ez a CardDeck és CardCarousel sorokra is érvényes. Minden sor természetes magasságát a legmagasabb kártya adja; a képek 3:2 aránya és a legfeljebb 160 logikai pixeles szélesség megmarad. Az önálló kártyák továbbra is a saját tartalmuk szerint méreteződnek; a sorok között nem vezetünk be minden képernyőre egyetlen, önkényes magasságot.

## Bizonyíték

- 6 új regresszió: deck és carousel, 375×667 telefon, 844×390 fekvő nézet, 768×1024 tablet 1,3× szöveggel. Rövid/hosszú/zárolt felületek egyenlő mérete, felső és alsó él, képarány és a természetes legnagyobb magasság ellenőrizve. A javítás előtt mind a 6 elbukott; utána mind sikeres.
- A tényleges expedíciós folyamat meglévő widgettesztjében azonos kártyaméret és felső/alsó él ellenőrzése.
- Teljes natív tesztkör: **185 sikeres, 0 hiba, 0 kihagyás**. [Teljes log](card-height-tests-2026-10-12.log) · [JSON](card-height-results-2026-10-12.json).
- Analyzer: **No issues found**. [Log](card-height-analyze-2026-10-12.log).
- [Friss Bamboo Grove expedíciós képernyő](../../screenshots/expansion-v1/02-bamboo-expedition.png).

A natív tesztindítás és a screenshotexport ugyanazokat az alkalmazás-widgeteket futtatja; a normál Flutter tesztindító localhost-socketje a környezetben tiltott. Készülékes build ebben a javításban nem történt.
