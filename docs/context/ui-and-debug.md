# UI helpers, display and the debug menu

## Drawing and input helpers: scHelpers

- `mouse_hovering(x, y, w, h, centred, hover_sound, click_sound, conditions, layer, id)`: returns false if `global.ui_layer` is above `layer` or input is disabled. Use it for anything clickable.
- `global.ui_layer` (enum `UI_LAYER` in `oMainMenu/Create_0`): `BASE, POPUP, BAG, SETTINGS, DEBUG`. Higher layers block lower ones.
- Tooltips: `queue_tooltip(x, y, name, desc, icon, index, die)` queues one per frame; `draw_all_tooltips()` draws it (called at the end of `oRunManager` Draw GUI End, `Draw_75`, so tooltips sit above every window) with keyword sub-tooltips found in the description. Titles stay on one line. Draw GUI End order: dice list, `tips_draw`, `insight_panel_draw`, `dragged_item_draw` (carried core/potion), `pause_draw`, `run_summary_draw`, then tooltips.
- Text: `draw_outline_text(str, outline, fill, width, x, y, scale, alpha, angle, max_width)`; `[tag]` colour markup via `colorcode_text`. Fonts `ftDefault`, `ftDescriptions`, `ftSmall`, `ftTiny`, `ftBig`, `ftBigger`, `ftDamage`.
- Buttons: `draw_gui_button(...)` returns `{ hover, click, ... }` (old, slated for replacement); `draw_wonky_rectangle` draws hand-drawn panels (caches surfaces, known leak, KANBAN T07).
- `throw_error(title, desc)` shows a red tooltip for ~1.5s.
- Bag view (`oRunManager/Draw_64`) and the debug dice list (`oRunManager/Draw_75`): each die box is edged in its rarity colour; scrollbars drag while `scroll_dragging` is true, which clears whenever the mouse button is up. Use GUI-space mouse positions (`device_mouse_y_to_gui`), never `mouse_y`, for anything drawn in Draw GUI.

## Display: scDisplay, scSettings

`apply_resolution()` sets window, surface, GUI and camera to `global.resolution_options[global.resolution_index]` (1080p, 1440p). `global.ui_scale = gui_w / 1920`; `global.gui` holds proportional sizes (`update_gui_layout`). Many rooms still use fixed 1080p numbers (KANBAN B83). Web builds (`IS_BROWSER`): `apply_resolution` hands over to `apply_browser_resolution` (always 1920x1080 inside, canvas fitted 16:9 into the page, refit by `browser_check_resize` from oSettingsMenu Step); no Resolution setting, no Exit button or double-Escape quit, fullscreen not restored at start-up. Export and smoke test: `docs/web-build.md`.

## Debug menu: scDebug, `oDebugger` (persistent, depth -10000)

- `DEBUG_TOOLS` macro: true when run from the IDE (`debug_mode || GM_build_type == "run"`). Everything below is off in exported builds.
- **F1** opens the panel (`global.dbg` holds its state); Escape closes it. Tabs: Run, Fight, Combat, Dice, Keepsakes, Items, Events, Rooms, Hotkeys. Widgets are immediate mode: `debug_button` returns true on click, `debug_label`, `debug_hovered` + `debug_tip` for hover tooltips (drawn by the menu itself, on top).
- **Hotkeys** (`debug_hotkeys`, menu closed): Space kill all and end turn, Backspace take 20, H heal, D draw, N complete spread, F2/F3/F4 speed x1/x2/x4. Older letter keys in `oRunManager/Step_0` (R, C, L, A, S, E, B, T, W, X, G, Q) also use `DEBUG_TOOLS`.
- **Hooks the game calls** (each does nothing unless the menu asked): `debug_apply_pending_fight` (oCombat Create), `debug_take_next_die` (deal_single_die), `debug_take_forced_event_index` (generate_event), `debug_turn_intel` (turn start), `debug_skip_intro` (oCutsceneManager Create).
- `debug_settings.json` keeps `skip_intro` between sessions.
- Leaving a fight via the menu restores the bag from `bag_snapshot`.
- The enemy and event name lists at the top of `debug_menu_init` are typed by hand: add new enemies and events there too.
