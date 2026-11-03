class_name LevelUpTexts
extends RefCounted
## The level-up screen's approved text (task T-051, keyed as in its table; the
## three new weapons' cards from T-171's table, added in T-173; the board's trees
## from T-495). T-519 (the 4-minute run, Weapons, Decisions, "Shorter trees: 5
## tiers"): every weapon has 5 tiers, so tiers 2 to 5; the merged tiers' cards give the
## merged numbers; a new weapon arrives at tier 2, so its get_ card says what the
## player gets at tier 2 (and its upgrade_<weapon>.tier2 card is the same upgrade as a
## card). Tier 5 is the old tier 8's card (the molotov's rewritten).
## Card keys: "<choice id>.title" / ".desc" (get_<weapon>), and
## "<choice id>.tier<N>.title" / ".desc" for an upgrade giving tier N.

const TEXTS := {
	"levelup.title": "Greenbull sent a gift pack!",
	"levelup.take": "Take it",
	"upgrade_gun.tier2.title": "Two Extra Bullets",
	"upgrade_gun.tier2.desc": "+2 bullets per volley.",
	"upgrade_gun.tier3.title": "Double Quick Trigger",
	"upgrade_gun.tier3.desc": "Fire rate x1.44.",
	"upgrade_gun.tier4.title": "Bundle and Trigger",
	"upgrade_gun.tier4.desc": "+1 bullet per volley, fire rate x1.2.",
	"upgrade_gun.tier5.title": "Rated E for Everyone",
	"upgrade_gun.tier5.desc": "Fire rate x4. Everyone gets a bullet.",
	"get_flamethrower.title": "Hot Take Exhaust",
	"get_flamethrower.desc": "Tailpipe flames while you drift.",
	"upgrade_flamethrower.tier2.title": "Wider Burn II",
	"upgrade_flamethrower.tier2.desc": "Flame area x1.56, two boosts in one. Great for thumbnails.",
	"upgrade_flamethrower.tier3.title": "Hotter, Wider Burn",
	"upgrade_flamethrower.tier3.desc": "+20% Damage, +30% flame area.",
	"upgrade_flamethrower.tier4.title": "Hot Stuff",
	"upgrade_flamethrower.tier4.desc": "Enemies burn 2 seconds longer.",
	"upgrade_flamethrower.tier5.title": "Lit 24/7",
	"upgrade_flamethrower.tier5.desc": "The flame never goes out, even when you aren't drifting. Spark it up.",
	"get_underglow.title": "Neon Underglow",
	"get_underglow.desc": "Damages nearby enemies each second.",
	"upgrade_underglow.tier2.title": "Brighter, Wider Glow",
	"upgrade_underglow.tier2.desc": "Glow radius x1.5 (50% wider). Visible from the boardroom.",
	"upgrade_underglow.tier3.title": "Hotter Glow",
	"upgrade_underglow.tier3.desc": "Glow damage x2.25.",
	"upgrade_underglow.tier4.title": "Faster Pulse",
	"upgrade_underglow.tier4.desc": "Glow hits come twice as fast.",
	"upgrade_underglow.tier5.title": "Blinding Glow",
	"upgrade_underglow.tier5.desc": "+30% Glow radius. Sunglasses recommended.",
	"get_molotov.title": "Hot Drop",
	"get_molotov.desc": "Throws a molotov every 3 seconds.",
	"upgrade_molotov.tier2.title": "Bigger Blaze II",
	"upgrade_molotov.tier2.desc": "Fire radius x1.56, 56% bigger. Marketing wants it in every frame.",
	"upgrade_molotov.tier3.title": "ANOTHER TWO",
	"upgrade_molotov.tier3.desc": "+2 molotovs per throw.",
	"upgrade_molotov.tier4.title": "Quick Throw",
	"upgrade_molotov.tier4.desc": "+50% attack speed.",
	"upgrade_molotov.tier5.title": "MOREEEE",
	"upgrade_molotov.tier5.desc": "+1 Molotov per throw.",
	"get_wiper.title": "Wiper Blade",
	"get_wiper.desc": "Sweeps in front of the car, shoving minions back.",
	"upgrade_wiper.tier2.title": "Longer Blade II",
	"upgrade_wiper.tier2.desc": "Blade 56% longer (x1.56). Now in widescreen.",
	"upgrade_wiper.tier3.title": "Faster Sweep",
	"upgrade_wiper.tier3.desc": "Sweep speed x1.6.",
	"upgrade_wiper.tier4.title": "Shove and Stretch",
	"upgrade_wiper.tier4.desc": "Minion knockback x1.5. Blades x1.3 longer.",
	"upgrade_wiper.tier5.title": "Back Wiper",
	"upgrade_wiper.tier5.desc": "A copy of your front wiper sweeps behind. Maximum visibility.",
	"get_bricks.title": "Bricks",
	"get_bricks.desc": "Make the car heavier, sending impact waves after each jump landing.",
	"upgrade_bricks.tier2.title": "Wider Wave II",
	"upgrade_bricks.tier2.desc": "Landing wave radius x2.1. The brand loves a big splash.",
	"upgrade_bricks.tier3.title": "Harder Landing",
	"upgrade_bricks.tier3.desc": "Damage x2.25.",
	"upgrade_bricks.tier4.title": "Shove Factor",
	"upgrade_bricks.tier4.desc": "Knockback x2.25.",
	"upgrade_bricks.tier5.title": "Widest Wave",
	"upgrade_bricks.tier5.desc": "Your landing wave reaches its widest yet. Brace for impact!",
}
