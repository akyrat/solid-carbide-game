# Scaling report (T-493)

Coverage = bounding box of a screen's visible content Controls as a share of the window; ratio = the worse of the bounding box's and the summed leaf-content area's (labels, buttons, pictures, sliders) against 1280x720. A screen is flagged when its coverage at any size drops under 85% of its 1280x720 coverage; a piece when its area share drops under 70%.

Captured by resizing the root window to each size (actual windows: {'1280x720': [1280, 720], '1920x1080': [1920, 1080], '2560x1440': [2560, 1440], '3840x2160': [3840, 2130], '3440x1440': [3440, 1440]}). Scan took 94 s.

## All screens (16 of 19 flagged), worst first

| Screen | 1280x720 | 1920x1080 | 2560x1440 | 3840x2160 | 3440x1440 |
|---|---|---|---|---|---|
| **main_menu** | 27% (1.00x) | 12% (0.44x) | 7% (0.25x) | 3% (0.11x) | 5% (0.19x) |
| **recap_win** | 91% (1.00x) | 94% (0.54x) | 96% (0.35x) | 97% (0.21x) | 96% (0.32x) |
| **recap_time_up** | 91% (1.00x) | 94% (0.56x) | 96% (0.38x) | 97% (0.23x) | 96% (0.35x) |
| **recap_wreck** | 91% (1.00x) | 94% (0.56x) | 96% (0.38x) | 97% (0.23x) | 96% (0.35x) |
| **power_up_overlay** | 91% (1.00x) | 91% (0.54x) | 91% (0.38x) | 91% (0.26x) | 92% (0.28x) |
| **level_up_gift_pack** | 100% (1.00x) | 100% (0.86x) | 91% (0.53x) | 91% (0.29x) | 92% (0.39x) |
| **pause_trick_list** | 91% (1.00x) | 91% (0.71x) | 91% (0.61x) | 91% (0.54x) | 92% (0.46x) |
| **pause_screen** | 93% (1.00x) | 93% (0.76x) | 93% (0.67x) | 93% (0.60x) | 93% (0.50x) |
| **pause_hud_layout_editor** | 91% (1.00x) | 91% (0.95x) | 91% (0.93x) | 91% (0.91x) | 92% (0.69x) |
| **garage** | 74% (1.00x) | 74% (1.00x) | 74% (1.00x) | 73% (0.99x) | 55% (0.74x) |
| **hud_mission_page** | 91% (1.00x) | 91% (1.00x) | 91% (1.00x) | 91% (0.99x) | 92% (0.74x) |
| **hud_trick_popup** | 91% (1.00x) | 91% (1.00x) | 91% (1.00x) | 91% (0.99x) | 92% (0.74x) |
| **hud_combo_broken** | 91% (1.00x) | 91% (1.00x) | 91% (1.00x) | 91% (0.99x) | 92% (0.74x) |
| **hud_run_start** | 91% (1.00x) | 91% (1.00x) | 91% (1.00x) | 91% (0.99x) | 92% (0.74x) |
| **time_up_screen** | 91% (1.00x) | 91% (1.00x) | 91% (1.00x) | 91% (0.99x) | 92% (0.74x) |
| **wreck** | 91% (1.00x) | 91% (1.00x) | 91% (1.00x) | 91% (0.99x) | 92% (0.74x) |
| tutorial_slide_3 | 100% (1.00x) | 100% (1.00x) | 100% (1.00x) | 100% (0.99x) | 100% (1.00x) |
| tutorial_slide_2 | 100% (1.00x) | 100% (1.00x) | 100% (1.00x) | 100% (0.99x) | 100% (1.00x) |
| tutorial_slide_1 | 100% (1.00x) | 100% (1.00x) | 100% (1.00x) | 100% (0.99x) | 100% (1.00x) |

Cells: coverage (ratio to 1280x720). Bold = flagged.

## main_menu

Contact sheet: `contact_sheets/main_menu.png`. Worst ratio 0.11.

- `Game/MainMenu/@CenterContainer@2/@VBoxContainer@3/Subtitle` (Label): area share at 1280x720 1.3%, worst ratio 0.11
- `Game/MainMenu/@CenterContainer@2/@VBoxContainer@3/Title` (Label): area share at 1280x720 4.4%, worst ratio 0.11
- `Game/MainMenu/@CenterContainer@2/@VBoxContainer@3/StartButton` (Button): area share at 1280x720 4.4%, worst ratio 0.11
- `Game/MainMenu/@CenterContainer@2/@VBoxContainer@3/GarageButton` (Button): area share at 1280x720 4.4%, worst ratio 0.11
- `Game/MainMenu/@CenterContainer@2/@VBoxContainer@3/ExitButton` (Button): area share at 1280x720 4.4%, worst ratio 0.11

## recap_win

Contact sheet: `contact_sheets/recap_win.png`. Worst ratio 0.21.

- `Game/Recap/Margin/Column/@CenterContainer@983/TitlePanel` (PanelContainer): area share at 1280x720 3.4%, worst ratio 0.11
- `Game/Recap/Margin/Column/Section_tricks/@VBoxContainer@991/@HFlowContainer@992/Trick_alternate_drift/Image` (TextureRect): area share at 1280x720 0.5%, worst ratio 0.11
- `Game/Recap/Margin/Column/Section_tricks/@VBoxContainer@991/@HFlowContainer@992/Trick_air_three_sixty/Image` (TextureRect): area share at 1280x720 0.5%, worst ratio 0.11
- `Game/Recap/Margin/Column/Section_tricks/@VBoxContainer@991/@HFlowContainer@992/Trick_airtime/Image` (TextureRect): area share at 1280x720 0.6%, worst ratio 0.11
- `Game/Recap/Margin/Column/Section_tricks/@VBoxContainer@991/@HFlowContainer@992/Trick_thread_the_needle/Image` (TextureRect): area share at 1280x720 0.9%, worst ratio 0.11
- `Game/Recap/Margin/Column/Section_weapons/@VBoxContainer@993/@HBoxContainer@994/Weapon_gun/Name` (Label): area share at 1280x720 0.2%, worst ratio 0.11
- `Game/Recap/Margin/Column/Section_weapons/@VBoxContainer@993/@HBoxContainer@994/Weapon_gun/Tier` (Label): area share at 1280x720 0.2%, worst ratio 0.11
- `Game/Recap/Margin/Column/Section_weapons/@VBoxContainer@993/@HBoxContainer@994/Weapon_flamethrower/Name` (Label): area share at 1280x720 0.3%, worst ratio 0.11
- `Game/Recap/Margin/Column/Section_weapons/@VBoxContainer@993/@HBoxContainer@994/Weapon_flamethrower/Tier` (Label): area share at 1280x720 0.3%, worst ratio 0.11
- `Game/Recap/Margin/Column/TopRow/Section_enemies/@VBoxContainer@986/@HBoxContainer@987/Enemy_minion/Image` (TextureRect): area share at 1280x720 0.4%, worst ratio 0.11
- `Game/Recap/Margin/Column/TopRow/Section_enemies/@VBoxContainer@986/@HBoxContainer@987/Enemy_minion/@VBoxContainer@984/Name` (Label): area share at 1280x720 0.2%, worst ratio 0.11
- `Game/Recap/Margin/Column/TopRow/Section_enemies/@VBoxContainer@986/@HBoxContainer@987/Enemy_minion/@VBoxContainer@984/Count` (Label): area share at 1280x720 0.3%, worst ratio 0.11
- ... 25 more pieces in the JSON

## recap_time_up

Contact sheet: `contact_sheets/recap_time_up.png`. Worst ratio 0.23.

- `Game/Recap/Margin/Column/@CenterContainer@1133/TitlePanel` (PanelContainer): area share at 1280x720 2.7%, worst ratio 0.11
- `Game/Recap/Margin/Column/Section_tricks/@VBoxContainer@1140/@HFlowContainer@1141/Trick_alternate_drift/Image` (TextureRect): area share at 1280x720 0.5%, worst ratio 0.11
- `Game/Recap/Margin/Column/Section_tricks/@VBoxContainer@1140/@HFlowContainer@1141/Trick_thread_the_needle/Image` (TextureRect): area share at 1280x720 0.9%, worst ratio 0.11
- `Game/Recap/Margin/Column/Section_weapons/@VBoxContainer@1142/@HBoxContainer@1143/Weapon_gun/Name` (Label): area share at 1280x720 0.2%, worst ratio 0.11
- `Game/Recap/Margin/Column/Section_weapons/@VBoxContainer@1142/@HBoxContainer@1143/Weapon_gun/Tier` (Label): area share at 1280x720 0.2%, worst ratio 0.11
- `Game/Recap/Margin/Column/TopRow/Section_enemies/@VBoxContainer@1135/@HBoxContainer@1136/Enemy_minion/Image` (TextureRect): area share at 1280x720 0.4%, worst ratio 0.11
- `Game/Recap/Margin/Column/TopRow/Section_enemies/@VBoxContainer@1135/@HBoxContainer@1136/Enemy_minion/@VBoxContainer@1134/Name` (Label): area share at 1280x720 0.2%, worst ratio 0.11
- `Game/Recap/Margin/Column/TopRow/Section_enemies/@VBoxContainer@1135/@HBoxContainer@1136/Enemy_minion/@VBoxContainer@1134/Count` (Label): area share at 1280x720 0.3%, worst ratio 0.11
- `Game/Recap/Margin/Column/TopRow/Section_combo/@VBoxContainer@1138/@CenterContainer@1139/@HBoxContainer@1137/PeakHolder/PeakViewers` (Label): area share at 1280x720 1.3%, worst ratio 0.11
- `Game/Recap/Margin/Column/Section_tricks/@VBoxContainer@1140/@HFlowContainer@1141/Trick_three_sixty/Image` (TextureRect): area share at 1280x720 0.5%, worst ratio 0.11
- `Game/Recap/Margin/Column/Section_weapons/@VBoxContainer@1142/@HBoxContainer@1143/Weapon_gun/Image` (TextureRect): area share at 1280x720 0.4%, worst ratio 0.11
- `Game/Recap/Margin/Column/Section_weapons/@VBoxContainer@1142/@HBoxContainer@1143/Weapon_underglow/Image` (TextureRect): area share at 1280x720 0.4%, worst ratio 0.11
- ... 15 more pieces in the JSON

## recap_wreck

Contact sheet: `contact_sheets/recap_wreck.png`. Worst ratio 0.23.

- `Game/Recap/Margin/Column/@CenterContainer@1276/TitlePanel` (PanelContainer): area share at 1280x720 2.6%, worst ratio 0.11
- `Game/Recap/Margin/Column/Section_tricks/@VBoxContainer@1283/@HFlowContainer@1284/Trick_alternate_drift/Image` (TextureRect): area share at 1280x720 0.5%, worst ratio 0.11
- `Game/Recap/Margin/Column/Section_tricks/@VBoxContainer@1283/@HFlowContainer@1284/Trick_thread_the_needle/Image` (TextureRect): area share at 1280x720 0.9%, worst ratio 0.11
- `Game/Recap/Margin/Column/Section_weapons/@VBoxContainer@1285/@HBoxContainer@1286/Weapon_gun/Name` (Label): area share at 1280x720 0.2%, worst ratio 0.11
- `Game/Recap/Margin/Column/Section_weapons/@VBoxContainer@1285/@HBoxContainer@1286/Weapon_gun/Tier` (Label): area share at 1280x720 0.2%, worst ratio 0.11
- `Game/Recap/Margin/Column/TopRow/Section_enemies/@VBoxContainer@1278/@HBoxContainer@1279/Enemy_minion/Image` (TextureRect): area share at 1280x720 0.4%, worst ratio 0.11
- `Game/Recap/Margin/Column/TopRow/Section_enemies/@VBoxContainer@1278/@HBoxContainer@1279/Enemy_minion/@VBoxContainer@1277/Name` (Label): area share at 1280x720 0.2%, worst ratio 0.11
- `Game/Recap/Margin/Column/TopRow/Section_enemies/@VBoxContainer@1278/@HBoxContainer@1279/Enemy_minion/@VBoxContainer@1277/Count` (Label): area share at 1280x720 0.3%, worst ratio 0.11
- `Game/Recap/Margin/Column/TopRow/Section_combo/@VBoxContainer@1281/@CenterContainer@1282/@HBoxContainer@1280/PeakHolder/PeakViewers` (Label): area share at 1280x720 1.3%, worst ratio 0.11
- `Game/Recap/Margin/Column/Section_tricks/@VBoxContainer@1283/@HFlowContainer@1284/Trick_three_sixty/Image` (TextureRect): area share at 1280x720 0.5%, worst ratio 0.11
- `Game/Recap/Margin/Column/Section_weapons/@VBoxContainer@1285/@HBoxContainer@1286/Weapon_gun/Image` (TextureRect): area share at 1280x720 0.4%, worst ratio 0.11
- `Game/Recap/Margin/Column/Section_weapons/@VBoxContainer@1285/@HBoxContainer@1286/Weapon_underglow/Image` (TextureRect): area share at 1280x720 0.4%, worst ratio 0.11
- ... 15 more pieces in the JSON

## power_up_overlay

Contact sheet: `contact_sheets/power_up_overlay.png`. Worst ratio 0.26.

- `Game/Run/PowerUpScreen/PowerUpScreen/@CenterContainer@380/@VBoxContainer@381/HeaderHolder/Header/TitleLabel` (Label): area share at 1280x720 6.6%, worst ratio 0.11
- `Game/Run/PowerUpScreen/PowerUpScreen/@CenterContainer@380/@VBoxContainer@381/Cards/Card_rev_charge/Body/Frame` (Panel): area share at 1280x720 12.5%, worst ratio 0.11
- `Game/Run/PowerUpScreen/PowerUpScreen/@CenterContainer@380/@VBoxContainer@381/Cards/Card_rev_charge/Body/@MarginContainer@467/@VBoxContainer@468/Name` (Label): area share at 1280x720 1.2%, worst ratio 0.11
- `Game/Run/PowerUpScreen/PowerUpScreen/@CenterContainer@380/@VBoxContainer@381/Cards/Card_rev_charge/ClickArea` (Button): area share at 1280x720 12.5%, worst ratio 0.11
- `Game/Run/PowerUpScreen/PowerUpScreen/@CenterContainer@380/@VBoxContainer@381/Cards/Card_jump/Body/Frame` (Panel): area share at 1280x720 12.5%, worst ratio 0.11
- `Game/Run/PowerUpScreen/PowerUpScreen/@CenterContainer@380/@VBoxContainer@381/Cards/Card_jump/Body/@MarginContainer@469/@VBoxContainer@470/Name` (Label): area share at 1280x720 1.2%, worst ratio 0.11
- `Game/Run/PowerUpScreen/PowerUpScreen/@CenterContainer@380/@VBoxContainer@381/Cards/Card_jump/ClickArea` (Button): area share at 1280x720 12.5%, worst ratio 0.11
- `Game/Run/PowerUpScreen/PowerUpScreen/@CenterContainer@380/@VBoxContainer@381/Cards/Card_rev_charge/Body/HighlightFrame` (Panel): area share at 1280x720 14.1%, worst ratio 0.11
- `Game/Run/PowerUpScreen/PowerUpScreen/@CenterContainer@380/@VBoxContainer@381/Cards/Card_rev_charge/Body/@MarginContainer@467/@VBoxContainer@468/Icon` (TextureRect): area share at 1280x720 0.4%, worst ratio 0.11
- `Game/Run/PowerUpScreen/PowerUpScreen/@CenterContainer@380/@VBoxContainer@381/Cards/Card_rev_charge/Body/@MarginContainer@467/@VBoxContainer@468/Description` (Label): area share at 1280x720 4.8%, worst ratio 0.11
- `Game/Run/PowerUpScreen/PowerUpScreen/@CenterContainer@380/@VBoxContainer@381/Cards/Card_jump/Body/@MarginContainer@469/@VBoxContainer@470/Icon` (TextureRect): area share at 1280x720 0.4%, worst ratio 0.11
- `Game/Run/PowerUpScreen/PowerUpScreen/@CenterContainer@380/@VBoxContainer@381/Cards/Card_jump/Body/@MarginContainer@469/@VBoxContainer@470/Description` (Label): area share at 1280x720 4.8%, worst ratio 0.11

## level_up_gift_pack

Contact sheet: `contact_sheets/level_up_gift_pack.png`. Worst ratio 0.29.

- `Game/Run/LevelUpScreen/LevelUpScreen/@CenterContainer@231/@VBoxContainer@232/Banner/Ribbon` (TextureRect): area share at 1280x720 7.3%, worst ratio 0.11
- `Game/Run/LevelUpScreen/LevelUpScreen/Sunburst` (TextureRect): area share at 1280x720 113.8%, worst ratio 0.11
- `Game/Run/LevelUpScreen/LevelUpScreen/@CenterContainer@231/@VBoxContainer@232/Banner/Ribbon/TitleLabel` (Label): area share at 1280x720 4.4%, worst ratio 0.11
- `Game/Run/LevelUpScreen/LevelUpScreen/@CenterContainer@231/@VBoxContainer@232/Banner/Emblem` (TextureRect): area share at 1280x720 1.8%, worst ratio 0.11
- `Game/Run/LevelUpScreen/LevelUpScreen/@CenterContainer@231/@VBoxContainer@232/Cards/Card_upgrade_gun/Body/@MarginContainer@342/@VBoxContainer@343/WeaponImage` (TextureRect): area share at 1280x720 0.4%, worst ratio 0.11
- `Game/Run/LevelUpScreen/LevelUpScreen/@CenterContainer@231/@VBoxContainer@232/Cards/Card_upgrade_gun/Body/@MarginContainer@342/@VBoxContainer@343/Title` (Label): area share at 1280x720 1.3%, worst ratio 0.11
- `Game/Run/LevelUpScreen/LevelUpScreen/@CenterContainer@231/@VBoxContainer@232/Cards/Card_upgrade_gun/ClickArea` (Button): area share at 1280x720 14.6%, worst ratio 0.11
- `Game/Run/LevelUpScreen/LevelUpScreen/@CenterContainer@231/@VBoxContainer@232/Cards/Card_get_wiper/Body/@MarginContainer@344/@VBoxContainer@345/WeaponImage` (TextureRect): area share at 1280x720 0.4%, worst ratio 0.11
- `Game/Run/LevelUpScreen/LevelUpScreen/@CenterContainer@231/@VBoxContainer@232/Cards/Card_get_wiper/Body/@MarginContainer@344/@VBoxContainer@345/Title` (Label): area share at 1280x720 1.3%, worst ratio 0.11
- `Game/Run/LevelUpScreen/LevelUpScreen/@CenterContainer@231/@VBoxContainer@232/Cards/Card_get_wiper/ClickArea` (Button): area share at 1280x720 14.6%, worst ratio 0.11
- `Game/Run/LevelUpScreen/LevelUpScreen/@CenterContainer@231/@VBoxContainer@232/Cards/Card_upgrade_gun/Body/@MarginContainer@342/@VBoxContainer@343/Description` (Label): area share at 1280x720 6.5%, worst ratio 0.11
- `Game/Run/LevelUpScreen/LevelUpScreen/@CenterContainer@231/@VBoxContainer@232/Cards/Card_get_wiper/Body/@MarginContainer@344/@VBoxContainer@345/Description` (Label): area share at 1280x720 6.5%, worst ratio 0.11

## pause_trick_list

Contact sheet: `contact_sheets/pause_trick_list.png`. Worst ratio 0.46.

- `Game/Run/PauseScreenLayer/PauseScreen/TrickListPanel/@VBoxContainer@573/TrickList/Layout/List/Row_extended_drift/@HBoxContainer@574/Picture` (TextureRect): area share at 1280x720 0.3%, worst ratio 0.11
- `Game/Run/PauseScreenLayer/PauseScreen/TrickListPanel/@VBoxContainer@573/TrickList/Layout/List/Row_three_sixty/@HBoxContainer@575/Picture` (TextureRect): area share at 1280x720 0.3%, worst ratio 0.11
- `Game/Run/PauseScreenLayer/PauseScreen/TrickListPanel/@VBoxContainer@573/TrickList/Layout/List/Row_three_sixty/@HBoxContainer@575/Name` (Label): area share at 1280x720 0.2%, worst ratio 0.11
- `Game/Run/PauseScreenLayer/PauseScreen/TrickListPanel/@VBoxContainer@573/TrickList/Layout/List/Row_alternate_drift/@HBoxContainer@576/Picture` (TextureRect): area share at 1280x720 0.3%, worst ratio 0.11
- `Game/Run/PauseScreenLayer/PauseScreen/TrickListPanel/@VBoxContainer@573/TrickList/Layout/List/Row_air_one_eighty/@HBoxContainer@577/Picture` (TextureRect): area share at 1280x720 0.3%, worst ratio 0.11
- `Game/Run/PauseScreenLayer/PauseScreen/TrickListPanel/@VBoxContainer@573/TrickList/Layout/List/Row_air_three_sixty/@HBoxContainer@578/Picture` (TextureRect): area share at 1280x720 0.3%, worst ratio 0.11
- `Game/Run/PauseScreenLayer/PauseScreen/TrickListPanel/@VBoxContainer@573/TrickList/Layout/List/Row_airtime/@HBoxContainer@579/Picture` (TextureRect): area share at 1280x720 0.3%, worst ratio 0.11
- `Game/Run/PauseScreenLayer/PauseScreen/TrickListPanel/@VBoxContainer@573/TrickList/Layout/List/Row_thread_the_needle/@HBoxContainer@580/Picture` (TextureRect): area share at 1280x720 0.3%, worst ratio 0.11
- `Game/Run/PauseScreenLayer/PauseScreen/TrickListPanel/@VBoxContainer@573/TrickList/Layout/Detail/Recipe/Step1/Note` (Label): area share at 1280x720 0.2%, worst ratio 0.11
- `Game/Run/PauseScreenLayer/PauseScreen/TrickListPanel` (PanelContainer): area share at 1280x720 47.9%, worst ratio 0.11
- `Game/Run/PauseScreenLayer/PauseScreen/TrickListPanel/@VBoxContainer@573/TrickList/Layout/Detail/Middle/Rule` (Label): area share at 1280x720 1.9%, worst ratio 0.11
- `Game/Run/PauseScreenLayer/PauseScreen/TrickListPanel/@VBoxContainer@573/TrickList/Layout/Detail/Recipe/Step1/Keys/KeyW` (PanelContainer): area share at 1280x720 0.2%, worst ratio 0.11
- ... 9 more pieces in the JSON

## pause_screen

Contact sheet: `contact_sheets/pause_screen.png`. Worst ratio 0.50.

- `Game/Run/PauseScreenLayer/PauseScreen/@PanelContainer@558/@CenterContainer@559/@VBoxContainer@560/@Label@562` (Label): area share at 1280x720 1.0%, worst ratio 0.11
- `Game/Run/PauseScreenLayer/PauseScreen/@PanelContainer@558/@CenterContainer@559/@VBoxContainer@560/@HBoxContainer@572/SmoothingCheck` (CheckBox): area share at 1280x720 0.3%, worst ratio 0.11
- `Game/Run/PauseScreenLayer/PauseScreen/@PanelContainer@558/@CenterContainer@559/@VBoxContainer@560/@Label@561` (Label): area share at 1280x720 1.7%, worst ratio 0.11
- `Game/Run/PauseScreenLayer/PauseScreen/@PanelContainer@558/@CenterContainer@559/@VBoxContainer@560/@HBoxContainer@563/@Label@564` (Label): area share at 1280x720 0.3%, worst ratio 0.11
- `Game/Run/PauseScreenLayer/PauseScreen/@PanelContainer@558/@CenterContainer@559/@VBoxContainer@560/@HBoxContainer@563/ZoomSlider` (HSlider): area share at 1280x720 0.5%, worst ratio 0.11
- `Game/Run/PauseScreenLayer/PauseScreen/@PanelContainer@558/@CenterContainer@559/@VBoxContainer@560/MusicRow/@Label@568` (Label): area share at 1280x720 0.3%, worst ratio 0.11
- `Game/Run/PauseScreenLayer/PauseScreen/@PanelContainer@558/@CenterContainer@559/@VBoxContainer@560/MusicRow/MusicSlider` (HSlider): area share at 1280x720 0.5%, worst ratio 0.11
- `Game/Run/PauseScreenLayer/PauseScreen/@PanelContainer@558/@CenterContainer@559/@VBoxContainer@560/HudSizeRow/@Label@570` (Label): area share at 1280x720 0.3%, worst ratio 0.11
- `Game/Run/PauseScreenLayer/PauseScreen/@PanelContainer@558/@CenterContainer@559/@VBoxContainer@560/HudSizeRow/HudSizeSlider` (HSlider): area share at 1280x720 0.5%, worst ratio 0.11
- `Game/Run/PauseScreenLayer/PauseScreen/@PanelContainer@558/@CenterContainer@559/@VBoxContainer@560/RunButtonsRow/TrickListButton` (Button): area share at 1280x720 0.3%, worst ratio 0.11
- `Game/Run/PauseScreenLayer/PauseScreen/@PanelContainer@558/@CenterContainer@559/@VBoxContainer@560/RunButtonsRow/HudLayoutButton` (Button): area share at 1280x720 0.4%, worst ratio 0.11
- `Game/Run/PauseScreenLayer/PauseScreen/@PanelContainer@558/@CenterContainer@559/@VBoxContainer@560/RunButtonsRow/RestartButton` (Button): area share at 1280x720 0.3%, worst ratio 0.11
- ... 2 more pieces in the JSON

## pause_hud_layout_editor

Contact sheet: `contact_sheets/pause_hud_layout_editor.png`. Worst ratio 0.69.

- `Game/Run/PauseScreenLayer/PauseScreen/HudLayoutEditor/EditorBar` (PanelContainer): area share at 1280x720 1.9%, worst ratio 0.11
- `Game/Run/PauseScreenLayer/PauseScreen/HudLayoutEditor/EditorBar/@VBoxContainer@583/HintLabel` (Label): area share at 1280x720 0.4%, worst ratio 0.11
- `Game/Run/PauseScreenLayer/PauseScreen/HudLayoutEditor/EditorBar/@VBoxContainer@583/@HBoxContainer@584/DoneButton` (Button): area share at 1280x720 0.2%, worst ratio 0.11
- `Game/Run/PauseScreenLayer/PauseScreen/HudLayoutEditor/EditorBar/@VBoxContainer@583/@HBoxContainer@584/ResetLayoutButton` (Button): area share at 1280x720 0.4%, worst ratio 0.11

## garage

Contact sheet: `contact_sheets/garage.png`. Worst ratio 0.74.


## hud_mission_page

Contact sheet: `contact_sheets/hud_mission_page.png`. Worst ratio 0.74.


## hud_trick_popup

Contact sheet: `contact_sheets/hud_trick_popup.png`. Worst ratio 0.74.


## hud_combo_broken

Contact sheet: `contact_sheets/hud_combo_broken.png`. Worst ratio 0.74.


## hud_run_start

Contact sheet: `contact_sheets/hud_run_start.png`. Worst ratio 0.74.


## time_up_screen

Contact sheet: `contact_sheets/time_up_screen.png`. Worst ratio 0.74.


## wreck

Contact sheet: `contact_sheets/wreck.png`. Worst ratio 0.74.


