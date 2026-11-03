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
	"upgrade_gun.tier2.desc": "+2 bullets per volley, 3 in all. Triple the content, same budget.",
	"upgrade_gun.tier3.title": "Double Quick Trigger",
	"upgrade_gun.tier3.desc": "Fire rate x1.44, two 20% boosts stacked. Marketing calls it innovation.",
	"upgrade_gun.tier4.title": "Bundle and Trigger",
	"upgrade_gun.tier4.desc": "+1 bullet per volley (4 in all), fire rate x1.2. More content per second.",
	"upgrade_gun.tier5.title": "Exposure for Everyone",
	"upgrade_gun.tier5.desc": "Fire rate x4, roughly 17 bullets a second. Everyone gets a shoutout.",
	"get_flamethrower.title": "Hot Take Exhaust",
	"get_flamethrower.desc": "Tailpipe flames while you drift, 56% bigger from the start. Great content.",
	"upgrade_flamethrower.tier2.title": "Wider Burn II",
	"upgrade_flamethrower.tier2.desc": "Flame area x1.56, two boosts in one. Great for thumbnails.",
	"upgrade_flamethrower.tier3.title": "Hotter, Wider Burn",
	"upgrade_flamethrower.tier3.desc": "Flame damage up 20%, flame area up 30%. Now in widescreen.",
	"upgrade_flamethrower.tier4.title": "Flammable Stuff",
	"upgrade_flamethrower.tier4.desc": "Enemies burn 2 seconds longer. Subs love a slow burn.",
	"upgrade_flamethrower.tier5.title": "Lit 24/7",
	"upgrade_flamethrower.tier5.desc": "The flame never goes out, even when you aren't drifting. Spark it up.",
	"get_underglow.title": "Neon Underglow",
	"get_underglow.desc": "Burns nearby enemies, 2 damage a second, nudges them back. Glow 50% wider. So aesthetic.",
	"upgrade_underglow.tier2.title": "Brighter, Wider Glow",
	"upgrade_underglow.tier2.desc": "Glow radius x1.5 (50% wider). Visible from the boardroom.",
	"upgrade_underglow.tier3.title": "Hotter Glow II",
	"upgrade_underglow.tier3.desc": "Glow damage x2.25, to 4.5 per hit. Peak production value.",
	"upgrade_underglow.tier4.title": "Faster Pulse II",
	"upgrade_underglow.tier4.desc": "Glow hits come twice as fast. Subs love a strobe.",
	"upgrade_underglow.tier5.title": "Blinding Glow",
	"upgrade_underglow.tier5.desc": "Glow radius up 30%. Sunglasses recommended.",
	"get_molotov.title": "Hot Drop",
	"get_molotov.desc": "Throws a molotov every 3 seconds. Fire lasts 3 seconds. Radius 56% bigger. Pre-sponsored.",
	"upgrade_molotov.tier2.title": "Bigger Blaze II",
	"upgrade_molotov.tier2.desc": "Fire radius x1.56, 56% bigger. Marketing wants it in every frame.",
	"upgrade_molotov.tier3.title": "ANOTHER TWO",
	"upgrade_molotov.tier3.desc": "2 more molotovs per throw, 3 in all. Fire always trends.",
	"upgrade_molotov.tier4.title": "Quick Throw II",
	"upgrade_molotov.tier4.desc": "Throw interval x0.56: every 1.68 seconds instead of 3. Content waits for no one.",
	"upgrade_molotov.tier5.title": "MOREEEE",
	"upgrade_molotov.tier5.desc": "+1 Molotov per throw, 4 per throw in all. The season finale the subs voted for.",
	"get_wiper.title": "Wiper Blade",
	"get_wiper.desc": "Sweeps a half circle for 3 damage, shoving minions back. Blade 56% longer. Size sells.",
	"upgrade_wiper.tier2.title": "Longer Blade II",
	"upgrade_wiper.tier2.desc": "Blade 56% longer (x1.56). Now in widescreen.",
	"upgrade_wiper.tier3.title": "Faster Sweep II",
	"upgrade_wiper.tier3.desc": "Sweep speed x1.625, two speed-ups merged. The brand team calls it synergy.",
	"upgrade_wiper.tier4.title": "Shove and Stretch",
	"upgrade_wiper.tier4.desc": "Minion knockback x1.5, 6 to 9. Blades x1.3 longer. Subs love a good shove.",
	"upgrade_wiper.tier5.title": "Back Wiper",
	"upgrade_wiper.tier5.desc": "A copy of your front wiper sweeps behind, upgrades and all. Rear-view content, monetised.",
	"get_bricks.title": "Bricks",
	"get_bricks.desc": "Bricks: heavier car. Each jump landing sends an impact wave, radius x2.1. Pure content.",
	"upgrade_bricks.tier2.title": "Wider Wave II",
	"upgrade_bricks.tier2.desc": "Landing wave radius x2.1. The brand loves a big splash.",
	"upgrade_bricks.tier3.title": "Harder Landing II",
	"upgrade_bricks.tier3.desc": "Landing wave damage x2.25, 6 becomes 13.5. Two 50% boosts, one press release.",
	"upgrade_bricks.tier4.title": "Shove Factor II",
	"upgrade_bricks.tier4.desc": "Landing wave knockback x2.25, from 4 to 9. Minions only, not the kaiju. Ragdolls get subs.",
	"upgrade_bricks.tier5.title": "Widest Wave",
	"upgrade_bricks.tier5.desc": "Your landing wave reaches its widest yet. Brace for impact!",
}
