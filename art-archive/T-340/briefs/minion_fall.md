Task T-340, the "minion_fall" set: the enemies' outlines made a little bolder, so the player sees and avoids them (Enemies, Decisions, "Damage in hearts, fewer health drops, bolder outlines"). Script pass only: NO PixelLab.

The art is one row of 40 frames of 48x48 (the set's five direction sheets side by side). Make the version with the free script:
  python game/tools/build_bolder_outlines.py build [--reach N] [--rim R,G,B]
  python game/tools/build_bolder_outlines.py strip minion_fall <the version path>
The script grows the sprites' dark outline one pixel outward in the sheet's own outline colour (no new colours, alpha 0 or 255, sizes unchanged), always from the originals in art-archive/T-340/originals/. Version 1 is the plain "build". If the evaluator says the outline is too thin, too heavy, lost against dark ground or breaks a rule, refine with the options (a lighter --rim ring just outside the outline, for example) and write the new strip. Frame size 48x48, 40 frames, at most 49 colours per frame. The subjects keep their look (Visual style rule 10).
