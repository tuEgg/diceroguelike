turn_count = 0;

if (!ds_exists(global.discard_pile, ds_type_list)) {
	global.discard_pile = ds_list_create();
} else {
	ds_list_clear(global.discard_pile);
}

if (!ds_exists(global.sacrifice_list, ds_type_list)) {
	global.sacrifice_list = ds_list_create();
} else {
	ds_list_clear(global.sacrifice_list);
}

if (!ds_exists(global.sacrifice_history, ds_type_list)) {
	global.sacrifice_history = ds_list_create();
} else {
	ds_list_clear(global.sacrifice_history);
}

// Create action queue, which is a list of structs, each containing a list of dice and other info
action_queue = ds_list_create();
locked_slot = -1;
bound_slot = -1;

var new_slot1 = {
    dice_list: ds_list_create(),			// all dice currently in the slot
    current_action_type: "None",			// the slot's selected type
    possible_type: "None",					// allowed types,
	bonus_amount: 0,						// bonus dice, on top of rolled dice - 1d4 + 2 for example
	buffed: 0,								// Whether or not this slot is buffed and if so, for how many turns, this decreases by 1 at the end of each round
	pre_buff_amount: 0						// Used to keep track of bonus_amount before we get buffed
};

//ds_list_add(new_slot1.dice_list, clone_die(global.dice_d4_none, "base"));
ds_list_add(action_queue, new_slot1);

// Use fibonacci for determining new slot creation
global.fib_lookup = [0, 1, 1, 2, 3, 5, 8, 13, 21];
sacrificies_til_new_action_tile = ds_list_size(action_queue);
slot_cost_modifier = 0;

// For drawing buttons
tile_scale = ds_list_create();
reward_scale = ds_list_create();
reward_credits_hover = 1.0;
reward_next_hover = 1.0;
btn_scale = 1.0; // play button hover animation 
disc_btn_scale = 1.0; // discard button hover animation
last_action_scale = 1.0;
last_hover = false; // hovering over last button is false

// Combat states
enum CombatState {
    START_TURN,
    PLAYER_INPUT,
    RESOLVE_ROUND,
	END_OF_ROUND
}

state = CombatState.START_TURN;

combat_feed = ds_list_create();
feed_queue  = ds_list_create();
feed_delay  = 2; // frames between messages (30 = ~0.5s at 60fps)
feed_timer  = 0;

function add_feed_entry(_text) {
    ds_list_add(feed_queue, _text);
}

function flush_feed_queue() {
    // Instantly move all queued messages to the feed (optional utility)
    while (ds_list_size(feed_queue) > 0) {
        var msg = ds_list_find_value(feed_queue, 0);
        ds_list_delete(feed_queue, 0);
        ds_list_add(combat_feed, msg);
    }
}

actions_submitted = false;

// For sequencing actions
action_index = 0;
action_timer = 0;
draw_action_index = 0;
draw_dice_index = 0;
action_delay = game_get_speed(gamespeed_fps) * 0.75; // time between actions
dice_index = 0;
dice_timer = 0;
dice_delay = game_get_speed(gamespeed_fps) * 0.75; // time between actions
enemies_turn_done = false;
enemy_turns_remaining = 0;
enemies_to_fade_out = false; // used to fade enemies out before processing end of turn
player_last_action_type = undefined;
player_turn_done = false; // for ending visuals on last die roll
delayed_enemy_attack = false; // used for delaying enemy turn after player turn 

player_hp_display = global.player_hp;

player_block_amount = 0;
player_intel = 0;
draw_intel = 0; // used to draw intel
intel_level = 0;
intel_scale = 1.0;
intel_alpha = 1.0;
is_discarding = false;
is_placing = false;

grabbed_amount = 0;
grabbed_value  = 0;
grabbed_type   = "";

dice_to_deal = 0;
dice_deal_timer = 0;
dice_deal_delay = 10; // frames between dice (at 60fps ~0.17s)
is_dealing_dice = false;
ejected_dice = false;
type_array = [];


// Enemies
room_enemies = ds_list_create();

enemies_left_this_combat = ds_list_size(oWorldManager.room_enemies);

global.enemy_x = display_get_gui_width() / 2 + 650 + (enemies_left_this_combat*110);
global.enemy_y = display_get_gui_height() / 2 + 200;
global.player_x = display_get_gui_width() / 2 - 650;
global.player_xstart = global.player_x;
global.player_y = global.enemy_y;

enemy_x_offset = -460 + (enemies_left_this_combat*80);
enemy_y_offset = -90;

for (var i = 0; i < enemies_left_this_combat; i++) {
	var _enemy = oWorldManager.room_enemies[| i];
	
	add_enemy_to_fight(_enemy);
}

enemy_target_index = 0; // by default the player is targeting enemy 1

//show_debug_message("=== NEW COMBAT START ===");
//show_debug_message("Dice bag size: " + string(ds_list_size(global.dice_bag)));
//show_debug_message("Discard pile: " + string(ds_list_size(global.discard_pile)));
//show_debug_message("Sacrifice history: " + string(ds_list_size(global.sacrifice_history)));

show_rewards = false;
rewards_stage = 1;
reward_list = ds_list_create();
reward_dice_options = undefined;
reward_consumable_options = undefined;
reward_keepsake_options = undefined;
rewards_dice_taken = false;
rewards_consumables_first_taken = -1;
rewards_consumables_second_taken = false;
rewards_consumables_locked = -1;
rewards_credits_taken = false;
rewards_keepsake_taken = false;
rewards_all_taken = false;

dice_played = 0;
dice_allowed_per_turn_original = 2;
dice_allowed_per_turn = dice_allowed_per_turn_original;
dice_allowed_this_turn_bonus = 0;
dice_played_scale = 1;
dice_played_color = c_white;

combat_end_effects_triggered = false;

all_enemies_spared = true; // used for alignment fights, if this remains true at the end of combat, we don't show standard rewards, but instead something else...
spare_kill_alpha = 0;