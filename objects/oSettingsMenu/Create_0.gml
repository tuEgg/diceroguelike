global.double_tap_last_key = undefined;
global.double_tap_timer = 0;

global.show_settings = false;

global.resolution_index = 2;

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
		
];

if (file_exists("settings.json")) {
	load_settings();
} else {
	save_settings();
}

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

global.ui_scale = display_get_gui_width() / 1920;