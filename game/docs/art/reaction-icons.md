# Reaction icons

Tasks T-352 (the six good ones) and T-357 (the six bad ones; HUD and menus, Decisions, "The HUD looks like a livestream" and "Bad reactions when the combo breaks"). Twelve 16 x 16 icons in `game/art/hud/reaction_<name>.png`, each with a `.json` record, all hand-placed pixel grids in `game/tools/build_hud_reaction_icons.py` (`NAMES` good, `BAD_NAMES` bad), 0 PixelLab generations, byte-identical every run. A 1 pixel dark HUD outline is drawn round each shape; opaque or empty pixels only; no Greenbull colours.

- Rebuild: `python game/tools/build_hud_reaction_icons.py build --out-dir game/art/hud --force`.
- Enlarged contact sheet on dark and light: `python game/tools/build_hud_reaction_icons.py contact --out SHEET.png`.
- The game loads them in `scripts/hud/reactions.gd` (`ICONS`, `BAD_ICONS`); see `hud-and-menus/hud.md`.
- T-357's contact sheets and the burst screenshot after a crash: `art-archive/T-357/screenshots/` (`v1.png` to `v3.png`, `bad_burst.png`); `before.png` is T-356's placeholders.
- Tests: `game/tools/test_build_hud_reaction_icons.py`.
