randomise();
credits = 0;
generate_dice_bag();
define_buffs_and_debuffs();
enemy_definitions();

global.player_max_hp = 30;
global.player_hp = global.player_max_hp;
keepsakes = ds_list_create();
keepsake_scale = ds_list_create();
keepsakes_master = ds_list_create();
voyage = 0; // voyage act I to start with
depth = -100;

define_keepsakes();

global.keywords = {
    "Stowaway": {
        colour: c_aqua,
        desc: "Bonus effect when dice is left unplayed",
		index: 0
    },

    "Favourite": {
        colour: c_lime,
        desc: "Always appears in your starting hand",
		index: 1
    },

    "Coin": {
        colour: c_yellow,
        desc: "Doesn't count towards played dice total, bypasses size requirements for slot checks.",
		index: 2
    },

    "Multitype": {
        colour: c_silver,
        desc: "Has more than one action type",
		index: 3
    },

    "Followthrough": {
        colour: c_red,
        desc: "Bonus effects dependent on previous slot type",
		index: 4
    }
};

//ds_list_add(keepsakes, get_keepsake_by_id("lucky_coin"));
//ds_list_add(keepsakes, get_keepsake_by_id("message_in_a_bottle"));
//ds_list_add(keepsakes, get_keepsake_by_id("eye_patch"));
//ds_list_add(keepsakes, get_keepsake_by_id("anchor"));
//ds_list_add(keepsakes, get_keepsake_by_id("ghost_lantern"));

global.tooltip_active = false;
global.tooltip_main = undefined; // main tooltip struct (only one allowed)
global.tooltip_keywords = [];    // list of keyword tooltip structs

max_items = 3;
items = [];
items_hover = [];

var test_item1 = {
	sprite: sCores,
	index: 0,
	name: "Weighted Core",
	description: "A core that increases the odds of rolling higher numbers",
	type: "core",
	dragging: false,
	distribution: "weighted"
}

var test_item2 = {
	sprite: sCores,
	index: 1,
	name: "Loaded Core",
	description: "A core that greatly increases the odds of rolling higher numbers",
	type: "core",
	dragging: false,
	distribution: "loaded"
} 

array_push(items, test_item1);
array_push(items, test_item2);
	
for (var i = 0; i < max_items; i++) {
	array_push(items_hover, 1.0);
}

global.dice_safe_area_x1 = 4*(room_width/11);
global.dice_safe_area_x2 = 7*(room_width/11);
global.dice_safe_area_y1 = 3*(room_height/4);
global.dice_safe_area_y2 = room_height - 100;

global.player_debuffs = ds_list_create();
global.enemy_debuffs = ds_list_create();

/// oCombat Create Event
global.hovered_dice_id = noone;

first_turn = true; // used to help favourtie dice come out of the bag at the workshop
dice_to_deal = 0;
dice_deal_timer = 0;
dice_deal_delay = 10; // frames between dice (at 60fps ~0.17s)
is_dealing_dice = false;
dice_dealt = false;

holding_item = false; // used for holding the hammer in the workbench, will eventually change cursor type, right now just blocks inputs in that room. Could also do it for dice.