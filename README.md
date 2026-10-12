# Lost Canopy

Flutter survival játék, MVP starter kit, közös kártyarendszer és projektben tárolt látványtervek.

- [Flutter alkalmazás és indítás](survival_game/README.md)
- [MVP-audit: mi készült el, mi hiányzik](survival_game/MVP_AUDIT_2026_10_12.md)
- [Állapot és menetrend](survival_game/PROJECT_STATUS_AND_ROADMAP.md)
- [Friss expedíciós mobilképek](survival_game/screenshots/expansion-v1/index.html)
- [30 alkalmazásképernyő](survival_game/screenshots/unified-ui-v1/index.html)
- [Kártyamagasság-javítás és 185 sikeres teszt](survival_game/design/unified-card-ui/CARD_HEIGHT_VALIDATION_2026_10_12.md)
- [MVP starter kit](LOST_CANOPY_MVP_STARTER_KIT/README_FIRST.md)
- [Kártyarendszer kit](LOST_CANOPY_CARD_SYSTEM_PACK/README.md)

Az alkalmazás a `survival_game` mappában futtatható meglévő Flutter SDK-val. A projekt gyökere a két kitet, grafikát, dokumentációt, natív teszteket és screenshotexportot is tartalmazza.

## Helyi Git-kapcsolat

Remote: `https://github.com/palgabor94/survival.git`. Előkészített ág: `codex/mvp-state-2026-10-12`.

Ebben a környezetben a gyökér `.git` útvonala írásvédett. A helyi commitok metadata-könyvtára `.git-state`; a `./git-workspace.sh status` és a többi Git-parancs ezen dolgozik.

A normál terminálban `./connect-git.sh` kapcsolja be a szokásos Git-felismerést és pusholja az előkészített ágat. A script a meglévő metadata-ra mutató `.git` linket hozza létre; meglévő `.git` esetén azt használja. A távoli repó korábbi állapotának felülírásához nem használ force push-t.

A hálózati kapcsolat a fejlesztői környezetből DNS-hibával elakadt (`Could not resolve host: github.com`); a helyi commit és a GitHubra történő feltöltés külön állapot. A GitHubra klónozott repó szokásos `.git` könyvtárat kap, a helyi segédscriptek ott nem szükségesek.
