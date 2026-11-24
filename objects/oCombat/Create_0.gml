// Lets the F1 debug menu choose the enemies for this fight (does nothing otherwise)
debug_apply_pending_fight();
tutorial_begin(); // the guided first fight, until the tutorial is done (progress.json)

turn_count = 0;

if (!ds_safe_exists(global.discard_pile, ds_type_list)) {
	global.discard_pile = ds_list_create();
} else {
	ds_list_clear(global.discard_pile);
}

if (!ds_safe_exists(global.sacrifice_list, ds_type_list)) {
	global.sacrifice_list = ds_list_create();
} else {
	ds_list_clear(global.sacrifice_list);
}

if (!ds_safe_exists(global.sacrifice_history, ds_type_list)) {
	global.sacrifice_history = ds_list_create();
} else {
	ds_list_clear(global.sacrifice_history);
}

// Create action queue, which is a list of structs, each containing a list of dice and other info
action_queue = ds_list_create();
locked_slot = -1;
bound_slot = -1;
mark_next = 0; // the next enemy letter and colour on the timeline (A, B, C...)
rot_spare = 0; // Rot: the odd point carried between the rotten slot's dice (process_action)
hovered_slot = -1;

// rolled dice: a fight starts with one empty slot. The first coloured die played into one picks its type for the turn
// (combat_new_slot has the slot's fields). docs/design-rolled-dice.md
// One slot to start (Jared, 2026-11-19): the rest are built, and slots fill left to right (slot_placement_check).
ds_list_add(action_queue, combat_new_slot("None"));
// each slot's place is worth a bonus to its total: +0 here, then +1, +2... for the ones you build (slot_set_position_bonus)
slot_set_position_bonus(action_queue[| 0], 0);

played_uids = [];              // dice played this turn (uid): "when played" effects fire once per die per turn, even if it's taken back and played again
rerolls_used = 0;              // rerolls this turn (right-click a die in hand, 3 insight each: combat_reroll_die)
redraws_used = 0;              // unused now: a redraw is paid as you discard (combat_discard_and_redraw)
overboard_dice = [];
// F242 content pass: counted each turn (reset in START_TURN) or for the fight
ink_max_bonus = 0;            // Inkpot dice played this fight: +2 max ink each (intel_max)
ink_actions_this_turn = 0;    // Calligrapher's die: ink actions taken this turn
min_rolls_this_turn = 0;      // dice that rolled their minimum this turn (die_roll_faces): Undertow die
coins_played_this_turn = 0;   // Purser's die
heal_on_full_block = 0;       // Tidepusher: heal this much each time your Block fully stops a hit this turn
block_carries = false;        // Defensive coin: your leftover Block carries into next turn // dice gone overboard this fight (F241): back in the bag when it's won (win_fight) or left (CleanUp)
take_back_request = undefined; // a played die clicked in Draw GUI, taken back in Step: { slot, index } (slot -1 = the new-slot tile)
new_tile_pos = undefined;      // where the new-slot tile is drawn (Draw GUI), for dice taken back from it

// Use fibonacci for determining new slot creation
global.fib_lookup = [0, 1, 1, 2, 3, 5, 8, 13, 21];
slot_cost_modifier = 0;

// For drawing buttons
tile_scale = ds_list_create();
reward_scale = ds_list_create();
reward_credits_hover = 1.0;
reward_next_hover = 1.0;
btn_scale = 1.0; // play button hover animation 
disc_btn_scale = 1.0; // discard button hover animation
last_action_scale = 1.0;
try_btn_scale = 1.0;
last_hover = false; // hovering over last button is false
disc_bag_hover = false; // the discard bag is hovered (set in Draw GUI, read earlier in the same event for its outline)

// Combat states
enum CombatState {
    START_TURN,
    PLAYER_INPUT,
    RESOLVE_ROUND,
	END_OF_ROUND,
	PLAYER_DEAD
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
dice_spin = 0; // resets every time we roll a die to animate the angle
action_delay_base = game_get_speed(gamespeed_fps) * 0.5; // time between actions at Normal combat speed (rolled dice: was 0.75, the numbers are known)
action_delay = action_delay_base * combat_delay_scale();
dice_index = 0;
dice_timer = 0;
dice_delay_base = game_get_speed(gamespeed_fps) * 0.4; // time between dice at Normal combat speed (rolled dice: was 0.75, no roll to watch)
dice_delay = dice_delay_base * combat_delay_scale();
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
quill_menu_enemy = undefined; // the enemy whose intent shows the Quill's Reroll / Halve choice
quill_btn_scales = [1, 1];
insight_revealed = false; // bought this turn: exact enemy intents (combat_buy)
ink_preview = 0;           // ink a hovered ink action would spend: its pips flicker (draw_ink_pips)
insight_view = false;     // the insight phase is open: the log, before you play (combat_insight_view_set / combat_insight_view_draw)
balance_next_turn = 0;      // Balance gained for next turn (Balanced die), applied as it starts (oCombat Step)
insight_phase_done = false; // this turn's start-of-turn check has run (the inkwell pulses if ink can do something)
ink_pulse = 0;              // frames left of the inkwell's start-of-turn pulse
ink_waiting = false;        // ink can do something and you haven't acted yet this turn: the inkwell keeps pulsing
quill_over = false;         // the log is open and the mouse is over something the quill can change (cursor_draw)
close_btn_scale = 1;
insight_view_age = 0;     // frames the view has been open (the opening click mustn't close it)
insight_surf = -1;
wet_surf = -1;            // the ink view's wet edge: a half-size mask of the ink things (wet_ink_draw)
wet_shapes = [];          // this frame's ink things, collected by wet_ink_rect / wet_ink_circle / wet_ink_poly
ink_strokes = [];         // doodles in the ink view, { pts: [[x, y, width]...], t } (ink_doodle_step / ink_doodles_draw)
ink_drawing = false;      // the left button is down drawing one
reward_item_burn = array_create(8, -1); // the item reward the first pick locked: how far it has burnt (0 to 1; -1 not yet)
aq_min_right = 0;          // the queue's right edge at its leftmost: enemies stand clear of it (enemy_layout_update)
aq_vis = 4;               // queue places in view: your slots, the one to build, locked ones up to four (Draw GUI)
ink_drag_enemy = undefined; // the enemy whose move is being dragged along the track in the ink view (combat_timeline_draw)
ink_drag_x = 0;
ink_writing_snd = -1;     // the looping quill sound while you draw (sfx_loop)
ink_pen_last = [0, 0];    // where the pen was last frame, and frames it hasn't moved
ink_pen_still = 0;
ink_costs = [];           // this frame's ink costs, drawn last, over the wet edge (ink_cost_pip, ink_costs_draw)
tokens_args = undefined;  // where the token row sits this frame ({ cx, right, y }), so the view can draw it again on top
reveal_btn_scale = 1;
rerolls_bought = 0;       // extra rerolls bought with insight this turn
redraws_bought = 0;       // extra redraws bought this turn
plays_bought = 0;         // extra plays bought this turn
intel_rewrite_used = false;// the Quill state lets you rewrite one enemy intent per turn
target_locked = false; // Overwhelm: you can't change target this turn
intel_scale = 1.0;
intel_alpha = 1.0;
is_discarding = false;
is_placing = false;

grabbed_amount = 0;
grabbed_value  = 0;
grabbed_type   = "";

dice_to_deal = 0;
dice_deal_timer = 0;
dice_deal_delay = 6; // frames between dice (at 60fps 0.1s; Jared 2026-11-22: quicker)
is_dealing_dice = false;
ejected_dice = false;
type_array = [];


// Enemies
room_enemies = ds_list_create();
fight_enemy_records = []; // every enemy that has been in this fight, used to free their lists in Clean Up

enemies_left_this_combat = ds_list_size(oWorldManager.room_enemies);

gui_w = display_get_gui_width();
gui_h = display_get_gui_height();

//show_debug_message("global ui scale: " + string(global.ui_scale));

define_combat_ui_sizes();

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
reward_auto_t = 0; // frames since this reward page's pick landed: it moves on by itself (oCombat Draw GUI)
pending_reward_die = undefined; // a reward die waiting to fly to the bag (made in Step)
player_hit_t = -100000;          // when you were last hit (a white flash on your ship)
player_death_t = -1;             // when you went down (lose_run): the ship keels over and sinks
reward_reveal_t = 0;
reward_keepsake_reveal_t = 0; // and the keepsake rewards (cards too, 2026-11-22)
reward_item_reveal_t = 0; // the same for the item rewards (they get the dice rewards' card design)// frames the dice rewards have been on show: they're dealt face down and flip one by one (F145)
rewards_consumables_first_taken = -1;
rewards_consumables_second_taken = false;
rewards_consumables_locked = -1;
rewards_credits_taken = false;
rewards_keepsake_taken = false;
rewards_all_taken = false;

dice_played = 0;
dice_allowed_per_turn_original = 4;
dice_allowed_per_turn = dice_allowed_per_turn_original;
dice_allowed_this_turn_bonus = 0;
dice_played_scale = 1;
dice_played_color = c_white;

combat_end_effects_triggered = false;

all_enemies_spared = true; // used for alignment fights, if this remains true at the end of combat, we don't show standard rewards, but instead something else...
spare_kill_alpha = 0;
insight_panel_open = false; // the insight eye is hovered: oRunManager draws the panel over the tutorial notes

