# Bekötött napzáró – 2026-10-15

- [Napzáró, 390 × 844](01-day-3-survived-390x844.png)
- [Next day után, a 4. napi tábor](02-next-day-4-camp.png)
- [Mentésből visszatöltött összesítő, 320 × 568](03-restored-day-end-320x568.png)
- [Kis kijelzőn legörgetve](04-restored-day-end-scrolled-320x568.png)

Ezek a valódi alkalmazásból készültek: seedelt 3. napi kezdés → balta készítése → Riverbank → hazatérés → pihenés → éjszakai esemény → alvás. A számok a játékmotor tényleges eredményei.

Az összesítő az alvás utáni riport része, a napi eseménycímekkel együtt mentve. A napváltás és az alvás költségei egyetlen tranzakcióban történnek; a Next day a függő riportot nyugtázza, nem futtatja újra az alvást. Lezárásig más akció nem indítható. Halálos éjszaka esetén a vereségi folyamat marad érvényben. A vihar kezdete az összesítő nyugtázása után következik.

A napi listában az elkészített tárgyak, táborfejlesztések és meglátogatott helyek élveznek elsőbbséget, legfeljebb három bejegyzéssel. A nap végi statokat és a teljes pozitív anyagkészletet mutatja; Wood, Stone és Fiber nulla mennyiségnél is látható. Nagy szövegnél a statok két oszlopra váltanak, a hosszú tartalom görgethető.

Export: `LOST_CANOPY_CAPTURE_DAY_END=1 LOST_CANOPY_CAPTURE_OUTPUT=screenshots/day-end-v1 python3 screenshots/tools/capture_unified_ui.py`.

Validáció: 331/331 natív Flutter-teszt sikeres, a Dart analyzer tiszta. A lefedett napzáró esetek: napközbeni mentés, függő összesítő visszaállítása, egyszeri továbblépés, régi mentés, halálos alvás, 320/375/390 px, fekvő nézet és 2× szöveg. A négy statdoboz azonos méretét is ellenőrizzük.
