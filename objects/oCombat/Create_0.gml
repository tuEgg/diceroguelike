first_turn = true;

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

var new_slot1 = {
    dice_list: ds_list_create(),		// all dice currently in the slot
    current_action_type: "None",         // the slot's selected type
    possible_type: "None",				// allowed types,
	bonus_amount: 0				// bonus dice, on top of rolled dice - 1d4 + 2 for example
};

//ds_list_add(new_slot1.dice_list, clone_die(global.dice_d4_none, "base"));
ds_list_add(action_queue, new_slot1);

// Use fibonacci for determining new slot creation
global.fib_lookup = [0, 1, 1, 2, 3, 5, 8, 13, 21];
sacrificies_til_new_action_tile = ds_list_size(action_queue);

// For drawing buttons
tile_scale = ds_list_create();
reward_scale = ds_list_create();
reward_credits_hover = 1.0;
reward_skip_hover = 1.0;
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
action_delay = game_get_speed(gamespeed_fps) * 0.75; // half a second between actions
enemy_turn_done = false;

player_hp_display = global.player_hp;

global.enemy_x = display_get_gui_width() / 2 + 650;
global.enemy_y = display_get_gui_height() / 2 + 200;
global.player_x = display_get_gui_width() / 2 - 650;
global.player_y = global.enemy_y;

player_block_amount = 0;
enemy_block_amount = 0;
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

enemy = oWorldManager.room_enemy;

var rand_move = irandom(ds_list_size(enemy.moves) - 1);
enemy_intent = enemy.moves[| rand_move];

enemy_intent_alpha = 0;     // for fade in/out
enemy_intent_scale = 0.5;   // for pop animation
enemy_intent_color = c_white;
enemy_intent_text = "";     // current intent text
enemy_turns_since_last_block = 1;
move_number = -1;

// Enemy stats
enemy_max_hp = enemy.max_hp;
enemy_hp = debug_mode ? 1 : enemy.current_hp;
enemy_hp_display = enemy_hp; // for lerping animation
enemy_alpha = 1.0;

//show_debug_message("=== NEW COMBAT START ===");
//show_debug_message("Dice bag size: " + string(ds_list_size(global.dice_bag)));
//show_debug_message("Discard pile: " + string(ds_list_size(global.discard_pile)));
//show_debug_message("Sacrifice history: " + string(ds_list_size(global.sacrifice_history)));

show_rewards = false;
reward_options = undefined;
rewards_dice_taken = false;
rewards_credits_taken = false;
rewards_keepsake_taken = false;
reward_credits = enemy.bounty;
rewards_all_taken = false;

dice_played = 0;
dice_allowed_per_turn_original = 2;
dice_allowed_per_turn = dice_allowed_per_turn_original;
dice_allowed_this_turn_bonus = 0;
dice_played_scale = 1;
dice_played_color = c_white;