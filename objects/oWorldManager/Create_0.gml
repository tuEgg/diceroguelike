combat_nodes_this_voyage = 0;
event_nodes_this_voyage = 0;
workbench_nodes_this_voyage = 0;
shop_nodes_this_voyage = 0;
bounty_nodes_this_voyage = 0;
elite_nodes_this_voyage = 0;
alignment_nodes_this_voyage = 0;

nodes_cleared = 0; // how many nodes in the captains logbook have we cleared
pages_cleared = 0; // how many pages have we cleared
spreads_cleared = 0 // how many spreads have we cleared
chapter = 1; // which chapter of the logbook we are in, each ends with a boss
boss_page_placed = false; // has this chapter's boss spread been laid out yet
chapter_end_alpha = 0; // fades in the chapter complete screen
chapter_btn_scale = 1.0; // hover animation for the "Turn the page" button
nodes_til_page_cleared = 0; // resets every time we start a new page
time = 0; // used to pulse animate next node
page_previous = undefined;

enum NODE_TYPE {
	COMBAT = 0,
	WORKBENCH = 1,
	SOCIAL = 2,
	SHOP = 3,
	EVENT = 4,
	BOUNTY = 5,
	ELITE = 6,
	BOSS = 7,
	TREASURE = 8,
	ALIGNMENT = 9
}

room_enemies = ds_list_create();

pages_shown = ds_list_create();
page_scale = ds_list_create();
current_page_turn = 1;
ds_list_add(page_scale, 1.0);
ds_list_add(page_scale, 1.0);
ds_list_add(page_scale, 1.0);
// a little left of centre: each card has its sea stop to its right, laid out as it will be on the chart (B+)
// three landscape cards (option A), each holding its island and its sea stop
page_pos[0] = { x: display_get_gui_width() * 0.5 - 570, y: display_get_gui_height() * 0.56 }; // 500 wide, 70 apart
page_pos[1] = { x: display_get_gui_width() * 0.5, y: display_get_gui_height() * 0.56 };
page_pos[2] = { x: display_get_gui_width() * 0.5 + 570, y: display_get_gui_height() * 0.56 };
pages_alpha = 0; // used for fading out pages

node_combat = {
	type: NODE_TYPE.COMBAT,
	subimg: 0,
	name: "Combat",
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
	name: "Shop",
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
	name: "Event",
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
	name: "Workbench",
	text: "Upgrade dice at the workbench",
	linked_room: rmWorkbench,
	scale: 1.0,
	cleared: false,
	x: 0,
	y: 0,
	disappeared: false,
};

node_bounty = {
	type: NODE_TYPE.BOUNTY,
	subimg: 4,
	name: "Bounty",
	text: "Choose a bounty target",
	linked_room: rmBounty,
	scale: 1.0,
	cleared: false,
	x: 0,
	y: 0,
	disappeared: false,
};

node_elite = {
	type: NODE_TYPE.ELITE,
	subimg: 5,
	name: "Elite",
	text: "Fight a difficult enemy for great reward",
	linked_room: rmCombat,
	scale: 1.0,
	cleared: false,
	x: 0,
	y: 0,
	disappeared: false,
};

node_boss = {
	type: NODE_TYPE.BOSS,
	subimg: 6,
	name: "Boss",
	text: "Put your build to the test against the boss.",
	linked_room: rmCombat,
	scale: 1.0,
	cleared: false,
	x: 0,
	y: 0,
	disappeared: false,
};

node_treasure = {
	type: NODE_TYPE.TREASURE,
	subimg: 7,
	name: "Treasure",
	text: "Gain a relic",
	linked_room: rmTreasure,
	scale: 1.0,
	cleared: false,
	x: 0,
	y: 0,
	disappeared: false,
};

node_alignment = {
	type: NODE_TYPE.ALIGNMENT,
	subimg: 8,
	name: "Alignment Fight",
	text: "A moral battle that affects your alignment",
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
	spd: 0,
	entering: false, // sailing in from the book's left edge after Embark (oWorldManager Draw GUI)
	voyage: undefined, // the voyage it's on (boat_sail_toward)
	tilt: 0,           // how far it heels over while sailing (added to angle when drawn)
}
book_left_x = 262;  // the open book's water pages' outer edges this frame (oWorldManager Draw GUI): the courses into
book_right_x = 1658; // and out of a spread start and end there, and the ship sails in and out across them

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
choices_locked = false; // whether we've locked in both our page choices
nodes_til_drafting = 0;
pages_drafted = 0;
all_nodes = ds_list_create();
next_node = undefined;
node_drift = 0; // used for drifting the last node to the left, resets every time we click

enum WORLD_STATE {
	OPENING,
	DRAFTING,
	TURNING,
	EXPLORING,
	CHAPTER_END, // the boss is beaten, waiting for the player to turn to the next chapter
	STRAIT // the spread is done: its sea stops are on the map (strait_draw), then TURNING (added last so saved numbers keep their meaning)
}
world_state = WORLD_STATE.OPENING;

book_open_scale = 0;
page_turn_scale = 1;
// pick the paper art for each page of the book
generate_book_pages();

heal_scale_target = 2.0;
heal_scale = heal_scale_target;
workbench_scale_target = 2.0;
workbench_scale = workbench_scale_target;
resting_alpha = 0;
rest_amount = 0.30; // Calm water at the strait heals this share of your health (Q14)
strait = undefined;    // this spread end's sea stops (strait_build), while world_state is STRAIT
sea_buoy = undefined;  // the left page's sea stop between a spread's pages: its look and stamp (passage_left_draw, B+)
harbour = undefined;
map_waves = [];        // the little waves now and then on the water pages (map_waves_draw)   // the boss spread's harbour, rest or refit (harbour_draw, B+)

embark_scale = 1.0;
workbench_scale = 1.0;

possible_encounters = ds_list_create();
ds_list_add(possible_encounters, "Early 1");
ds_list_add(possible_encounters, "Early 2");
ds_list_add(possible_encounters, "Early 3");

// comment out the below when not testing
//if (debug_mode) {
//	ds_list_add(possible_encounters, "Encounter 1");
//	ds_list_add(possible_encounters, "Encounter 2");
//	ds_list_add(possible_encounters, "Encounter 3");
//	ds_list_add(possible_encounters, "Encounter 4");
//	ds_list_add(possible_encounters, "Encounter 5");
//	ds_list_add(possible_encounters, "Encounter 6");
//	ds_list_add(possible_encounters, "Encounter 7");
//}

possible_elites = ds_list_create();
elite_list_before_bounty = ds_list_create(); // for restoring remaining elite fights this voyage after a bounty
ds_list_add(possible_elites, "Elite 1");
ds_list_add(possible_elites, "Elite 2");
ds_list_add(possible_elites, "Elite 3");


possible_alignment_encounters = ds_list_create();
ds_list_add(possible_alignment_encounters, "Alignment 1");
current_node_type = undefined;
current_node = undefined; // the map node being played, it remembers what it rolled so Continue can bring it back

alarm[0] = 1; // used to delay drafting in cases where we click exit in another room 
can_draft = false;


combat_chance =		0;
event_chance =		0;
shop_chance =		0;
bounty_chance =		0;
elite_chance =		0;
alignment_chance =	0;

island_surf = -1; // used for tracking if we have created the surface to draw masked islands with
island_mask_surf = -1;

// Create
u_erode_texel  = shader_get_uniform(shErode, "u_texel");
u_erode_radius = shader_get_uniform(shErode, "u_radius");