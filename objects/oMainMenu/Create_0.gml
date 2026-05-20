global.main_input_disabled = false; // allows you to interact with menus and the bag screen without affecting elements behind it
global.all_input_disabled = false; // prevents player from doing anything
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
			room_goto(rmMap);
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