# Challenge drivability check

(From the old `game/README.md`; the index is [../../README.md](../../README.md).)

## Challenge drivability check

`game/tools/check_challenge.gd` (task T-021, Driving & Drift Agent) checks that a challenge drawing (`docs/level-design/<pattern>/arrow-*.json`) can be driven. The Level/Challenge Design Agent runs it on every challenge before handing it over.

**Run it** (headless, from the repo root; give drawings or folders, which are searched recursively):

```
bash game/tools/check_challenge.sh --save docs/level-design
```

```
powershell -ExecutionPolicy Bypass -File game/tools/check_challenge.ps1 --save docs/level-design
```

- It prints the car's handling values, then one line per drawing: `PASS` with how long the drive took and how fast it went, or `FAIL` with how far along the arrow the best attempt got, the drawing point nearest that place (numbered from the start, 1 = the white dot), what went wrong (left the corridor, hit a boulder, hit a building, stopped making progress) and the radius of the drawn curve there.
- `--save` writes, next to each passing drawing, `<name>.driven.json` (the line the car drove: x, y, speed and heading every physics step, plus the driver setting and the handling values used) and `<name>.driven.svg` (the drawing with the driven line in cyan and the drawn car every half second). It never changes the drawing's own `.json` or `.svg`.
- `--attempts=<folder>` writes a picture of the furthest attempt for each failing drawing into that folder (`<pattern>-<name>.attempt.svg`). Use a folder outside `docs/` and `game/`, such as `screenshots/`.
- `--set=<key>=<value>` overrides one handling value from `scripts/driving/car_tuning.gd` for this run, for example `--set=top_speed_multiplier=3.0`. Without it, the check uses the game's current values.
- Exit codes: 0 = every drawing can be driven; 1 = at least one cannot; 2 = bad arguments or a drawing could not be read.

**What it checks.** It drives the game's own car code (`scripts/driving/car_model.gd`, with the values in `car_tuning.gd`), 50 physics steps per second, pressing W, S, A and D each step like a player. The car starts on the arrow's first point, nose along the arrow. A drive passes when the car's centre reaches the arrow's last point while:

- the drawn car (1 by 3 units) touches the 3-unit corridor on every step, on the stretch of the arrow it has reached (3 units behind to 6 units ahead), so a path that crosses itself is followed in order;
- the car's physics body (1 by 1 unit) never touches a boulder or a building cell (`B`) of the drawing.

The centre line is the same rounded curve the drawing's picture shows. Two drivers try it:

- **A path follower** (120 fixed settings): it aims at a point a little way ahead on the arrow, turning the nose a bit past it to cancel the slide (counter-steer), and holds a target speed: W below it (W jumps to cruise speed, so under cruise it coasts and taps W), S when well above. The settings are 10 target speeds from top speed down to 3 units/s, 4 look-ahead distances and 3 counter-steer strengths.
- **A search over key combinations:** from a standstill on the arrow's start, it tries all 9 sets of keys (W, S or neither, with A, D or neither), each held for 5 physics steps, from the 48 most promising drives so far (furthest along the arrow and nearest its centre line, spread over positions, headings and speeds), until one reaches the end or none is left.

The drawing passes if any drive passes; the saved line is the quickest passing drive. On a fail, the reported place is the furthest any drive got. The `PASS` line also says whether the path follower passed with W held the whole way (a target speed at or above cruise speed), a quick sign of how hard the challenge is. Everything is deterministic: the same drawing and values always give the same result. A run of the 3 MVP drawings takes about 15 seconds.

The drawn car only has to touch the corridor, and it is 3 units long, so its centre can be up to about 3 units from the arrow's centre line. A quick drive can therefore cut inside a loop, close to a boulder, and the driven-line pictures show where it does. The drawn car may also overlap a boulder in the picture: only the 1 by 1 physics body collides.

The code is `tools/challenge_checker.gd` (the check and the picture) and `tools/check_challenge.gd` (the command line); its tests are `tests/unit/test_challenge_checker.gd`, part of the GUT suite.

