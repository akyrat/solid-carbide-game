---
id: G-002
title: Add an image of the weapon on each level-up card, and add three new...
status: building
art_cap: 40
art_used: 0
iteration: 1
max_iterations: 20
created: 2026-10-18
lead: Goal-G-002
---

## Goal

Add an image of the weapon on each level-up card, and add three new weapons: the neon underglow, molotovs and the windshield wiper, each with 8 tiers, with the level-up offering two random choices from all available, as written in docs/weapons.md (Decisions, 2026-10-18) and docs/hud-and-menus.md (Decisions, 2026-10-18). Include their PixelLab art.

## Goal acceptance criteria

- [ ] `game/data/weapons.json` holds five weapons: the starting gun, the exhaust flamethrower, the neon underglow, the molotovs and the windshield wiper. Each of the three new ones has base values and exactly 7 upgrade tiers (tiers 2 to 8), read through `game/scripts/data/weapon_data.gd`, and a data test checks this. (QA: pass / fail)
- [ ] In a headless run with each new weapon given at tier 1: the neon underglow damages a minion inside its circle as soon as the minion enters, then again every second while it stays inside. A molotov thrown from the car leaves a circular fire area that damages a minion standing in it. The windshield wiper sweeps a semicircle in front of the car and damages a minion it hits and pushes it away from the car. The gun and the flamethrower still never push. An automated test covers each of these. (QA: pass / fail)
- [ ] Each new weapon's tiers 2 to 8 can be applied from code. Each tier changes the weapon the way `weapons.json` says, and a test checks every tier. (QA: pass / fail)
- [ ] Level-up offers: the first level-up of a normal run offers exactly 'upgrade the gun' and 'get the flamethrower'. Every later level-up offers two different choices drawn at random from every available choice (get a weapon the car doesn't have, or the next tier of one it has). A weapon at tier 8 is never offered. With one choice left, one card shows. With none left, the choice is skipped. Seeded tests cover all of these cases. (QA: pass / fail)
- [ ] Every possible level-up card (get and each upgrade tier of all five weapons) shows approved text from the Narrative Theme Agent in `game/scripts/ui/level_up_texts.gd`, with no placeholder or missing key. A test walks every choice id and tier. (QA: pass / fail)
- [ ] Every level-up card shows an image of its weapon. A screenshot fixture of the level-up screen shows two cards, each with its weapon image, inside the red and gold card frame. (QA: pass / fail)
- [ ] The PixelLab art is in `game/art/` with its records, and every other generation is in `art-archive/<task>/`. That covers one card image per weapon (all five) plus the in-world art for the underglow, the molotov and its fire area, and the wiper. The art replaces the placeholders in the game, and `art_used` in the goal file is at or under the goal's art cap of 40. (QA: pass / fail)
- [ ] The run scene opens and plays headless from the main menu with all five weapons owned at once (through a dev or playtest switch) for at least 60 seconds with no script errors. (QA: pass / fail)
- [ ] The game's tests, the tools tests and the docs checks all pass on `playtest/G-002`. `docs/weapons.md` (Content), `docs/hud-and-menus.md` (Level-up screen), `docs/visual-style.md` (if art decisions were recorded) and `game/README.md` describe what was built, and the staleness check reports nothing stale after the long GDD and the short GDD fingerprint are regenerated. (QA: pass / fail)

## Open questions

Answered by the board (2026-10-18, in `docs/weapons.md`, Decisions): burning only while inside the fire area; the wiper is always on and pushes only minions (the kaiju is damaged, not pushed); the garage damage bonus applies to every weapon; the gun's card shows a small pixel-art gun. The rest are left to the agents as proposals for the playtest.

- Does a burning enemy keep burning after it leaves a molotov's fire area, and for how long? (Weapons, Open questions, 2026-10-18)
- Is the kaiju knocked back by the windshield wiper, or only minions? Today the kaiju's body overlap rule exists for the flamethrower, but nothing is said about pushing it.
- What image does the starting gun's card show? The gun has no visible weapon on the car, only its bullets (Weapons, Decisions).
- Does the garage damage bonus also multiply the three new weapons' damage? Weapons, Content says it applies to the gun and the flamethrower only.
- Are the new weapons' in-world effects all PixelLab art, or are some drawn by script like the drift smoke and level-up particles? The goal says 'their PixelLab art' but doesn't list which pieces.
- Is the card image style in the level-up screen's red and gold Redgull theme, or in the city's neon palette like the in-world weapons?
- Molotovs 'thrown at random': random landing spot around the car, random timing, or both? How far from the car can they land?
- Is the windshield wiper always sweeping, or only in some driving state (like the flamethrower only while drifting)? Does it hit enemies through buildings?
- Does the neon underglow's damage-on-entry repeat if an enemy leaves and re-enters within the same second (could stack with the per-second tick)?
- Does a dev or playtest switch give each new weapon at the start, like `flamethrower_at_start`? This would be useful for the board's playtest, but the docs don't ask for one.

## Sub-goals

| rank | id | title | score | why | verdict | tickets |
|---|---|---|---|---|---|---|
| 1 | S1 | Weapon data for the three new weapons (Game Data Agent) | unblocks 9, value 5 | Every new weapon and its 8 tiers read their numbers from weapons.json. The docs say the agents propose the numbers and what each tier changes, and the board judges them in the playtest. The text task and the behaviour tasks need these first. | covered | T-166 |
| 2 | S3 | Enemy knockback hook (Enemy Behavior Agent) | unblocks 6, value 4 | The windshield wiper knocks enemies back, and enemies have no way to be pushed by a weapon today (minion and kaiju only have take_damage and walk). The wiper task needs a knockback call on enemies. | in-flight | T-167 |
| 3 | S4 | Neon underglow behaviour with placeholder look (Weapon Behavior Agent) | unblocks 5, value 5 | The first of the three new weapons: a circle around the car that damages enemies on entry and every second. | in-flight | T-168 |
| 4 | S5 | Molotovs behaviour with placeholder look (Weapon Behavior Agent) | unblocks 5, value 5 | The second new weapon: molotovs thrown from the car at random, each leaving a circular fire area that burns enemies. | in-flight | T-169 |
| 5 | S6 | Windshield wiper behaviour with placeholder look (Weapon Behavior Agent) | unblocks 5, value 5 | The third new weapon: one wiper in front of the car sweeping a semicircle, damaging and knocking back the enemies it hits. It is the only weapon that pushes. | in-flight | T-170 |
| 6 | S2 | Level-up card text for the three new weapons (Narrative Theme Agent) | unblocks 3, value 5 | Every card shows a title and a description, and text never uses placeholders. The cards for 'get' and tiers 2 to 8 of each new weapon need approved text before the screen task can show them. | in-flight | T-171 |
| 7 | S7 | Level-up offers: two random choices from all five weapons (Weapon Behavior Agent) | unblocks 3, value 5 | The docs replace the fixed two-weapon offer with two different choices at random from every available choice. The first level-up still offers the flamethrower or a gun upgrade. | in-flight | T-172 |
| 8 | S8 | Level-up screen: new card text and a weapon image on every card, placeholder images first (UI Agent) | unblocks 2, value 5 | The HUD and menus decision puts an image of the weapon on each card, and the screen must show the new choices with their approved text. Placeholder images come first, so the screen doesn't wait for the art. | in-flight | T-173 |
| 9 | S9 | PixelLab art: one card image per weapon, all five (Asset Generation Agent) | unblocks 1, value 4 | The goal asks for the PixelLab art, and every card, including the gun's and the flamethrower's, shows its weapon's image. | in-flight | T-174 |
| 10 | S10 | PixelLab art: in-world art for the underglow, molotovs and fire area, and the wiper (Asset Generation Agent) | unblocks 1, value 4 | The goal asks for the new weapons' PixelLab art. The behaviour tasks start with placeholders, and this task swaps the final art in. | in-flight | T-175 |
| 11 | S11 | Integration check of the goal (QA/Integration Agent) | unblocks 0, value 4 | The goal is only done when all five weapons, the random offers and the card images work together in a real run, ready for the board's single playtest of `playtest/G-002`. | in-flight | T-176 |

### S1: Weapon data for the three new weapons (Game Data Agent)

Needs: nothing.

- `game/data/weapons.json` has entries for the neon underglow, the molotovs and the windshield wiper. Each has base values (for example damage, radius or size, interval) and exactly 7 upgrade tiers, each saying what it changes.
- `weapon_data.gd` reads the new entries, and a data test checks there are 5 weapons, each with tiers 1 to 8.
- The proposal and its reasoning are in the ticket's result notes, and `docs/weapons.md` Content says the numbers are proposals for the playtest.

### S3: Enemy knockback hook (Enemy Behavior Agent)

Needs: nothing.

- Minions (and the kaiju, if the board's answer says so) expose a knockback call taking a direction and a strength. A test shows a minion moved away by it and still not pushed through buildings, walls or boulders.
- Without the call, minion and kaiju movement is unchanged (the existing enemy tests still pass).
- `docs/enemies.md` Content and `game/README.md` 'Minions' describe the call.

### S4: Neon underglow behaviour with placeholder look (Weapon Behavior Agent)

Needs: S1.

- A run starts without it. Once it is given at tier 1, an enemy entering the circle takes damage at once and every enemy inside takes damage every second, through its damage function, with the numbers from weapons.json.
- Tiers 2 to 8 apply from code as weapons.json says (test per tier). It stops while paused and after the run ends, and resets on a new run.
- A placeholder circle under the car, drawn in code, never Redgull red, draws under the car.
- `docs/weapons.md` Content and `game/README.md` 'Weapons' describe it, and the weapon tests pass.

### S5: Molotovs behaviour with placeholder look (Weapon Behavior Agent)

Needs: S1.

- Once given at tier 1, molotovs are thrown from the car as the S1 data says (when and where they land are the agent's proposal within 'at random'). Each makes a circular fire area where it lands, and enemies inside burn and take damage, with numbers from weapons.json.
- Fire areas expire, are cleared on a new run, and stop while paused. Tiers 2 to 8 apply from code (test per tier).
- Whether burning goes on after an enemy leaves the fire follows the board's answer to the open question, and a test covers it.
- Placeholder bottle and fire area drawn in code, never Redgull red. `docs/weapons.md` Content and `game/README.md` are updated, and the weapon tests pass.

### S6: Windshield wiper behaviour with placeholder look (Weapon Behavior Agent)

Needs: S1, S3.

- Once given at tier 1, one wiper sweeps back and forth in a semicircle in front of the car, turning with the car. An enemy it hits takes damage and is pushed away through the S3 knockback call, with numbers from weapons.json.
- A test shows the gun and the flamethrower still never push enemies.
- Tiers 2 to 8 apply from code (test per tier). It stops while paused and resets on a new run.
- Placeholder wiper drawn in code, never Redgull red. `docs/weapons.md` Content and `game/README.md` are updated, and the weapon tests pass.

### S2: Level-up card text for the three new weapons (Narrative Theme Agent)

Needs: S1.

- The ticket's result notes hold a table with a title and a description for 'get_<weapon>' and 'upgrade_<weapon>.tier2' to 'tier8' for each of the three new weapons (24 pairs), each matching what that tier does in weapons.json.
- Each text follows the tone of the existing texts in `level_up_texts.gd` and the Extended narrative, and contains no Redgull-forbidden or real-brand words.

### S7: Level-up offers: two random choices from all five weapons (Weapon Behavior Agent)

Needs: S4, S5, S6.

- `level_up_offers.gd` offers choice ids for 'get' and 'upgrade' of all five weapons. The first level-up of a normal run offers exactly 'upgrade_gun' and 'get_flamethrower'. Later level-ups offer two different ids drawn at random from all available ones.
- Seeded tests: never the same id twice in one offer, tier 8 never offered, one card when one choice is left, choice skipped when none is left, and the flamethrower-at-start playtest switch still works.
- Taking each new choice applies the weapon or its next tier and resumes the run.
- `docs/weapons.md` Content 'The level-up offers' and `game/README.md` are updated.

### S8: Level-up screen: new card text and a weapon image on every card, placeholder images first (UI Agent)

Needs: S2, S7.

- `level_up_texts.gd` holds the S2 texts word for word, and a test checks that every choice id and tier the offers can produce has a title and a description.
- Each card shows its weapon's image (placeholder images drawn in code until S9, never Redgull red) along with its title, description and 'Take it' button. The layout keeps text readable and the build-up animation and keyboard and mouse rules work as before (existing level-up screen tests pass).
- A screenshot fixture shows two cards with images. `docs/hud-and-menus.md` Content 'Level-up screen' and `game/README.md` are updated.

### S9: PixelLab art: one card image per weapon, all five (Asset Generation Agent)

Needs: S8.

- Planned calls and cost are written in the result notes before calling, within the goal's art cap, with one generation round only.
- Five card images (starting gun, exhaust flamethrower, neon underglow, molotovs, windshield wiper) are in `game/art/level_up/` (or the folder the agent records) with records. They follow the Visual style pixel rules (hard edges, no semi-transparent pixels, transparent background), and red is used only where it fits Redgull's gift packs.
- The art replaces the S8 placeholders and the screenshot fixture shows them. Every other generation is in `art-archive/<task>/`. `docs/visual-style.md` is updated if an art decision is recorded.

### S10: PixelLab art: in-world art for the underglow, molotovs and fire area, and the wiper (Asset Generation Agent)

Needs: S4, S5, S6.

- Planned calls and cost are in the result notes before calling, staying within the art cap together with S9, with one generation round only.
- The underglow effect, the molotov (bottle and fire area, animated if the agent proposes it) and the wiper are in `game/art/` with records, at 32 art pixels per unit and drawn at scale 0.5, following the pixel rules.
- In a run with the three weapons owned, the placeholders are replaced by the art, and the weapon behaviour tests still pass. Every other generation is in `art-archive/<task>/`.

### S11: Integration check of the goal (QA/Integration Agent)

Needs: S7, S8, S9, S10.

- A run started from the main menu with all five weapons owned (dev or playtest switch, never visible to players) runs headless for 60 seconds with no script errors.
- A run that levels up repeatedly reaches tier 8 on several weapons with no repeated or maxed choice offered and no error.
- All three test sets pass, and the staleness check is clean after the long GDD and the short GDD fingerprint are regenerated.

## Scoring

Ranked by code, not by Claude: first by how many other sub-goals wait on it (directly or further down the chain), then by value (Claude's estimate, 1 to 5), then by Claude's order. A sub-goal is therefore always ranked before every sub-goal that needs it. A dependency cycle is refused. Score column: unblocks N (sub-goals waiting on it), value V.

## Tickets

- T-166: Weapon numbers: the neon underglow, the molotovs and the windshield wiper, with 8 tiers each (S1, written)
- T-167: Minions can be knocked back by a weapon (a knockback call) (S3, written)
- T-168: The neon underglow: a circle around the car that damages enemies (placeholder look) (S4, written)
- T-169: The molotovs: thrown from the car, they leave fire areas that burn enemies (placeholder look) (S5, written)
- T-170: The windshield wiper: sweeps in front of the car, damages and pushes minions back (placeholder look) (S6, written)
- T-171: Text: level-up cards for the neon underglow, the molotovs and the windshield wiper (S2, written)
- T-172: Level-up offers: two different random choices from all five weapons (S7, written)
- T-173: Level-up screen: cards for the new weapons, and a weapon image on every card (placeholder images) (S8, written)
- T-174: Art: one level-up card image per weapon, all five (PixelLab) (S9, written)
- T-175: Art: the neon underglow, the molotov and its fire area, and the windshield wiper in the world (PixelLab) (S10, written)
- T-176: QA: the five weapons, the random offers and the card images together in a run (S11, written)

## Iteration log

- 2026-10-18, iteration 0: started: planning.
- 2026-10-18, iteration 0: priority scoring: 11 sub-goals ranked, 9 goal criteria, 10 open questions.
- 2026-10-18, iteration 0: paused (see Pauses).
- 2026-10-18, iteration 0: resumed: its last pause (stop: another stop) can't be checked by the runner; --force.
- 2026-10-18, iteration 0: gap detection: S1 missing (wrote T-166), S3 missing (wrote T-167), S4 missing (wrote T-168), S5 missing (wrote T-169), S6 missing (wrote T-170), S2 missing (wrote T-171), S7 missing (wrote T-172), S8 missing (wrote T-173), S9 missing (wrote T-174), S10 missing (wrote T-175), S11 missing (wrote T-176).
- 2026-10-18, iteration 0: paused (see Pauses).
- 2026-10-18, iteration 0: resumed: its last pause (refusal: a headless session reported a refusal) can't be checked by the runner; --force.
- 2026-10-18, iteration 0: paused (see Pauses).
- 2026-10-18, iteration 0: resumed: its last pause (refusal: a headless session reported a refusal that blocked its work) can't be checked by the runner; --force.
- 2026-10-18, iteration 0: paused (see Pauses).
- 2026-10-18, iteration 0: resumed: its last pause (qa: QA left criteria unmarked) can't be checked by the runner; --force.
- 2026-10-18, iteration 1: T-166 (S1, game-data, sonnet): passed (done, QA rounds 1), merged into playtest/G-002; art 0; agent: (nothing new). Rescan: S1 covered, S3 in-flight, S4 in-flight, S5 in-flight, S6 in-flight, S2 in-flight, S7 in-flight, S8 in-flight, S9 in-flight, S10 in-flight, S11 in-flight.

## Pauses

- 2026-10-18 [stop]: Claude could not be run for step 'gaps': [WinError 206] The filename or extension is too long
- 2026-10-18 [refusal]: The game-data agent on T-166 reported a refusal; the runner never works around one: [{'tool_name': 'Bash', 'tool_use_id': 'toolu_01XtgK1F1yhu32e8CMdm9dhz', 'tool_input': {'command': 'python - <<\'EOF\'\np=\'game/data/weapons.json\'\ns=open(p,encoding=\'utf-8\').read()\ns=s.replace("The two MVP weapons, copied","The five MVP weapons: the gun and the flamethrower, copied")\ns=s.replace("No knockback (the weapons never push enemies).","The gun and the flamethrower never push enemies; of the five only the wiper pushes (knockback_distance, minions only, never the kaiju). The underglow, molotov and wiper entries are the Game Data Agent\'s proposal (T-166) for the board\'s playtest. Tiers: underglow and wiper numbers are in units and seconds; wiper sweep_degrees_per_second turns the arm, sweep_arc_degrees is the semicircle.")\nadd=\'\'\'  },\n  "underglow": {\n    "damage": 1,\n    "radius": 2.5,\n    "tick_interval": 1,\n    "damage_on_enter": true,\n    "tiers": [\n      { "tier": 2, "effect": "radius_multiplier", "value": 1.2 },\n      { "tier": 3, "effect": "damage_multiplier", "value": 1.5 },\n      { "tier": 4, "effect": "tick_interval_multiplier", "value": 0.75 },\n      { "tier": 5, "effect": "radius_multiplier", "value": 1.25 },\n      { "tier": 6, "effect": "damage_multiplier", "value": 1.5 },\n      { "tier": 7, "effect": "tick_interval_multiplier", "value": 0.67 },\n      { "tier": 8, "effect": "radius_multiplier", "value": 1.3 }\n    ]\n  },\n  "molotov": {\n    "damage": 2,\n    "throw_interval": 3,\n    "molotovs_per_throw": 1,\n    "throw_distance_min": 3,\n    "throw_distance_max": 8,\n    "fire_radius": 1.5,\n    "fire_duration": 3,\n    "tick_interval": 0.5,\n    "damage_on_enter": true,\n    "tiers": [\n      { "tier": 2, "effect": "fire_radius_multiplier", "value": 1.2 },\n      { "tier": 3, "effect": "throw_interval_multiplier", "value": 0.8 },\n      { "tier": 4, "effect": "damage_multiplier", "value": 1.5 },\n      { "tier": 5, "effect": "add_molotovs", "value": 1 },\n      { "tier": 6, "effect": "add_fire_duration_seconds", "value": 1.5 },\n      { "tier": 7, "effect": "fire_radius_multiplier", "value": 1.3 },\n      { "tier": 8, "effect": "add_molotovs", "value": 1 }\n    ]\n  },\n  "wiper": {\n    "damage": 3,\n    "length": 2.5,\n    "sweep_arc_degrees": 180,\n    "sweep_degrees_per_second": 240,\n    "hit_cooldown": 0.5,\n    "knockback_distance": 1.5,\n    "knockback_kaiju": false,\n    "tiers": [\n      { "tier": 2, "effect": "length_multiplier", "value": 1.2 },\n      { "tier": 3, "effect": "damage_multiplier", "value": 1.4 },\n      { "tier": 4, "effect": "sweep_speed_multiplier", "value": 1.25 },\n      { "tier": 5, "effect": "knockback_multiplier", "value": 1.5 },\n      { "tier": 6, "effect": "length_multiplier", "value": 1.3 },\n      { "tier": 7, "effect": "damage_multiplier", "value": 1.4 },\n      { "tier": 8, "effect": "sweep_speed_multiplier", "value": 1.3 }\n    ]\n  }\n}\n\'\'\'\ni=s.rstrip().rfind("  }\\n}")\ns=s[:i]+add\nopen(p,\'w\',encoding=\'utf-8\').write(s)\nimport json;json.load(open(p,encoding=\'utf-8\'))\n\np=\'game/scripts/data/weapon_data.gd\'\ns=open(p,encoding=\'utf-8\').read()\ns=s.replace("The two MVP weapons\' numbers","The five MVP weapons\' numbers")\ns=s.replace(\'"gun" or "flamethrower" (tiers\',\'"gun", "flamethrower", "underglow", "molotov" or "wiper" (tiers\')\ns+=\'\'\'\n\n## What the neon underglow does at `tier`: damage (per tick and on entering), radius,\n## tick_interval, damage_on_enter.\nfunc underglow_at(tier: int) -> Dictionary:\n\tvar u: Dictionary = _data["underglow"]\n\tvar damage := float(u["damage"])\n\tvar radius := float(u["radius"])\n\tvar tick := float(u["tick_interval"])\n\tfor t in tiers("underglow"):\n\t\tif int(t["tier"]) > tier:\n\t\t\tcontinue\n\t\tmatch String(t["effect"]):\n\t\t\t"radius_multiplier": radius *= float(t["value"])\n\t\t\t"damage_multiplier": damage *= float(t["value"])\n\t\t\t"tick_interval_multiplier": tick *= float(t["value"])\n\treturn {\n\t\t"damage": damage,\n\t\t"radius": radius,\n\t\t"tick_interval": tick,\n\t\t"damage_on_enter": bool(u["damage_on_enter"]),\n\t}\n\n\n## What the molotovs do at `tier`: damage, throw_interval, molotovs_per_throw, throw_distance_min,\n## throw_distance_max, fire_radius, fire_duration, tick_interval, damage_on_enter.\nfunc molotov_at(tier: int) -> Dictionary:\n\tvar m: Dictionary = _data["molotov"]\n\tvar damage := float(m["damage"])\n\tvar interval := float(m["throw_interval"])\n\tvar count := int(m["molotovs_per_throw"])\n\tvar radius := float(m["fire_radius"])\n\tvar duration := float(m["fire_duration"])\n\tfor t in tiers("molotov"):\n\t\tif int(t["tier"]) > tier:\n\t\t\tcontinue\n\t\tmatch String(t["effect"]):\n\t\t\t"fire_radius_multiplier": radius *= float(t["value"])\n\t\t\t"throw_interval_multiplier": interval *= float(t["value"])\n\t\t\t"damage_multiplier": damage *= float(t["value"])\n\t\t\t"add_molotovs": count += int(t["value"])\n\t\t\t"add_fire_duration_seconds": duration += float(t["value"])\n\treturn {\n\t\t"damage": damage,\n\t\t"throw_interval": interval,\n\t\t"molotovs_per_throw": count,\n\t\t"throw_distance_min": float(m["throw_distance_min"]),\n\t\t"throw_distance_max": float(m["throw_distance_max"]),\n\t\t"fire_radius": radius,\n\t\t"fire_duration": duration,\n\t\t"tick_interval": float(m["tick_interval"]),\n\t\t"damage_on_enter": bool(m["damage_on_enter"]),\n\t}\n\n\n## What the windshield wiper does at `tier`: damage, length, sweep_arc_degrees,\n## sweep_degrees_per_second, hit_cooldown, knockback_distance, knockback_kaiju.\nfunc wiper_at(tier: int) -> Dictionary:\n\tvar w: Dictionary = _data["wiper"]\n\tvar damage := float(w["damage"])\n\tvar length := float(w["length"])\n\tvar speed := float(w["sweep_degrees_per_second"])\n\tvar knock := float(w["knockback_distance"])\n\tfor t in tiers("wiper"):\n\t\tif int(t["tier"]) > tier:\n\t\t\tcontinue\n\t\tmatch String(t["effect"]):\n\t\t\t"length_multiplier": length *= float(t["value"])\n\t\t\t"damage_multiplier": damage *= float(t["value"])\n\t\t\t"sweep_speed_multiplier": speed *= float(t["value"])\n\t\t\t"knockback_multiplier": knock *= float(t["value"])\n\treturn {\n\t\t"damage": damage,\n\t\t"length": length,\n\t\t"sweep_arc_degrees": float(w["sweep_arc_degrees"]),\n\t\t"sweep_degrees_per_second": speed,\n\t\t"hit_cooldown": float(w["hit_cooldown"]),\n\t\t"knockback_distance": knock,\n\t\t"knockback_kaiju": bool(w["knockback_kaiju"]),\n\t}\n\'\'\'\nopen(p,\'w\',encoding=\'utf-8\').write(s)\n\np=\'game/tests/unit/test_weapon_data.gd\'\ns=open(p,encoding=\'utf-8\').read()\ns=s.replace(\'["gun", "flamethrower"]:\',\'["gun", "flamethrower", "underglow", "molotov", "wiper"]:\')\ns+=\'\'\'\n\nfunc test_five_weapons_each_with_eight_tiers() -> void:\n\tvar raw: Dictionary = GameData.load_file("weapons").data\n\tvar count := 0\n\tfor k in raw:\n\t\tif raw[k] is Dictionary and raw[k].has("tiers"):\n\t\t\tcount += 1\n\t\t\tassert_eq(raw[k].tiers.size() + 1, 8, "%s has base plus 7 tiers" % k)\n\tassert_eq(count, 5)\n\n\nfunc test_underglow_tiers() -> void:\n\tvar w := WeaponData.new()\n\tvar u1 := w.underglow_at(1)\n\tassert_eq(u1.damage, 1.0)\n\tassert_eq(u1.radius, 2.5)\n\tassert_eq(u1.tick_interval, 1.0)\n\tassert_true(u1.damage_on_enter)\n\tvar u8 := w.underglow_at(8)\n\tassert_almost_eq(u8.damage, 2.25, 0.0001)\n\tassert_almost_eq(u8.radius, 2.5 * 1.2 * 1.25 * 1.3, 0.0001)\n\tassert_almost_eq(u8.tick_interval, 0.75 * 0.67, 0.0001)\n\n\nfunc test_molotov_tiers() -> void:\n\tvar w := WeaponData.new()\n\tvar m1 := w.molotov_at(1)\n\tassert_eq(m1.molotovs_per_throw, 1)\n\tassert_eq(m1.fire_radius, 1.5)\n\tassert_eq(m1.fire_duration, 3.0)\n\tassert_eq(m1.throw_interval, 3.0)\n\tvar m8 := w.molotov_at(8)\n\tassert_eq(m8.molotovs_per_throw, 3)\n\tassert_almost_eq(m8.fire_radius, 1.5 * 1.2 * 1.3, 0.0001)\n\tassert_almost_eq(m8.fire_duration, 4.5, 0.0001)\n\tassert_almost_eq(m8.throw_interval, 2.4, 0.0001)\n\tassert_almost_eq(m8.damage, 3.0, 0.0001)\n\n\nfunc test_wiper_tiers_and_knockback() -> void:\n\tvar w := WeaponData.new()\n\tvar w1 := w.wiper_at(1)\n\tassert_eq(w1.damage, 3.0)\n\tassert_eq(w1.length, 2.5)\n\tassert_eq(w1.knockback_distance, 1.5)\n\tassert_false(w1.knockback_kaiju)\n\tvar w8 := w.wiper_at(8)\n\tassert_almost_eq(w8.damage, 3.0 * 1.4 * 1.4, 0.0001)\n\tassert_almost_eq(w8.length, 2.5 * 1.2 * 1.3, 0.0001)\n\tassert_almost_eq(w8.knockback_distance, 2.25, 0.0001)\n\tassert_almost_eq(w8.sweep_degrees_per_second, 240.0 * 1.25 * 1.3, 0.0001)\n\'\'\'\nopen(p,\'w\',encoding=\'utf-8\').write(s)\n\np=\'game/README.md\'\ns=open(p,encoding=\'utf-8\').read()\ns=s.replace("`data/weapons.json` holds the starting gun and the exhaust flamethrower: base values and, for each, the 7 upgrade tiers (tiers 2 to 8) as `effect` plus `value`.","`data/weapons.json` holds the starting gun, the exhaust flamethrower and (T-166, proposals for the board\'s playtest) the neon underglow (`underglow`), the molotovs (`molotov`) and the windshield wiper (`wiper`, the only entry with a knockback strength): base values and, for each, the 7 upgrade tiers (tiers 2 to 8) as `effect` plus `value`.")\ns=s.replace("`gun_at(tier)` and `flame_at(tier)` return","`gun_at(tier)`, `flame_at(tier)`, `underglow_at(tier)`, `molotov_at(tier)` and `wiper_at(tier)` return")\nopen(p,\'w\',encoding=\'utf-8\').write(s)\n\np=\'docs/weapons.md\'\ns=open(p,encoding=\'utf-8\').read()\nnew=\'\'\'### Numbers for the three new weapons (proposal, task T-166)\n\nProposals by the Game Data Agent for the board\'s playtest; the board judges and asks for changes. Numbers: [../game/data/weapons.json](../game/data/weapons.json). Each has 8 tiers (tier 1 is getting it; tiers 2 to 8 are 7 upgrades). Units and seconds as in the file. The garage damage bonus multiplies all of them.\n\n- **Neon underglow:** circle of radius 2.5 around the car; 1 damage when an enemy enters and every 1 second inside. Tiers: 2 radius x1.2; 3 damage x1.5; 4 tick interval x0.75; 5 radius x1.25; 6 damage x1.5; 7 tick interval x0.67; 8 radius x1.3 (final: radius about 5.85, damage 2.25 every 0.5 seconds).\n- **Molotovs:** one thrown every 3 seconds at a random spot 3 to 8 units from the car; fire area radius 1.5 lasting 3 seconds; enemies take 2 on entering and every 0.5 seconds while inside. Tiers: 2 radius x1.2; 3 throw interval x0.8; 4 damage x1.5; 5 one more molotov per throw; 6 fire lasts 1.5 seconds longer; 7 radius x1.3; 8 one more molotov per throw (final: 3 per throw every 2.4 seconds, radius 2.34, 4.5 seconds, 3 damage).\n- **Windshield wiper:** one arm 2.5 units long sweeping a 180 degree semicircle in front of the car at 240 degrees per second; 3 damage per hit, an enemy can be hit again after 0.5 seconds; minions are pushed back 1.5 units, the kaiju is damaged but not pushed. Tiers: 2 length x1.2; 3 damage x1.4; 4 sweep speed x1.25; 5 knockback x1.5; 6 length x1.3; 7 damage x1.4; 8 sweep speed x1.3 (final: length 3.9, damage 5.9, knockback 2.25).\n\n\'\'\'\ns=s.replace("### The level-up offers (built in task T-043)",new+"### The level-up offers (built in task T-043)",1)\nopen(p,\'w\',encoding=\'utf-8\').write(s)\nEOF\nls game/tests; grep -rn "godot" tools/*.py 2>/dev/null | head -3; ls game/addons 2>/dev/null'}}, {'tool_name': 'Bash', 'tool_use_id': 'toolu_01Gda1rpeGs9GcqTLyxUbS9D', 'tool_input': {'command': 'python -c "import json;json.load(open(\'game/data/weapons.json\'))" && ls tools | head -30; ls game | head -20; which godot godot4 2>/dev/null'}}, {'tool_name': 'PowerShell', 'tool_use_id': 'toolu_017qxc87aKUC9BQciHPgtzyW', 'tool_input': {'command': 'powershell -ExecutionPolicy Bypass -File game/tools/run_tests.ps1 2>&1 | Select-Object -Last 15', 'timeout': 400000}}, {'tool_name': 'PowerShell', 'tool_use_id': 'toolu_01CY9FsLfeEo5XT7K3DBEqZD', 'tool_input': {'command': '& game/tools/run_tests.ps1 | Select-Object -Last 15', 'timeout': 400000}}, {'tool_name': 'Bash', 'tool_use_id': 'toolu_013j5SaRtvHbumKDUyj62Fnj', 'tool_input': {'command': 'bash game/tools/run_tests.sh', 'timeout': 400000}}, {'tool_name': 'Bash', 'tool_use_id': 'toolu_011aMUrqP5bWzoAV9ZuWw7Fk', 'tool_input': {'command': 'git add game docs tasks/T-166-weapon-numbers-the-neon-underglow-the.md'}}, "bash game/tools/run_tests.sh (needed approval; wanted to run the game's tests)", 'powershell -ExecutionPolicy Bypass -File game/tools/run_tests.ps1 (refused: nested PowerShell process)', '& game/tools/run_tests.ps1 | Select-Object -Last 15 (refused: multiple operations need approval)', 'python -c json.load check chained with ls tools (refused: multiple operations need approval)', 'git add game docs tasks/T-166-... (needed approval; wanted to stage files for commit)']
- 2026-10-18 [refusal]: The game-data agent on T-166 reported a refusal; the runner never works around one: [{'tool_name': 'Bash', 'tool_use_id': 'toolu_01DejMqLJTsNXfQC4RripnPv', 'tool_input': {'command': 'python -c "import json;d=json.load(open(\'game/data/weapons.json\'));print({k:len(v[\'tiers\']) for k,v in d[\'weapons\'].items()} if \'weapons\' in d else list(d))"'}}, '`python -c` to parse `game/data/weapons.json` directly was refused as not pre-approved. I skipped it, because the loader tests already parse the file.']
- 2026-10-18 [qa]: QA left 3 criteria of T-166 unmarked.

