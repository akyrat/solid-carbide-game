# Rebrand sweep

(From the old `game/README.md`; the index is [../../README.md](../../README.md).)

## Rebrand sweep (T-307)

`game/tools/check_rebrand.py` checks that nothing the player can see still carries the old sponsor: its name, its logo or its brand red. It reads every `res://` path in `game/scenes` and `game/scripts` (a `%s` pattern stands for every file it matches, a path with no extension for every PNG starting with it, a folder for every PNG in it) and reports:

- **red** (the brand-red check, T-308): a loaded PNG with an opaque pixel within `BRAND_THRESHOLD` (RGB distance 12) of one of the old sponsor's brand reds (`BRAND_COLOURS` in the script: the old logo red 135, 17, 27 and the reds of the old level-up art, gift pack package and helicopter sheet, each with the archived file it came from). Other reds, such as fire oranges and wood or grip browns, are not flagged: Visual style says red is no longer reserved. The old golds are left out because Greenbull's yellow and fire yellow sit next to them. The subjects whose red the docs keep (`KEPT_RED`: the likes heart, the alert signs, the car's tail lights, the minion's mouth, the health canister, the combo broken popup) are listed apart when they match. `style_rules.reads_as_red` is unchanged and still used elsewhere;
- **name**: a loaded file whose name contains the old sponsor's name in lower case;
- **text**: a quoted string or JSON value containing the old sponsor's name, in any case, in `game/scripts`, `game/scenes` or `game/data` (comments are skipped).

The old name is spelled once, as `style_rules.OLD_BRAND` (T-312, the way `tools/style_loop` spells it since T-299); the banned-word list, these checks, their tests and the build scripts that write it into the art records build it from that constant (`OLD_BRAND.lower()` for file names and the archive folders in `art-archive/T-304/` and `art-archive/T-305/`, `style_rules.OLD_BRAND_DIR`). What they compare, print and write is unchanged.

```
python game/tools/check_rebrand.py [--game-dir game] [--json]
python -m unittest discover -s game/tools -p test_check_rebrand.py
```

It only reports; exit code 1 when there is any finding. On playtest/G-006 the report is clean (0 findings). `game/tools/list_brand_palette.py FILE.png` lists a PNG's commonest colours, for finding more brand colours. Screenshots of every screen: `art-archive/T-307/screenshots/`.

