# Scaling report (T-493)

Coverage = bounding box of a screen's visible content Controls as a share of the window; ratio = the worse of the bounding box's and the summed leaf-content area's (labels, buttons, pictures, sliders) against 1280x720. A screen is flagged when its coverage at any size drops under 85% of its 1280x720 coverage; a piece when its area share drops under 70%.

Captured by resizing the root window to each size (actual windows: {'1280x720': [1280, 720], '1920x1080': [1920, 1080], '2560x1440': [2560, 1440], '3840x2160': [3840, 2130], '3440x1440': [3440, 1440]}). Scan took 94 s.

## All screens (13 of 19 flagged), worst first

| Screen | 1280x720 | 1920x1080 | 2560x1440 | 3840x2160 | 3440x1440 |
|---|---|---|---|---|---|
| **garage** | 74% (1.00x) | 74% (1.00x) | 74% (1.00x) | 73% (0.99x) | 55% (0.74x) |
| **pause_hud_layout_editor** | 91% (1.00x) | 91% (1.00x) | 91% (1.00x) | 91% (0.99x) | 92% (0.74x) |
| **main_menu** | 33% (1.00x) | 33% (1.00x) | 33% (1.00x) | 33% (0.99x) | 25% (0.74x) |
| **hud_mission_page** | 91% (1.00x) | 91% (1.00x) | 91% (1.00x) | 91% (0.99x) | 92% (0.74x) |
| **hud_trick_popup** | 91% (1.00x) | 91% (1.00x) | 91% (1.00x) | 91% (0.99x) | 92% (0.74x) |
| **hud_combo_broken** | 91% (1.00x) | 91% (1.00x) | 91% (1.00x) | 91% (0.99x) | 92% (0.74x) |
| **pause_screen** | 93% (1.00x) | 93% (1.00x) | 93% (1.00x) | 93% (0.99x) | 93% (0.74x) |
| **hud_run_start** | 91% (1.00x) | 91% (1.00x) | 91% (1.00x) | 91% (0.99x) | 92% (0.74x) |
| **time_up_screen** | 91% (1.00x) | 91% (1.00x) | 91% (1.00x) | 91% (0.99x) | 92% (0.74x) |
| **wreck** | 91% (1.00x) | 91% (1.00x) | 91% (1.00x) | 91% (0.99x) | 92% (0.74x) |
| **pause_trick_list** | 91% (1.00x) | 91% (1.00x) | 91% (1.00x) | 91% (0.99x) | 92% (0.74x) |
| **power_up_overlay** | 91% (1.00x) | 91% (1.00x) | 91% (1.00x) | 91% (0.99x) | 92% (0.74x) |
| **recap_win** | 90% (1.00x) | 91% (1.00x) | 90% (1.00x) | 91% (0.99x) | 91% (0.84x) |
| recap_time_up | 90% (1.00x) | 91% (1.00x) | 90% (1.00x) | 91% (0.99x) | 91% (0.87x) |
| recap_wreck | 90% (1.00x) | 91% (1.00x) | 90% (1.00x) | 91% (0.99x) | 91% (0.87x) |
| tutorial_slide_3 | 100% (1.00x) | 100% (1.00x) | 100% (1.00x) | 100% (0.99x) | 100% (1.00x) |
| tutorial_slide_2 | 100% (1.00x) | 100% (1.00x) | 100% (1.00x) | 100% (0.99x) | 100% (1.00x) |
| tutorial_slide_1 | 100% (1.00x) | 100% (1.00x) | 100% (1.00x) | 100% (0.99x) | 100% (1.00x) |
| level_up_gift_pack | 100% (1.00x) | 100% (1.00x) | 100% (1.00x) | 100% (1.00x) | 100% (1.00x) |

Cells: coverage (ratio to 1280x720). Bold = flagged.

## garage

Contact sheet: `contact_sheets/garage.png`. Worst ratio 0.74.


## pause_hud_layout_editor

Contact sheet: `contact_sheets/pause_hud_layout_editor.png`. Worst ratio 0.74.


## main_menu

Contact sheet: `contact_sheets/main_menu.png`. Worst ratio 0.74.


## hud_mission_page

Contact sheet: `contact_sheets/hud_mission_page.png`. Worst ratio 0.74.


## hud_trick_popup

Contact sheet: `contact_sheets/hud_trick_popup.png`. Worst ratio 0.74.


## hud_combo_broken

Contact sheet: `contact_sheets/hud_combo_broken.png`. Worst ratio 0.74.


## pause_screen

Contact sheet: `contact_sheets/pause_screen.png`. Worst ratio 0.74.


## hud_run_start

Contact sheet: `contact_sheets/hud_run_start.png`. Worst ratio 0.74.


## time_up_screen

Contact sheet: `contact_sheets/time_up_screen.png`. Worst ratio 0.74.


## wreck

Contact sheet: `contact_sheets/wreck.png`. Worst ratio 0.74.


## pause_trick_list

Contact sheet: `contact_sheets/pause_trick_list.png`. Worst ratio 0.74.


## power_up_overlay

Contact sheet: `contact_sheets/power_up_overlay.png`. Worst ratio 0.74.


## recap_win

Contact sheet: `contact_sheets/recap_win.png`. Worst ratio 0.84.

- `Game/Recap/Margin/Column/Section_tricks` (PanelContainer): area share at 1280x720 18.8%, worst ratio 0.65

