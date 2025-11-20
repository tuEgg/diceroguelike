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
ds_list_add(keepsakes, get_keepsake_by_id("message_in_a_bottle"));
ds_list_add(keepsakes, get_keepsake_by_id("eye_patch"));
ds_list_add(keepsakes, get_keepsake_by_id("anchor"));
ds_list_add(keepsakes, get_keepsake_by_id("ghost_lantern"));

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
	description: "A core that increase the odds of rolling higher numbers",
	type: "core",
	dragging: false
}

var test_item2 = {
	sprite: sCores,
	index: 1,
	name: "Karamjan Rum",
	description: "Dice rolls following this turn won't roll 1.",
	type: "consumable",
	dragging: false
}

for (var i = 0; i < max_items; i++) {
	array_push(items, choose(test_item1, test_item2));
	array_push(items_hover, 1.0);
}