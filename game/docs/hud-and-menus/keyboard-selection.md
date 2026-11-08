# Keyboard selection (T-573)

Nothing looks selected when a menu opens (docs/hud-and-menus.md, Content, "Nothing is selected when a screen opens").

## How
`KeyNav` (`game/scripts/ui/key_nav.gd`) has the shared parts:
- `clear_selection(owner)`: releases the focus if it is inside `owner`. Screens call it when they open or come back from a sub-page, instead of `grab_focus()`.
- `reveal_selection(event, owner, start, accept_presses)`: with nothing selected inside `owner`, the first fresh press of an arrow, Tab, W, A, S or D selects `start` and marks the key used. Enter or Space does the same, or, when `accept_presses` is true, presses `start`. It does nothing when `start` is hidden or takes no focus.
- `handle_keys(event, owner, start, accept_presses)`: `reveal_selection`, then the W, A, S, D walk (`handle_wasd`). Screens call it from `_unhandled_key_input`.

## Screens
| Screen | Start button | Enter or Space with nothing selected |
|---|---|---|
| Main menu | Start | presses Start |
| Garage | first Buy shown (Back if none) | selects it |
| Cosmetics | first action shown (Back if none) | selects it |
| Settings | Back | selects it |
| Tutorial slides | Go live (last slide), right arrow (others); none on trick slides | presses it |
| Pause screen | Resume | selects it |
| Trick list | Back | selects it |
| God mode page | Back | selects it |
| HUD layout editor | Done | selects it |

The garage and Cosmetics still hand the selection on when the selected button hides (a maxed Buy, a picked effect): that only happens when the player had selected it.

Tests: `game/tests/unit/test_no_preselected_button.gd`.
