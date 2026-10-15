# Balta- és lándzsaprogresszió — bekötés

2026-10-15 · Az elfogadott [mechanikai terv](PLAN_HU.md) és pergamentes koncepciók alapján. [Tényleges screenshotok](../../screenshots/tool-progression-v1/README.md).

## Elkészült

- Stone / Reinforced / Salvage Axe: 10 / 16 / 24 állapot, GOOD ×1 / ×1,10 / ×1,20. A sikeres favágás próbánként +0 / +1 / +2 Woodot kap; nulla találatnál nincs bónusz. Salvage baltával legalább két PERFECT további 1 Hardwoodot ad. Maximális ügyes hozam így 9+2, 10+2, illetve 11+3 Wood+Hardwood.
- Stone / Hunting / Salvage Spear: ugyanennyi állapot és GOOD-szorzó, a kockázatos fizikai lándzsás döntéseken +0 / +8 / +15 százalékpont. A jelenlegi fegyveres jaguárakció egészséges esélye 70 / 78 / 85%; a krokodilé 65 / 73 / 80%. A lándzsás esély plafonja 90%, a biztos ág biztos marad. A vadászat PERFECT zónája és húsalaphozama változatlan.
- A meglévő Injured ×0,9 és Exhausted ×0,85 időzítési hátrány, illetve fizikai és sanity-levonások megmaradtak. Ez pontosítja a tervezési dokumentum Exhausted ×0,9-es példaszámát: a meglévő motor értéke nem változott.
- A vaddisznó új **Keep it at bay** döntése lándzsával választható; nincs húsjutalom. Sikertelenül fizikai sérülés, sanity-vesztés és csomagvesztés, befejezett expedíció következik. A régi választások megmaradtak. Az eseménykatalógus most legfeljebb 5 kártyát enged; a felület ugyanabban az egy sorban lapozza őket.
- Négy új recept, az elfogadott előfeltételekkel és költségekkel. A fejlesztés megtartja az előző tárgyat, törött előfeltétel is elfogadott; az új tárgy teljes állapotú és felszerelt. Camp Tier 1 / 2 szükséges.
- Javítás: külön, kisebb anyagköltség + 1 idő. A pontos költség a tool-catalogban található, ugyanabból olvas a motor és a megerősítő ablak. Nem költi el újra a gyártás teljes anyagát.
- Mentett balta-/lándzsaválasztás. Régi mentésben az alap eszköz az alapértelmezés; hiány vagy törés esetén a legjobb használható változat válik elérhetővé. A minijáték előnézete jelzi a fallbacket. A régi `stone_axe/stone_spear` eseményfeltételeket bármely használható családtag teljesíti.
- A minijáték indulásakor a konkrét eszköz és a GOOD-szorzó rögzül a mentésben; aktív próbánál nem cserélhető. Kopás egyszer, eredménykor: `1 + MISS-ek`. Egy állapotú eszközzel a megkezdett próbát be lehet fejezni. A közvetlen események mindig a ténylegesen használt tárgyon számolnak el 1 kopást.

## Felület és art

A craft menü ALL / AXES / SPEARS szűrőt kapott a meglévő Craft / Camp váltás mellett. A kártyák mérete és a 3:2 képablak egységes. Koppintásra nyílik a tárgy nagy képe, az előnyök, a feltételek, a pontos költség és a megerősítés. Items / Gear alatt Equip és külön megerősített Repair érhető el. A minijáték előtt három eszköz közül lehet választani.

Az encounter a felszerelt tárgyat mutatja, a részletekben annak állapotát, előnyét, a teljes számított esélyt és a fennálló hátrányokat. Nem mutat előre jutalomértékeket. A stat-eredmény minden akciónál kiemelt változást, kisebb aktuális értéket és progress bart mutat. A hátralévő idő külön óraikonnal jelenik meg.

A saját hátteres új atlasz `assets/art/tools_atlas_v1.png`, a kis ikonok külön, valódi alfa hátterű `tool_icons_atlas_v1.png` atlaszt használnak. Mindkettő 1536×1024; a kártyaképek 3×3, az ikonok 3×2 cellásak. A régi külön tárgyikonok és kártyaképek megmaradtak. A generálási promptok a PROMPTS.md fájlban szerepelnek.

## Ellenőrzés

14 új motorteszt és 5 új UI-teszt. Teljes natív Flutter tesztfutás: **398 sikeres, 0 hibás, 0 kihagyott**. Lefedi a régi mentést, az új eszközök feltételeit, egyszeri jutalmat/kopást, törést és tartalékra váltást, közbeni mentést, javításköltséget, állapotlevonást, fegyveres eseményeket; a UI oldalon az egyforma kártyákat, felszerelésválasztást, javítást és eredményt 320 px-en, fekvő nézetben és kétszeres betűmérettel. A végső kis felületi tömörítés után a 19 célzott teszt ismét futott.

Az aktuális eszközök szerepe és költsége implementálva; az emberi nehézség és a teljes gazdaság újramérése még a későbbi balanszmérföldkő része. A meglévő friss játékból végigvezetett mentési regressziók sikeresek. Fizikai készülékes próbát ez a futás nem jelent.

Következő mérföldkő: hordott készlet és tábori tárolás. A vezetett első nap továbbra is az MVP utolsó fejlesztési lépése.
