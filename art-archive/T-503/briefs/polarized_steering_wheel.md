# Brief: Polarized Steering Wheel icon (T-503)

A 32 x 32 pixel-art icon for the driving power-up "Polarized Steering Wheel" (lift off the gas, steer, then accelerate in a new direction for a speed burst). It replaces a script-drawn placeholder (art-archive/T-503/old/polarized_steering_wheel_placeholder.png). Shown at 64 x 64 on a power-up card.

Read docs/visual-style.md (Rules 1 to 6, 9) first. Look at game/art/power_ups/ (the other icons) and match their size, outline and palette.

Subject: one steering wheel, front view, a thick rim with three spokes and a hub, dark blue-grey rubber/steel, glossy highlights on the top-left of the rim, polarized look: a cyan glint on one half of the rim and a magenta glint on the other half, small stepped neon halo pixels. One clear central symbol.

Matched-set style: 32 x 32, transparent background, hard pixel edges, a dark almost-black 1 px outline broken by lighter highlight pixels, detailed shading, light from the top-left, neon night palette, at most 30 colours. The icon fills about 28 x 28 pixels, centred. No Greenbull light green (104,220,96) or yellow (247,208,52), no text, no real brands.

PixelLab call (planned): create-image-pixflux, 32x32, no_background, single color black outline, detailed shading, highly detailed, text_guidance_scale 8, same settings as T-465.

Refine rule from the board (2026-11-02): when refining, prefer a new PixelLab generation (adjust the prompt from the reason) over script repaints. Write any params JSON with the Write tool, never a heredoc or redirect into a file; do not run sed on the client or grep env. If any command is refused, stop and report it.
