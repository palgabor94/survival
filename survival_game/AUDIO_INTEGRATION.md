# Lost Canopy · zene és hangeffektek

2026-10-13. A music mappa három eredeti MP3-ja változtatás nélkül bekerült az assets/music könyvtárba. A lejátszó just_audio 0.10.6; [API és platformdokumentáció](https://pub.dev/packages/just_audio). Bekötés: lib/audio/music_controller.dart, lib/audio/music_scope.dart, lib/main.dart. Assetforrás és hash: assets/music/manifest.json.

## Zeneválasztás

| Helyzet | Jelenlegi fájl |
|---|---|
| Betöltés/főhangulat, térkép, expedíció, explore esemény, romok, horgászat, növénygyűjtés/favágás | main.mp3 |
| Tábor, inventory, műhely, pihenés, éjszakai tábor | camp.mp3 |
| Állatos encounter, aktív vadászat, végső mentési vihar | action.mp3 |
| Megmentés | camp.mp3, amíg saját befejező zene nem érkezik |
| Game over | Zene leáll |

Egy közös lejátszó, ismétlés, váltáskor kb. 0,48 s lehalkítás + új fájl betöltése + 0,48 s felhangosítás. Ez egymás utáni fade, nem két egyidejű zeneszám. Az azonos zenét igénylő akciók nem indítják újra a fájlt. Háttérben/néma állapotban azonnal szünetel, ugyanarra a zenére visszatérve megtartja a lejátszási pozíciót. Minijáték-szünetben halkabb.

**Camp → Menu:** Music kapcsoló és 0–100% hangerő, alapérték 35%. A beállítás külön SharedPreferences kulcsokban mentődik; az új menet nem törli. A lejátszás nem blokkolja a játékot, ha az audioeszköz hibát jelez. Régi menetmentés változatlanul működik. Az új natív pluginhoz teljes újraépítés kell, a hot reload önmagában nem elegendő.

A külön éjszakai, vihar-, megmentési zenék és rövid zenei jelzések még nincsenek a forrásmappában; addig a fenti három zenefájl adja a megfelelő hangulatot.

## Bekötött hangeffektek

A gyökérben lévő **sounds/** mappa mind a hét felvétele felhasználva. Az eredetik változatlanok; a játékhoz öt 44 másodperces, összeúsztatott végű MP3 loop, három 0,65 másodperces favágás és négy 0,36 másodperces lépés készült. Az új assetek összesen **3,65 MiB**-ot foglalnak. A rövid minták monó WAV-ok, eltérő változatokkal; az ambience sztereó. A loopok hangerő-normalizálást, a rövid minták csúcsszint-igazítást és rövid fade-et kapnak.

| Helyzet / művelet | Hang |
|---|---|
| Nappali dzsungel, térkép, erdei minijáték, romok | jungle.mp3 |
| Éjszaka | night.mp3 |
| Riverbank, Fishing Pond, Mangrove Shallows | river.mp3 |
| Light rain, Storm és végső mentési vihar | rain.mp3; enyhe esőben halkabban |
| Látható tábor, nappal és éjjel | campfire.mp3 külön rétegként a környezeti hang mellett |
| Térkép vagy erdei minijáték a táborból | Tűzréteg szünetel |
| Megmentés | Nappali dzsungel, tábori tűz nélkül |
| Game over | Minden környezeti hang és effekt leáll |
| Sikeres utazás, expedíció mélyítése és hazatérés | Három rövid lépés, változó mintákkal |
| Favágás-minijáték jó/tökéletes találata | Egy favágásminta; melléütés, zárolás és ismételt gombnyomás néma |
| Régi baltás eseményválasztás, amely ténylegesen fát ad | Egy favágásminta |

A zene, a két környezeti réteg és a két akciócsatorna párhuzamosan működik. A környezeti váltásnál 0,24 s lehalkítás/felhangosítás történik; háttérbe kerülés és némítás megszakítja a lejátszást és a további lépéseket. Az azonos loopot a tranzakciók nem töltik újra. Minijáték-szünetben a környezet halkabb, az akcióeffektek leállnak. A hangváltozat-választás külön számlálót használ, a játék véletlengenerátorát és jutalmait nem befolyásolja. A mentés nem tartalmaz transient hangokat, ezért betöltéskor nincs effektismétlés.

**Camp → Menu:** külön Sound effects kapcsoló és hangerő, alapérték 60%; a zenétől és menetmentéstől függetlenül tárolva. A környezeti rétegek ennél halkabb saját gainnel szólnak. Új menet nem törli a hangbeállításokat.

Bekötés: lib/audio/sounds_controller.dart, lib/audio/sounds_scope.dart és lib/game/game_sound.dart. Fájlok: assets/sounds/. Visszakövethető források, SHA-256, pontos vágási időpontok és ffprobe-adatok: assets/sounds/manifest.json. Újragyártás: `python3 screenshots/tools/prepare_sound_assets.py`.

UI-kattintás, vadászat, horgászmozdulatok, állatok, puzzle és helikopter saját rövid effektje még hiányzik; az alábbi listából ezek gyűjthetők következőnek.

## Ellenőrzés

**293 repository-teszt sikeres, analyzer tiszta.** Ebből 12 zene-/UI-teszt és 14 hangeffekt-/UI-teszt. Ellenőrzött a helyzetválasztás, fade/gain, egyszeri lejátszás, gyors váltás, némítás folyamatban lévő betöltéskor, háttér/pause, mentett beállítás, autosave együttműködés, hibakezelés, assetegyezés és tényleges menü/térkép kezelés. A zenét és effekteket ugyanabban a tényleges menüben, egymástól függetlenül kapcsolja a UI-teszt. Az audio-backend ezekben fake, nem hangszórós meghallgatás. Az MP3/WAV asseteket ffmpeg készítette és ffprobe ellenőrizte. Logok: /private/tmp/lost-canopy-sounds-full-tests.log és /private/tmp/lost-canopy-sounds-analyze.log; gépi eredmény: .dart_tool/native-test-results.json.

Az iOS szimulátoros buildet a teljes Flutter SDK külső cache-ének írásvédelme állította meg (engine.stamp). Natív készülékes lejátszás, telefonhívás/fülhallgató és a zenék tényleges hangerőegyensúlya még meghallgatandó.

### iOS CocoaPods javítás · 2026-10-13

A `GeneratedPluginRegistrant.m: Module 'audio_session' not found` hiba oka a hiányzó CocoaPods integráció volt: nem volt Pods könyvtár/lockfile, és a workspace csak a Runner projektet tartalmazta. A `pod install --no-repo-update` sikeresen telepítette a Flutter, audio_session, just_audio és shared_preferences_foundation podokat, frissítette a Runner buildfázisait és a workspace-t. A Podfile most explicit iOS 13.0 minimumot tartalmaz.

Xcode-ban **ios/Runner.xcworkspace** nyitandó meg, majd új build indítandó. A generált pluginregistrant nem kapott kézi módosítást. A telepített pod modulemapjából és fejléceiből összeállított ideiglenes frameworkkel az `@import audio_session` és a pluginregisztráció Clang-ellenőrzése sikeres. Ez nem teljes appbuild: az Xcode buildet ebben a környezetben a `Session.modulevalidation` cache írási hibája megállította. Logok: /private/tmp/lost-canopy-pod-install.log, /private/tmp/lost-canopy-audio-module-check.log, /private/tmp/lost-canopy-ios-audio-build.log.

## Pixabay · első kör

Angol keresőkifejezések; egyenként vagy rövid kombinációban érdemes keresni. A cél természetes, földközeli hangvilág, rövid és visszafogott UI-jelzésekkel.

| Hang | Keresőszavak | Javasolt fájlnév |
|---|---|---|
| Nappali dzsungel | jungle ambience, tropical rainforest birds, rainforest loop | ambient_jungle_day |
| Éjszakai dzsungel | jungle night ambience, tropical insects, night crickets loop | ambient_jungle_night |
| Tábortűz | campfire crackling loop, small fire burning | ambient_campfire |
| Folyó/patak | small stream loop, river flowing, water stream ambience | ambient_river |
| Eső | heavy rain forest loop, tropical rain ambience | ambient_rain |
| Mennydörgés | distant thunder, thunder rumble | thunder_distant |
| Növényzet/szél | wind through trees, leaves rustling loop | ambient_wind_leaves |
| Talajon lépések | boots dirt footsteps, gravel footsteps, forest footsteps | footsteps_dirt_01 |
| Favágás | axe chopping wood, wood chop impact, log chopping | wood_chop_01 |
| Suhintás | axe swing whoosh, short weapon swing, spear whoosh | weapon_swing_01 |
| Lándzsa találat | spear impact, arrow flesh impact, soft body impact | spear_hit_01 |
| Gyűjtés | leaves rustling short, bush rustle, grass picking | gather_leaves_01 |
| Tárgyfelvétel | backpack rustle, cloth bag handling, item pickup soft | item_pickup |
| Vízivás | drinking water gulp, water bottle drink | consume_water |
| Evés | eating crunch short, bite apple, chewing short | consume_food |
| Építés/javítás | hammer wood, wood construction, hammer nails | craft_hammer_01 |
| UI-kattintás | soft wood click, wooden tap, subtle ui click | ui_click |
| Zárolt művelet/hiba | low wood knock, muted error click, soft denied | ui_locked |
| Jó időzítés | short bell hit, soft positive chime, woodblock hit | timing_good |
| Tökéletes időzítés | warm chime short, short success chime, small metal bell | timing_perfect |
| Sérülés | male pain grunt short, body impact, short hit grunt | player_hurt_01 |
| Horgász bedobás | fishing cast, small water splash, fishing line cast | fishing_cast |
| Kapás | fishing reel click, water plop, fishing bite | fishing_bite |
| Fárasztás | fishing reel winding, fishing line tension, reel drag | fishing_reel |
| Hal csobbanása | fish splash, water splash small, fish flapping | fishing_splash |

## Pixabay · encounter és mentés

| Hang | Keresőszavak | Javasolt fájlnév |
|---|---|---|
| Jaguár | jaguar growl, big cat snarl, leopard growl | jaguar_growl |
| Vaddisznó | wild boar grunt, boar snort, pig growl | boar_grunt |
| Kígyó | snake hiss, snake hissing short | snake_hiss |
| Darazsak | wasp buzzing, hornet swarm, insect swarm buzzing | hornet_swarm |
| Majom | monkey calls, monkey screech, jungle monkeys | monkey_call |
| Krokodil | crocodile hiss, reptile hiss, crocodile growl | crocodile_hiss |
| Romok kőlapja | stone grinding, stone sliding, stone door movement | ruins_stone_move |
| Puzzle helyes megoldása | deep bell short, low resonant chime, ancient gong soft | ruins_solved |
| Rádió/beacon | radio static short, radio beep, walkie talkie signal | beacon_signal |
| Helikopter érkezése | helicopter approaching, helicopter flyby, distant helicopter | rescue_helicopter |
| Rövid pozitív eredmény | warm success chime, low positive chime, subtle achievement | outcome_success |
| Vereségzárás | low drum hit, dark gong short, low cinematic hit | outcome_failure |

## Gyűjtés formátuma

Rövid effektekből tiszta WAV előnyös; MP3 is használható. UI 0,1–0,5 s, suhintás/találat 0,2–1 s, állathang 1–3 s; ambientből hosszabb, lehetőleg loopolható felvétel. A gyakori ütésből/lépésből/rustle-ből 2–4 változat jó. A környezeti hang maradhat sztereó; a rövid pontszerű effektek lehetnek monók.

További fájlokat a projekt gyökerében a **sounds/** mappába, a fenti nevekkel vagy beszédes angol névvel érdemes gyűjteni. Mindenhez legyen forrás-URL egy SOURCES.md-ben, hogy később visszakereshető maradjon. Következőnek a rövid UI, vadászat és horgászat hangjai a legfontosabbak; utána az állatok, puzzle és megmentés.
