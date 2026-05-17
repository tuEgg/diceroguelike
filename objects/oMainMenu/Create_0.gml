global.main_input_disabled = false; // allows you to interact with menus and the bag screen without affecting elements behind it
global.all_input_disabled = false; // prevents player from doing anything
global.loading_game = false;

active_menu_item = -1;
menu_scale = [1, 1, 1, 1];
menu_titles = ["Continue", "New Game", "Settings", "Exit"];
menu_actions = [
	function() {
		global.loading_game = true;
		room_goto(rmMap);
	},
	function() {
		room_goto(rmMap);
	},
	function() {
		
	},
	function() {
		game_end();
	},
];
menu_active = [save_exists(1), true, true, true];
