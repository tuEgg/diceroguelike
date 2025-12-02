pages_turned = 0; // how many pages in the captains logbook have we cleared
time = 0; // used to pulse animate next node
page_previous = undefined;

enum PAGE_TYPE {
	COMBAT = 0,
	WORKBENCH = 1,
	SOCIAL = 2,
	SHOP = 3,
	EVENT = 4,
	BOSS = 5
}

room_enemy = undefined;

pages_shown = ds_list_create();
page_scale = ds_list_create();
page_pos[0] = { x: display_get_gui_width() * 3/4 - 200, y: display_get_gui_height() * 2.2/7 };
page_pos[1] = { x: display_get_gui_width() * 3/4 + 200, y: display_get_gui_height() * 2.2/7 };
page_pos[2] = { x: display_get_gui_width() * 3/4, y: display_get_gui_height() * 4.7/7 };

combat_chance = 60;
event_chance = 30;
workbench_chance = 5;
shop_chance = 5;

node_combat = {
	type: PAGE_TYPE.COMBAT,
	subimg: 0,
	text: "Fight against enemies to earn rewards",
	linked_room: rmCombat,
	scale: 1.0,
	cleared: false,
};

node_shop = {
	type: PAGE_TYPE.SHOP,
	subimg: 2,
	text: "Trade at port",
	linked_room: rmShop,
	scale: 1.0,
	cleared: false,
};

node_event = {
	type: PAGE_TYPE.EVENT,
	subimg: 1,
	text: "Take a chance on a random event",
	linked_room: rmEvent,
	scale: 1.0,
	cleared: false,
};

node_workbench = {
	type: PAGE_TYPE.WORKBENCH,
	subimg: 3,
	text: "Upgrade dice at the workbench",
	linked_room: rmWorkbench,
	scale: 1.0,
	cleared: false,
};

node_boss = {
	type: PAGE_TYPE.BOSS,
	subimg: 0,
	text: "Put your build to the test against the boss.",
	linked_room: rmCombat,
	scale: 1.0,
	cleared: false,
};

generate_pages();

boat_data = {
	x: 300,
	y: display_get_gui_height()/2,
	angle: 0
}

map_position = {
	x: 0,
	y: 0,
}

circle_list = ds_list_create();
node_x[0] = 0;
node_y[0] = 0;
node_x[1] = 0;
node_y[1] = 0;
node_x[2] = 0;
node_y[2] = 0;

chosen_pages = ds_list_create();
choices_locked = false;

embark_scale = 1.0;