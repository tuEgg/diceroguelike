global.double_tap_last_key = undefined;
global.double_tap_timer = 0;

global.show_settings = false;

global.resolution_index = 0;
global.custom_cursor = true; // Settings > Display > Custom cursor (cursor_draw)
global.action_icons = false; // off by default (Jared, 2026-11-22): action glyphs on dice are a Settings option. // Settings > Display > Action icons on dice (draw_action_type_icon), for telling types apart without colour
global.cursor_hidden = false;
global.cursor_hover_time = 0;
global.cursor_tilt = 0;
global.shake_on = true; // Settings > Gameplay > Screen shake (screen_shake)
global.combat_speed_index = 1; // Settings > Gameplay > Combat speed: Slow, Normal, Fast, Fastest (F13)

global.resolution_options = [
    //{ w: 1280, h: 720 },
    //{ w: 1600, h: 900 },
    { w: 1920, h: 1080 },
    { w: 2560, h: 1440 },
];

settings_changed = false; // used to change text from "cancel" to "save changes"

category_index = 0;
save_scale = 1;
cancel_scale = 1;
quit_scale = 1;
starting_mouse_x = undefined;

categories = [
    {
        name: "Audio",
		scale: 1,
        settings: [
            {
                name: "Master Volume",
                type: "slider",
                get_value: function() { return global.vol_master; },
                set_value: function(_val) { global.vol_master = _val; },
                min_val: 0,
                max_val: 1,
				dragging: false,
            },
            {
                name: "UI Volume",
                type: "slider",
                get_value: function() { return global.vol_ui; },
                set_value: function(_val) { global.vol_ui = _val; },
                min_val: 0,
                max_val: 1,
				dragging: false,
            },
            {
                name: "SFX Volume",
                type: "slider",
                get_value: function() { return global.vol_sfx; },
                set_value: function(_val) { global.vol_sfx = _val; },
                min_val: 0,
                max_val: 1,
				dragging: false,
            },
            {
                name: "Music Volume",
                type: "slider",
                get_value: function() { return global.vol_music; },
                set_value: function(_val) { global.vol_music = _val; },
                min_val: 0,
                max_val: 1,
				dragging: false,
            },
            {
                name: "Mute",
                type: "toggle",
                get_value: function() { return global.muted; },
                set_value: function(_val) { global.muted = _val; },
            },
        ]
    },
    {
        name: "Display",
		scale: 1,
        settings: [
            {
                name: "Action icons on dice",
                type: "toggle",
                get_value: function() { return global.action_icons; },
                set_value: function(_val) { global.action_icons = _val; },
            },
            {
                name: "Custom cursor",
                type: "toggle",
                get_value: function() { return global.custom_cursor; },
                set_value: function(_val) { global.custom_cursor = _val; },
            },
            {
                name: "Fullscreen",
                type: "toggle",
                get_value: function() { return window_get_fullscreen(); },
                set_value: function(_val) { window_set_fullscreen(_val); },
            },
            {
                name: "Resolution",
                type: "dropdown",
                get_value: function() { return global.resolution_index; },
                set_value: function(_val) { global.resolution_index = _val; apply_resolution(); },
                //options: ["1280x720", "1600x900", "1920x1080", "2560x1440"],
				options: ["1920x1080", "2560x1440"],
				show_options: false
            },
        ]
    },
    {
        name: "Gameplay",
		scale: 1,
        settings: [
            {
                name: "Tutorial next run",
                type: "toggle",
                get_value: function() { return !progress_get("tutorial_done"); },
                set_value: function(_val) { progress_set_tutorial(_val); }, // saved straight away, separate from Save/Cancel
            },
            {
                name: "Intro next run",
                type: "toggle",
                get_value: function() { return !progress_get("intro_seen"); },
                set_value: function(_val) {
					// saved straight away (progress.json); the cutscene manager is already alive, so tell it too
					progress_set("intro_seen", !_val);
					if (instance_exists(oCutsceneManager)) oCutsceneManager.cutscenes[0].seen = !_val || debug_mode; // never in a debug run (F6)
				},
            },
            {
                name: "Combat speed",
                type: "dropdown",
                get_value: function() { return global.combat_speed_index; },
                set_value: function(_val) { global.combat_speed_index = _val; },
				options: ["Slow", "Normal", "Fast", "Fastest"],
				show_options: false
            },
            {
                name: "Screen shake",
                type: "toggle",
                get_value: function() { return global.shake_on; },
                set_value: function(_val) { global.shake_on = _val; if (!_val) global.shake = 0; },
            },
        ]
    },
		
];

// a web build has no resolution choice: it always fits the page (apply_browser_resolution)
if (IS_BROWSER) array_delete(categories[1].settings, 3, 1); // Resolution (after Action icons, Custom cursor, Fullscreen)

if (file_exists("settings.json")) {
	load_settings();
}

// what this player has seen (intro, tutorial, tips), kept apart from runs
progress_load();

depth = -10000;

// used for smoothing out drawn lines, particularly from our wonky rectangles function
global.button_cache = ds_map_create();


// color definitions
global.color_intel = make_color_rgb(210, 210, 0);
global.color_attack = c_red;
global.color_block = make_color_rgb(30, 160, 255);
global.color_heal = c_lime;
global.color_debuff = c_white;
global.color_unknown = c_dkgray;
global.color_bg = make_color_rgb(20, 50, 80);
global.color_error = make_color_rgb(140, 10, 10);
ui_init(); // the logbook palette (scUI): replaces the action pigments above with its brightness ladder

// button colours, by role (red/blue/green/yellow stay for attack/block/heal/insight only)
global.ui_primary = make_color_rgb(46, 150, 90);	// the main "go" action on a screen (Embark, Resume, Save, Back to the menu)
global.ui_neutral = make_color_rgb(128, 96, 64);	// ordinary choices and leaving (Exit, Continue, Settings)
global.ui_danger = make_color_rgb(150, 42, 42);		// can't be undone or costs you (abandon a run, Kill)
global.ui_quiet = make_color_rgb(70, 66, 80);		// secondary, skippable (Skip tutorial)

global.ui_scale = display_get_gui_width() / 1920;

// smooth edges on everything drawn in code (pips, badges, icons, panels): the best multisample anti-aliasing the
// graphics card offers (desktop; the web build has none to set), and rounder circles than the default 24 segments
var _aa = 0;
if (display_aa & 8) _aa = 8; else if (display_aa & 4) _aa = 4; else if (display_aa & 2) _aa = 2;
if (_aa > 0 && !IS_BROWSER) display_reset(_aa, false); // vsync stays off, as in the Windows options
draw_set_circle_precision(64);