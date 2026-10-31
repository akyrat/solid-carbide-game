"""T-399 helper: write parked_car_1_bottom_v2.json from v1's request, with the source's real facing.

v1 said from north-east to south-west and PixelLab kept the car's rear at the lower right
(no turn). The top picture's nose really points top left on screen, so v2 names it
north-west and asks for south-east (nose toward the viewer, at the lower right).

  python art-archive/T-399/make_bottom_v2_request.py
"""
import json
from pathlib import Path

here = Path(__file__).resolve().parent / "requests"
req = json.loads((here / "parked_car_1_bottom_v1.json").read_text())
req["from_direction"] = "north-west"
req["to_direction"] = "south-east"
req["direction_change"] = None
(here / "parked_car_1_bottom_v2.json").write_text(json.dumps(req, indent=1))
print("wrote", here / "parked_car_1_bottom_v2.json")
