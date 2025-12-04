pages_turned = 0; // how many pages in the captains logbook have we cleared
time = 0; // used to pulse animate next node
page_previous = undefined;

enum NODE_TYPE {
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
ds_list_add(page_scale, 1.0);
ds_list_add(page_scale, 1.0);
ds_list_add(page_scale, 1.0);
page_pos[0] = { x: display_get_gui_width() * 3/4 - 200, y: display_get_gui_height() * 2.2/7 };
page_pos[1] = { x: display_get_gui_width() * 3/4 + 200, y: display_get_gui_height() * 2.2/7 };
page_pos[2] = { x: display_get_gui_width() * 3/4, y: display_get_gui_height() * 4.7/7 };

node_combat = {
	type: NODE_TYPE.COMBAT,
	subimg: 0,
	text: "Fight against enemies to earn rewards",
	linked_room: rmCombat,
	scale: 1.0,
	cleared: false,
	x: 0,
	y: 0,
	disappeared: false,
};

node_shop = {
	type: NODE_TYPE.SHOP,
	subimg: 2,
	text: "Trade at port",
	linked_room: rmShop,
	scale: 1.0,
	cleared: false,
	x: 0,
	y: 0,
	disappeared: false,
};

node_event = {
	type: NODE_TYPE.EVENT,
	subimg: 1,
	text: "Take a chance on a random event",
	linked_room: rmEvent,
	scale: 1.0,
	cleared: false,
	x: 0,
	y: 0,
	disappeared: false,
};

node_workbench = {
	type: NODE_TYPE.WORKBENCH,
	subimg: 3,
	text: "Upgrade dice at the workbench",
	linked_room: rmWorkbench,
	scale: 1.0,
	cleared: false,
	x: 0,
	y: 0,
	disappeared: false,
};

node_boss = {
	type: NODE_TYPE.BOSS,
	subimg: 0,
	text: "Put your build to the test against the boss.",
	linked_room: rmCombat,
	scale: 1.0,
	cleared: false,
	x: 0,
	y: 0,
	disappeared: false,
};

boat_data = {
	x: 300,
	y: display_get_gui_height()/2,
	angle: 0,
	base_y: display_get_gui_height()/2,
	spd: 0
}

// The absolute position in the world of the map
map_position = {
	x: 0,
	y: 0,
}

// The difference in position between the maps absolute position and the nodes absolute position, set only when choosing a destination or arriving at one
map_offset = {
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
node_to_move_to = undefined;
last_node = undefined;

chosen_pages = ds_list_create();
choices_locked = false;
nodes_til_drafting = 0;
pages_drafted = 0;
all_nodes = ds_list_create();
next_node = undefined;
node_drift = 0; // used for drifting the last node to the left, resets every time we click

embark_scale = 1.0;