update_gui_layout();

global.heal_pos = 0;

randomise();
credits = 50; // the same in debug runs (F1 > Run can add gold when testing)
generate_dice_bag();
define_buffs_and_debuffs();
define_enemies();
define_items();
define_events();

fullscreen = false;

global.player_max_hp = 60; // Q11 (2026-11-19): more health, enemies hit harder (ENEMY_ATTACK_BOOST)
global.player_hp = global.player_max_hp;
global.player_alignment = 50;
global.alignment_stage = 0;
global.hand_size = 6;
global.player_luck = 50; // used for reward generation
keepsakes = ds_list_create();
keepsake_scale = ds_list_create();
credits_scale = 1.0;
credits_heard = credits; // the gold the coin sound last knew of (Step): a change jingles
global.shake = 0;                 // screen shake, px (screen_shake): decays in Step, applied in Draw GUI Begin
global.particles_pending = [];    // particle bursts asked for from Draw GUI (particle_emit_later), made in Step
coin_tick_cd = 0;// frames until the next coin clink may play (the trickle)
coin_streak = 0;        // clinks in this haul: each one a little higher
coin_streak_idle = 0;   // frames since gold last came in
voyage = 0; // voyage act I to start with
depth = -100;

dutchman_taken = false; // used for the bonuses granted by the flying dutchman event.

define_keepsakes();

ds_list_add(keepsakes, get_keepsake_by_id("looking_glass"));

// icon_on: where a die shows the keyword's icon (draw_dice_keywords): "hand" (dice you're about to play), "slot" (dice
// in the queue). Elsewhere the words do the job: a card's or tooltip's description starts with the keyword. Coin and
// Multitype show in the die itself (a round coin, split colours); Favourite only matters as the hand is dealt.
global.keywords = {
    "Stowaway": {
        colour: c_aqua,
        desc: "Bonus effect when left unplayed.",
		index: 0,
		icon_on: ["hand"]
    },

    "Favourite": {
        colour: c_lime,
        desc: "Always appears in your starting hand.",
		index: 1,
		icon_on: []
    },

    "Coin": {
        colour: c_yellow,
        desc: "Doesn't use a play.",
		index: 2,
		icon_on: []
    },

    "Multitype": {
        colour: c_silver,
        desc: "Has more than one action type.",
		index: 3,
		icon_on: []
    },

    "Followthrough": {
        colour: c_red,
        desc: "Bonus effect that depends on earlier slots.",
		index: 4,
		icon_on: ["hand"]
    },

    "Exclusive": {
        colour: c_teal,
        desc: "Clears its slot when played. No other dice can join it, and it can't build a slot.",
		index: 5,
		icon_on: ["hand"]
    },

"Sticky": {
        colour: c_dkgray,
        desc: "Stays in its slot one extra turn and acts again.",
		index: 7,
		icon_on: ["hand", "slot"]
    },

    "Overboard": {
        colour: make_color_rgb(70, 130, 180),
        desc: "Gone for the rest of the fight after its slot acts.",
		index: 10, // drawn in code (draw_keyword_icon), like the others
		icon_on: ["hand", "slot"]
    },

    "Might": {
        colour: c_white,
        desc: "Attacks get +1 per Might.",
		index: 8
    },

    "Balance": {
        colour: c_white,
        desc: "Blocks get +1 per Balance.",
		index: 9
    }
};

global.COLOR_RULES = [
    { tag: "gold",			keyword: "gold",			type: "num_keyword" },
    { tag: "alignment",		keyword: "alignment",		type: "num_keyword" },
    { tag: "luck",			keyword: "luck",			type: "num_keyword" },
    { tag: "luck",			keyword: "lucky",			type: "num_keyword" },
    { tag: "block",			keyword: "block",			type: "num_keyword" },
    { tag: "block",			keyword: "BLK",				type: "num_keyword" },
    { tag: "heal",			keyword: "heal",			type: "num_keyword" },
    { tag: "attack",		keyword: "attack",			type: "num_keyword" },
    { tag: "attack",		keyword: "ATK",				type: "num_keyword" },
    { tag: "intel",			keyword: "intel",			type: "num_keyword" },
    { tag: "intel",			keyword: "ink",			type: "num_keyword" }, // "Insight" is what the player reads; the code still says intel
    { tag: "followthrough",	keyword: "followthrough",	type: "num_keyword" },
    { tag: "multitype",		keyword: "multitype",		type: "num_keyword" },
    { tag: "coin",			keyword: "coin",			type: "num_keyword" },
    { tag: "stowaway",		keyword: "stowaway",		type: "num_keyword" },
    { tag: "favourite",		keyword: "favourite",		type: "num_keyword" },
    { tag: "exclusive",		keyword: "exclusive",		type: "num_keyword" },
    { tag: "loose",			keyword: "loose",			type: "num_keyword" },
    { tag: "sticky",		keyword: "sticky",			type: "num_keyword" },
    { tag: "alignment",		keyword: "alignment",		type: "num_keyword" },
    // NOTE: "health" is handled as a special case below
];

global.color_common = make_colour_rgb(52, 55, 73);
global.color_uncommon = make_colour_rgb(42, 90, 85);
global.color_rare = make_colour_rgb(85, 42, 90);

global.tooltip_active = false;
global.tooltip_main = undefined; // main tooltip struct (only one allowed)
global.tooltip_keywords = [];    // list of keyword tooltip structs
global.total_tooltip_height = 0; // used to track total tooltip height

max_items = 3;
items = [undefined, undefined, undefined];
items_hover = [];
items_hover_scale = [];
has_space_for_item = true;
	
for (var i = 0; i < max_items; i++) {
	array_push(items_hover, 0);
	array_push(items_hover_scale, 1.0);
}

global.dice_safe_area_x1 = 4*(display_get_gui_width()/11);
global.dice_safe_area_x2 = 7*(display_get_gui_width()/11);
global.dice_safe_area_y1 = 3*(display_get_gui_height()/4);
global.dice_safe_area_y2 = display_get_gui_height() - 100;

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

// insight (player_intel): points you spend during your turn (Jared, 2026-11-19): see exact intents 2, an extra reroll
// or redraw 3, an extra play 4, a Quill rewrite 6 (the INSIGHT_COST_ macros, scEnemies). Below 0 the page is Blotted.
// These are the eye's two looks (sIntelEye frames): ranges, and exact numbers once you've paid to see them.
global.player_intel_data = ds_list_create();
ds_list_add(global.player_intel_data, {
	requirement: 0,
	name: "Ink",
	description: "Enemy intents show a range.",
	index: 1,
});
ds_list_add(global.player_intel_data, {
	requirement: 0,
	name: "Ink",
	description: "Enemy intents show exact numbers.",
	index: 2,
});
global.intel_blotted = {
	name: "Blotted",
	description: "Below 0 ink, enemy intents are hidden.",
	index: 0,
};

show_dice_list = false; // used for displaying all the dice in the master list
bag_hover = false;
show_bag_contents = false; // used to click on the bag and lock the view
bag_to_show = global.dice_bag;
bag_title = "";
pre_bag_open_ui_layer = UI_LAYER.BASE; // used for restoring the correct UI layer once the bag is closed
pre_settings_open_ui_layer = UI_LAYER.BASE; // same as above but for settings
scroll_y = 0;
scroll_dragging = false; // is the bag or dice list scrollbar being dragged
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
dice_selection_age = 0; // frames the dice picker has been open: its opening click can't pick a die (Draw GUI End)
dice_selection_list = ds_list_create();
dice_selection_num_selected = 0;
dice_selection_event = undefined;
dice_selection_filter = "none";
pending_item = undefined; // an item waiting for a free slot (the wreck with full slots: pending_item_draw)
rooms_since_fight = 0;    // island stops in a row with no fight (enter_node; pages_ensure_fights; saved)
shipwright_wait = 0;      // spreads in a row offered with a core held and no Shipwright (pages_assign_passages; saved)
ink_plus_found = false;   // "+1" drawn in ink has paid out this run (ink_egg_plus_one; saved)
ink_neow_found = false;   // "neow" written in ink has paid out this run (ink_egg_neow; saved)
ink_egg_found = false;    // the triangle drawn in ink has paid out this run (ink_egg_check; saved)
dice_selection_up_to = false; // true: Confirm works with any number up to dice_selection (the workbench)

tools = ds_list_create();

tool_hammer = {
	name: "The Hammer",
	desc: "Smash two dice into one.",
	index: 0, // index for the silhouette sprite
	sprite: sHammer,
	price: 150,
	object: oHammer
}


tool_drill = {
	name: "The Drill",
	desc: "Drill a new core into a die.",
	index: 2, // index for the silhouette sprite
	sprite: sDrill,
	price: 125,
	object: oDrill
}

tool_scissors = {
	name: "The Cutters",
	desc: "Cut two faces off a die.",
	index: 1, // index for the silhouette sprite
	sprite: sScissors,
	price: 165,
	object: oScissors
}

// the Bin (2026-11-24): throws a die out of your bag for good. Drawn in code (draw_bin_icon) until Jared's sprite
tool_bin = {
	name: "The Bin",
	desc: "Remove a die from your bag.",
	index: -1, // no silhouette frame: drawn in code
	sprite: -1,
	price: 100,
	object: noone,
	kind: "bin"
}
tools_bought = 0; // tools bought in shops this run: the next costs 100, 150, 200 (tool_price; saved)

ds_list_add(tools, tool_drill); // a run starts with only the Drill; the Hammer, Cutters and Bin are bought in shops (master_tool_list)

tools_scale = ds_list_create();
ds_list_add(tools_scale, 0.5);

show_tools = false;
toolbag_scale = 1.0;

global.master_tool_list = ds_list_create();
ds_list_add(global.master_tool_list, tool_hammer);
ds_list_add(global.master_tool_list, tool_scissors);
ds_list_add(global.master_tool_list, tool_bin);

bag_clip_surf = -1;    // the bag view's cards, cut to its panel (Draw GUI End, F157)
ink_scene = -1;        // the log's ink look (F118): the frame drawn into a surface while the log is open (Draw GUI Begin)
ink_capturing = false; // this frame is going into ink_scene (set in Draw GUI Begin, reset first thing in Draw GUI End)
can_visit_workbench = false; // "At sea": set when a page's island is done; the map offers the workbench once (F02)
at_sea_scales = [1, 1];

// Check if we are loading
alarm[0] = 1;

// Used for offering a dice and core at the start of a new run
new_run_offering = false;

// F05/F35: stats for the end-of-voyage summary (saved with the run), the pause menu, and the summary itself
run_stats = run_stats_new();
run_over = undefined; // { won, cause, alpha, btn_scale } once the voyage has ended (run_end)
paused = false;
pre_pause_ui_layer = UI_LAYER.BASE;
pause_scales = [1, 1, 1];
cog_scale = 1; // the top bar's menu cog
alignment_popup_text = ""; // gain_alignment: "+5 merciful" under the compass for a moment
alignment_popup_col = c_white;
alignment_popup_t = -1;    // frames since it appeared (-1: none)
bag_sort = 0;        // bag view order: 0 bag order, 1 type, 2 size, 3 rarity, 4 name (bag_view_list)
bag_filter = "All"; // bag view type filter
bag_btn_scales = [1, 1, 1, 1, 1, 1, 1];
cog_turn = 0;
//global.ui_layer = UI_LAYER.POPUP;

// Populate offerings with a random dice and random core pairing
offering = [];
var consumable_options = ds_list_create();
generate_item_rewards(consumable_options, global.master_item_list, 3, "core");
					
var dice_options = ds_list_create();
generate_dice_rewards(dice_options, global.master_dice_list, 3);

// a core does nothing on a coin, so any coin offered is swapped for another die (not one already on offer)
for (var i = 0; i < ds_list_size(dice_options); i++) {
	if (dice_options[| i].dice_value != 2) continue;
	var _swap = [];
	for (var m = 0; m < ds_list_size(global.master_dice_list); m++) {
		var _cand = global.master_dice_list[| m];
		if (_cand.dice_value == 2) continue;
		var _dupe = false;
		for (var k = 0; k < ds_list_size(dice_options); k++) if (dice_options[| k].name == _cand.name) _dupe = true;
		if (!_dupe) array_push(_swap, _cand);
	}
	if (array_length(_swap) > 0) dice_options[| i] = clone_die(_swap[irandom(array_length(_swap) - 1)], "");
}

for (var i = 0; i < 3; i++) {
	var random_core = consumable_options[| i];
	var random_die = dice_options[| i];

	offering[i] = {
		core: random_core,
		dice: random_die,
		core_scale: 1,
		dice_scale: 1,
		bg_scale: 1,
		lift: 0, // the card rising on hover / when chosen
	}
}
offer_selected = -1;   // which card is chosen (-1: none yet); the button takes it
offer_btn_scale = 1;

ds_list_destroy(dice_options);
ds_list_destroy(consumable_options);