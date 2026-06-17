enum UI_LAYER {
    BASE,
    POPUP,
    BAG,
    SETTINGS
}
global.ui_layer = UI_LAYER.BASE;
global.all_input_disabled = false;

global.loading_game = false;

active_menu_item = -1;

menu = [
	{
		title: "Continue",
		scale: 1,
		action: function() {
			global.loading_game = true;
			room_goto(rmMap);
		},
		flag: save_exists(1),
	},
	{
		title: "New Voyage",
		scale: 1,
		action: function() {
			start_run();
		},
		flag: true,
	},
	{
		title: "Settings",
		scale: 1,
		action: function() {
			global.show_settings = true;
		},
		flag: true,
	},
	{
		title: "Exit",
		scale: 1,
		action: function() {
			game_end();
		},
		flag: true,
	},
];

show_run_warning = false;
proceed_new_scale = 1;
cancel_new_scale = 1;