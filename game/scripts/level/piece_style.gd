extends Resource
## The look of the level creator's rooftops and ramps of any size (task T-251), drawn in the
## engine by elevation_platform_drawing.gd (textured mode): one tileable texture per face, and the
## numbers of the drawing. Every setting is here, in one resource
## (art/creator_pieces/piece_style.tres), so new textures (T-255) are swapped in by changing that
## file only. The textures are projected at TEXTURE_PX_PER_UNIT art pixels per unit, mirror-tiled
## (CanvasItem.TEXTURE_REPEAT_MIRROR) and drawn with nearest filtering.

## Art pixels per unit the textures are projected at (the sample map's art: 32, drawn at 0.5).
const TEXTURE_PX_PER_UNIT := 32.0

## A rooftop's top face.
@export var roof_top: Texture2D
## A rooftop's two visible walls (east and south).
@export var wall: Texture2D
## A ramp's driving surface (its lane lines along the texture's v run along the ramp).
@export var ramp_top: Texture2D
## A ramp's two visible sides.
@export var ramp_side: Texture2D
## The low wall standing on a rooftop's back edges (north and west); its transparent pixels show
## what is behind it. Null for no parapet.
@export var parapet: Texture2D
## Tile a ramp's textures plainly instead of mirrored (T-255): the ramp's textures must then be
## seamless, which lets the chevrons on its top point the same way along its whole length.
@export var ramp_plain_repeat := false
## The parapet's height, units (the sample map's: 20 art px).
@export var parapet_height_units := 0.625
## The west parapet faces east, away from the light: its colour times this.
@export var parapet_west_shade := 0.8
## How dark each wall is (times its texture): a rooftop's east and south walls, a ramp's sides.
@export var roof_east_shade := 0.86
@export var roof_south_shade := 0.66
@export var ramp_east_shade := 0.72
@export var ramp_south_shade := 0.54
## Art pixels between a wall's top edge and its texture's first row (the sample map's 4).
@export var wall_row_offset_px := 4.0
## The dark outline on the edges, and its width in drawn pixels (0.5 = one art pixel).
@export var outline_color := Color8(10, 12, 24)
@export var outline_width := 0.5
