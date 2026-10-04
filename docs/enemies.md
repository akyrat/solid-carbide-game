# Enemies

Which enemies exist, what they look like, how they move, deal damage, and behave.

*Maintained by the Project Lead. Agents: Enemy Behavior Agent (works on it), Game Data Agent (reads it). This is a source-of-truth document: content changes happen here first, then flow down to the long GDD and the short GDD.*

## Decided so far

- Each level ends with a different type of monster as its final boss. The kaiju is only the first level's boss.
- MVP boss: a sprite much bigger than the player, walking slowly toward the player, with contact damage.
- The boss has one special move. After a short animation, several meteors rain down at once. In 2D, each is a meteor sprite falling top to bottom, with an impact animation on landing.
- Before the meteors land, a danger warning area shows on the ground for 2 seconds. A meteor that lands on the player deals damage and knocks them back.
- Landed meteors become obstacles, laid out as one of the challenge designs (for example, two meteors). Once they land, a guide arrow appears between them, for example a curved figure-eight, to show this is the challenge to complete.
- The boss becomes vulnerable only by completing the challenges its own meteors create. Those use a different color than the challenges already on the map.
- Idea under consideration: a semi-transparent shield on the boss, in the same color as the arrow of the challenge it spawned, to signal that it is invulnerable.

## Parked for later

- How long does the boss stay vulnerable after a challenge is completed?
- How often does the boss use the meteor move, and can it start another while a challenge is still uncompleted?
- How does enemy pressure scale across the 7 minutes before the boss?

## Content

(To be written.)
