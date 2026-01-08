enum GUI_LAYOUT {
    ACTION_TILE_W           = 120,
    ACTION_TILE_PADDING     = 20,
    PLAY_W					= 200,
    PLAY_H					= 100,
    DISCARD_W				= 200,
    DISCARD_H				= 220,
	BAG_W					= 120,
	BAG_H					= 130,
	BAG_X					= 60,
	BAG_Y					= 40,
}

// color definitions
global.color_intel = make_color_rgb(210, 210, 0);
global.color_attack = c_red;
global.color_block = make_color_rgb(30, 160, 255);
global.color_heal = c_lime;
global.color_debuff = c_white;
global.color_unknown = c_dkgray;
global.color_bg = make_color_rgb(20, 50, 80);

randomise();
credits = debug_mode ? 500 : 50;
generate_dice_bag();
define_buffs_and_debuffs();
define_enemies();
define_items();
define_events();

global.main_input_disabled = false; // allows you to interact with menus and the bag screen without affecting elements behind it
global.all_input_disabled = false; // prevents player from doing anything

global.player_max_hp = 40;
global.player_hp = global.player_max_hp;
global.player_alignment = 50;
global.hand_size = 5;
global.player_luck = 50; // used for reward generation
keepsakes = ds_list_create();
keepsake_scale = ds_list_create();
credits_scale = 1.0;
voyage = 0; // voyage act I to start with
depth = -100;

define_keepsakes();

ds_list_add(keepsakes, get_keepsake_by_id("looking_glass"));

global.keywords = {
    "Stowaway": {
        colour: c_aqua,
        desc: "Bonus effect when dice is left unplayed.",
		index: 0
    },

    "Favourite": {
        colour: c_lime,
        desc: "Always appears in your starting hand.",
		index: 1
    },

    "Coin": {
        colour: c_yellow,
        desc: "Doesn't count towards played dice total, bypasses size requirements for slot checks.",
		index: 2
    },

    "Multitype": {
        colour: c_silver,
        desc: "Has more than one action type.",
		index: 3
    },

    "Followthrough": {
        colour: c_red,
        desc: "Bonus effects when dice is rolled dependent on previous slots.",
		index: 4
    },

    "Exclusive": {
        colour: c_teal,
        desc: "This die cannot be played into a slot with other dice, or have other dice played into it.",
		index: 5
    },

    "Loose": {
        colour: c_ltgray,
        desc: "This die always ejects from its slot, regardless of permanence.",
		index: 6
    },

    "Sticky": {
        colour: c_dkgray,
        desc: "This die becomes permanent to the slot it is played.",
		index: 7
    },

    "Might": {
        colour: c_white,
        desc: "Boost Attacks by 1 per point of Might",
		index: 8
    },

    "Balance": {
        colour: c_white,
        desc: "Boost Blocks by 1 per point of Balance",
		index: 9
    }
};

global.tooltip_active = false;
global.tooltip_main = undefined; // main tooltip struct (only one allowed)
global.tooltip_keywords = [];    // list of keyword tooltip structs

max_items = 3;
items = [undefined, undefined, undefined];
items_hover = [];
items_hover_scale = [];
has_space_for_item = true;

if (debug_mode) {
	items[0] = clone_item(item_consumable_mirage_brew);
}
	
for (var i = 0; i < max_items; i++) {
	array_push(items_hover, 0);
	array_push(items_hover_scale, 1.0);
}

global.dice_safe_area_x1 = 4*(room_width/11);
global.dice_safe_area_x2 = 7*(room_width/11);
global.dice_safe_area_y1 = 3*(room_height/4);
global.dice_safe_area_y2 = room_height - 100;

global.player_debuffs = ds_list_create();
global.enemy_debuffs = ds_list_create();

/// oCombat Create Event
global.hovered_dice_id = noone;

turn_count = 1; // used to help favourtie dice come out of the bag at the workshop
dice_to_deal = 0;
dice_deal_timer = 0;
dice_deal_delay = 10; // frames between dice (at 60fps ~0.17s)
is_dealing_dice = false;
dice_dealt = false;

bonus_dice_next_combat = 0;

holding_item = false; // used for holding the hammer in the workbench, will eventually change cursor type, right now just blocks inputs in that room. Could also do it for dice.
show_consumables_chance = 30; // percentage chance to show consumables after any given fight

// player intel 
global.player_intel_data = ds_list_create();
ds_list_add(global.player_intel_data, {
	requirement: 0,
	name: "-",
	description: "No information revealed.",
	index: 0,
});
ds_list_add(global.player_intel_data, {
	requirement: 3,
	name: "I",
	description: "Target enemy intent revealed.",
	index: 1,
});
ds_list_add(global.player_intel_data, {
	requirement: 6,
	name: "II",
	description: "All enemy intents revealed & can change targets.",
	index: 2,
});
ds_list_add(global.player_intel_data, {
	requirement: 9,
	name: "III",
	description: "Drew an extra die this turn.",
	index: 3,
});
ds_list_add(global.player_intel_data, {
	requirement: 12,
	name: "IV",
	description: "+1 playable dice this turn.",
	index: 4,
});

show_dice_list = false; // used for displaying all the dice in the master list
show_dice_bag = false;
bag_hover = false;
bag_hover_locked = false; // used to click on the bag and lock the view
scroll_y = 0;
m_grab_y = 0;
s_grab_y = 0;
filtered_list = ds_list_create();
show_bag_dice_info = true;
dice_hover = undefined;

error_timer = 0;
error_message = "";
error_description = "";

active_bounty = undefined;

health_scale = 1.0; // changes every time the player heals or loses health outside of room combat
alignment_scale = 1.0;

tool_list = ds_list_create();
ds_list_add(tool_list, "hammer");

dice_selection = false; // set to a number when you want to select a certain number of dice to process an event for
dice_selection_message = "";
dice_selection_scale = 1.0; // used for the button
dice_selection_list = ds_list_create();
dice_selection_num_selected = 0;
dice_selection_event = undefined;
dice_selection_filter = "none";