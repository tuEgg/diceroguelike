// Debug tools only exist when the game is run from the IDE, never in an exported build
#macro DEBUG_TOOLS (debug_mode || GM_build_type == "run")

function trace() {
	/// trace(...values)
	var r = string(argument[0]), i;
	for (i = 1; i < argument_count; i++) {
	    r += ", " + string(argument[i]);
	}
	show_debug_message(r);
}

// =====================================================================
// DEBUG MENU (F1)
// State lives in global.dbg, created by oDebugger. The game reads a few
// of these values through the small debug_* hooks at the bottom.
// =====================================================================

/// Create the debug state. Called once from oDebugger Create.
function debug_menu_init() {
	global.dbg = {
		open: false,
		tab: 0,
		scroll: 0,
		prev_ui_layer: UI_LAYER.BASE,

		tabs: ["Run", "Fight", "Combat", "Dice", "Keepsakes", "Items", "Events", "Rooms", "Hotkeys"],

		// Fight builder
		enemy_names: ["Deckhand", "Baby Kraken", "Seagull", "Thug", "Pirate Ruffian", "Parrot", "Peg-leg", "Elizabeak", "Bill",
			"Pufferfish", "Corsair Gunner", "Turtle", "Barrel o' Fish", "Driftnet Fish", "Pirate Captain", "Giant Conch", "Barnacle Titan"],
		fight_picks: [],			// enemy names in the fight being built
		fight_type: 0,				// index into fight_types
		fight_types: [
			{ name: "Normal",		node_type: NODE_TYPE.COMBAT },
			{ name: "Elite",		node_type: NODE_TYPE.ELITE },
			{ name: "Alignment",	node_type: NODE_TYPE.ALIGNMENT },
			{ name: "Boss",			node_type: NODE_TYPE.BOSS },
		],
		pending_fight: undefined,	// { names, node_type } picked up by oCombat when it is created

		// Events
		event_names: ["Pirate Prisoner", "A Great Storm", "Clear skies", "Broken sails", "Dividing up the bounty", "A Hidden Trunk",
			"Some old loot", "Spare Ammunition", "A bird flies aboard", "The Wishing Well", "An island dream", "The Flying Dutchman",
			"Rough tides", "The constellation", "A precious ingot", "The Siren's Call"],
		forced_event: "",			// name of the event the next event room must show

		// Dice
		dice_to_hand: false,		// false = add to bag, true = deal straight to hand (combat only)
		next_dice: [],				// dice structs the next deals will hand out instead of drawing from the bag
		bag_snapshot: undefined,	// the bag as it was when the current fight started

		// Combat
		turn_intel: 0,				// intel granted at the start of every turn

		// Misc
		base_speed: game_get_speed(gamespeed_fps),
		speed_multiplier: 1,
		message: "",
		message_timer: 0,
		clicked: false,				// was the left mouse button pressed this frame (set while drawing)
		hover_tip: undefined,		// { name, desc, icon, index, dice } for whatever list entry the mouse is over

		// Kept between sessions in debug_settings.json (see debug_settings_save)
		skip_intro: true,			// skip the intro cutscene when the game is run from GameMaker
	};

	debug_settings_load();
}

/// Debug settings live in their own small file, next to the save, so they survive restarts.
function debug_settings_load() {
	if (!file_exists("debug_settings.json")) return;
	try {
		var _file = file_text_open_read("debug_settings.json");
		var _settings = json_parse(file_text_read_string(_file));
		file_text_close(_file);
		if (variable_struct_exists(_settings, "skip_intro")) global.dbg.skip_intro = _settings.skip_intro;
	} catch (_error) {
		show_debug_message("Couldn't read debug_settings.json: " + string(_error));
	}
}

function debug_settings_save() {
	var _file = file_text_open_write("debug_settings.json");
	file_text_write_string(_file, json_stringify({ skip_intro: global.dbg.skip_intro }));
	file_text_close(_file);
}

/// oCutsceneManager Create: should the intro count as already seen? Only ever true when run from GameMaker.
function debug_skip_intro() {
	if (!DEBUG_TOOLS) return false;
	return global.dbg.skip_intro;
}

/// Show a short confirmation line at the bottom of the menu.
function debug_say(_text) {
	global.dbg.message = _text;
	global.dbg.message_timer = game_get_speed(gamespeed_fps) * 2.5;
	show_debug_message("[debug menu] " + _text);
}

/// Are we inside a run (the run and world managers exist)?
function debug_in_run() {
	if (instance_exists(oRunManager) && instance_exists(oWorldManager)) return true;
	debug_say("Start a run first");
	return false;
}

function debug_menu_open() {
	var dbg = global.dbg;
	dbg.open = true;
	dbg.prev_ui_layer = global.ui_layer;
	global.ui_layer = UI_LAYER.DEBUG; // blocks hovers and clicks on the game underneath
}

/// @param _reset_layer  true after jumping rooms, so we never carry a popup layer into the new room
function debug_menu_close(_reset_layer = false) {
	var dbg = global.dbg;
	dbg.open = false;
	global.ui_layer = _reset_layer ? UI_LAYER.BASE : dbg.prev_ui_layer;
}

/// Called every step from oDebugger.
function debug_menu_step() {
	if (!DEBUG_TOOLS) exit;

	var dbg = global.dbg;

	if (keyboard_check_pressed(vk_f1)) {
		if (dbg.open) debug_menu_close(); else debug_menu_open();
	}

	if (dbg.open) {
		// Escape closes the menu, and is used up so the settings menu doesn't also open this frame
		if (keyboard_check_pressed(vk_escape)) {
			keyboard_clear(vk_escape);
			debug_menu_close();
			exit;
		}
		
		// Other code may change the layer while we're open (escape, popups), remember it and keep ours on top
		if (global.ui_layer != UI_LAYER.DEBUG) {
			dbg.prev_ui_layer = global.ui_layer;
			global.ui_layer = UI_LAYER.DEBUG;
		}

		if (mouse_wheel_up())	dbg.scroll = max(0, dbg.scroll - 3);
		if (mouse_wheel_down())	dbg.scroll += 3;
	}

	// F2 / F3 / F4: game speed x1 / x2 / x4, any time
	if (keyboard_check_pressed(vk_f2)) debug_set_speed(1);
	if (keyboard_check_pressed(vk_f3)) debug_set_speed(2);
	if (keyboard_check_pressed(vk_f4)) debug_set_speed(4);
	
	if (!dbg.open) debug_hotkeys();

	if (dbg.message_timer > 0) dbg.message_timer--;
}

/// The testing shortcut keys, listed on the Hotkeys tab. Only when run from GameMaker, and never during a cutscene.
function debug_hotkeys() {
	if (global.all_input_disabled) exit;

	var in_run = instance_exists(oRunManager) && instance_exists(oWorldManager);
	if (!in_run) exit;

	var in_combat = (room == rmCombat && instance_exists(oCombat));

	// Space: kill every enemy and finish the fight
	if (keyboard_check_pressed(vk_space) && in_combat) {
		debug_kill_all_and_end_turn();
	}

	// Backspace: the first enemy hits you for 20
	if (keyboard_check_pressed(vk_backspace) && in_combat && ds_list_size(oCombat.room_enemies) > 0) {
		with (oCombat) process_action("player", 0, 20, 0, room_enemies[| 0], -1, "ATK");
	}

	// H: heal to full
	if (keyboard_check_pressed(ord("H"))) {
		global.player_hp = global.player_max_hp;
	}

	// D: draw a die
	if (keyboard_check_pressed(ord("D")) && in_combat) {
		oCombat.dice_to_deal += 1;
		oCombat.is_dealing_dice = true;
	}

	// N: complete this spread (on the map)
	if (keyboard_check_pressed(ord("N")) && room == rmMap) {
		debug_complete_spread();
	}
}

/// Kill every enemy, then end the turn if the player is mid-turn, so the fight wraps up on its own.
function debug_kill_all_and_end_turn() {
	if (!instance_exists(oCombat)) exit;

	for (var i = 0; i < ds_list_size(oCombat.room_enemies); i++) {
		debug_kill_enemy(oCombat.room_enemies[| i]);
	}

	with (oCombat) {
		if (state == CombatState.PLAYER_INPUT && !is_dealing_dice && !show_rewards) actions_submitted = true;
	}
}

/// Called on every room start from oDebugger.
function debug_menu_room_start() {
	if (!DEBUG_TOOLS) exit;

	// Remember the bag as the fight begins, so abandoning a fight through the menu can't lose dice
	if (room == rmCombat) {
		debug_snapshot_bag();
	} else {
		global.dbg.bag_snapshot = undefined;
	}
}

function debug_snapshot_bag() {
	var _snapshot = [];
	for (var i = 0; i < ds_list_size(global.dice_bag); i++) {
		array_push(_snapshot, clone_die(global.dice_bag[| i], ""));
	}
	global.dbg.bag_snapshot = _snapshot;
}

/// Leaving a fight part-way through would lose every die in hand, in slots and in the discard pile.
/// Put the bag back to how it was when the fight started.
function debug_restore_bag_if_abandoning_fight() {
	var dbg = global.dbg;

	if (room != rmCombat || dbg.bag_snapshot == undefined) exit;
	if (!instance_exists(oCombat) || oCombat.show_rewards) exit; // fight already won, dice are back in the bag

	ds_list_clear(global.dice_bag);
	for (var i = 0; i < array_length(dbg.bag_snapshot); i++) {
		ds_list_add(global.dice_bag, dbg.bag_snapshot[i]);
	}
	dbg.bag_snapshot = undefined;
	dbg.next_dice = [];
}

/// Jump to a room from anywhere in a run.
function debug_goto_room(_room) {
	if (!debug_in_run()) exit;
	
	// a jump isn't a map node, so nothing should be remembered against one
	oWorldManager.current_node = undefined;

	debug_restore_bag_if_abandoning_fight();
	debug_menu_close(true);
	room_goto(_room);
}

/// Start a fight against the given enemy names.
function debug_start_fight(_names, _node_type) {
	if (!debug_in_run()) exit;

	if (array_length(_names) == 0) {
		debug_say("Pick at least one enemy");
		exit;
	}

	debug_restore_bag_if_abandoning_fight();
	oWorldManager.current_node = undefined; // not a map node

	// oCombat picks this up as it is created (leaving a fight clears the enemy list, so we can't fill it here)
	var _copy = [];
	array_copy(_copy, 0, _names, 0, array_length(_names));
	global.dbg.pending_fight = { names: _copy, node_type: _node_type };

	debug_menu_close(true);
	room_goto(rmCombat);
}

/// Give a die to the bag, or deal it straight to the hand when in combat.
function debug_give_die(_die_struct) {
	if (!debug_in_run()) exit;

	var dbg = global.dbg;

	if (dbg.dice_to_hand && room == rmCombat && instance_exists(oCombat)) {
		array_push(dbg.next_dice, _die_struct);
		oCombat.dice_to_deal += 1;
		oCombat.is_dealing_dice = true;
		debug_say("Dealt " + _die_struct.name + " to hand (joins your bag after the fight)");
	} else {
		ds_list_add(global.dice_bag, clone_die(_die_struct, ""));

		// keep the snapshot in step, so the die survives abandoning the fight
		if (dbg.bag_snapshot != undefined) array_push(dbg.bag_snapshot, clone_die(_die_struct, ""));

		debug_say("Added " + _die_struct.name + " to bag");
	}
}

/// Does the player own this keepsake? Returns its index in oRunManager.keepsakes, or -1.
function debug_keepsake_index(_keepsake) {
	for (var i = 0; i < ds_list_size(oRunManager.keepsakes); i++) {
		if (oRunManager.keepsakes[| i]._id == _keepsake._id) return i;
	}
	return -1;
}

/// Deal lethal damage to one enemy, through the normal damage code so death effects fire.
function debug_kill_enemy(_enemy) {
	if (_enemy == undefined || _enemy.dead) exit;

	with (oCombat) {
		_enemy.block_amount = 0;
		// exactly enough to kill, a huge number would be drawn screen-sized
		process_action(_enemy, 0, max(1, _enemy.hp), 0, "player", -1, "ATK", 0, global.dice_d4_atk, 1);
	}
}

// ---------------------------------------------------------------------
// Drawing. Simple immediate-mode widgets: draw it and get back whether it was clicked.
// ---------------------------------------------------------------------

/// @returns {bool} true if this button was clicked this frame
function debug_button(_x, _y, _w, _h, _label, _highlight = false, _enabled = true) {
	var mx = device_mouse_x_to_gui(0);
	var my = device_mouse_y_to_gui(0);
	var _hover = _enabled && (mx >= _x && mx < _x + _w && my >= _y && my < _y + _h);

	var _col = make_color_rgb(52, 58, 70);
	if (_highlight)	_col = make_color_rgb(40, 120, 80);
	if (_hover)		_col = make_color_rgb(90, 110, 160);

	draw_set_alpha(_enabled ? 1.0 : 0.4);
	draw_set_color(_col);
	draw_rectangle(_x, _y, _x + _w - 2, _y + _h - 2, false);

	draw_set_color(c_white);
	draw_set_halign(fa_left);
	draw_set_valign(fa_middle);
	draw_text(_x + 8, _y + _h/2, _label);
	draw_set_alpha(1.0);

	return _hover && global.dbg.clicked;
}

/// @returns {bool} is the mouse over this rectangle
function debug_hovered(_x, _y, _w, _h) {
	var mx = device_mouse_x_to_gui(0);
	var my = device_mouse_y_to_gui(0);
	return (mx >= _x && mx < _x + _w && my >= _y && my < _y + _h);
}

/// Show a tooltip for a list entry. The game's own tooltips are drawn underneath this menu, so the menu draws its own.
function debug_tip(_name, _desc, _icon = undefined, _index = 0, _dice = undefined) {
	global.dbg.hover_tip = { name: _name, desc: _desc, icon: _icon, index: _index, dice: _dice };
}

function debug_label(_x, _y, _text, _col = c_white) {
	draw_set_color(_col);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_text(_x, _y, _text);
}

/// Called from oDebugger Draw GUI.
function debug_menu_draw() {
	if (!DEBUG_TOOLS) exit;

	var dbg = global.dbg;
	if (!dbg.open) exit;

	var gui_w = display_get_gui_width();
	var gui_h = display_get_gui_height();

	dbg.clicked = mouse_check_button_pressed(mb_left);
	dbg.hover_tip = undefined;

	draw_set_font(ftDefault);
	var row_h = string_height("Ag") + 12;

	// Panel
	var px = 20;
	var py = 20;
	var pw = min(gui_w - 40, max(780, gui_w * 0.45));
	var ph = gui_h - 40;
	var pad = 14;

	draw_set_alpha(0.92);
	draw_set_color(make_color_rgb(18, 20, 26));
	draw_rectangle(px, py, px + pw, py + ph, false);
	draw_set_alpha(1.0);

	debug_label(px + pad, py + pad, "DEBUG MENU   (F1 or Escape to close, mouse wheel to scroll)", c_yellow);

	// Tabs down the left side
	var tab_w = 150;
	var tab_x = px + pad;
	var tab_y = py + pad + row_h + 6;

	for (var t = 0; t < array_length(dbg.tabs); t++) {
		if (debug_button(tab_x, tab_y + t * row_h, tab_w, row_h, dbg.tabs[t], dbg.tab == t)) {
			dbg.tab = t;
			dbg.scroll = 0;
		}
	}

	// Content area
	var cx = tab_x + tab_w + pad;
	var cy = tab_y;
	var cw = px + pw - pad - cx;
	var ch = py + ph - pad - row_h - cy; // leave a row at the bottom for the message line
	var max_rows = floor(ch / row_h);
	var half_w = floor(cw / 2);
	var third_w = floor(cw / 3);
	var quarter_w = floor(cw / 4);

	var in_run = instance_exists(oRunManager) && instance_exists(oWorldManager);
	var in_combat = in_run && room == rmCombat && instance_exists(oCombat);

	switch (dbg.tabs[dbg.tab]) {

		// -------------------------------------------------------------
		case "Hotkeys":
			var yy = cy;

			debug_label(cx, yy + 6, "Skip the intro cutscene when run from GameMaker:");
			yy += row_h;
			if (debug_button(cx, yy, half_w, row_h, dbg.skip_intro ? "Skipping (click to play it)" : "Playing (click to skip it)", dbg.skip_intro)) {
				dbg.skip_intro = !dbg.skip_intro;
				debug_settings_save();
				// takes effect on the next run, or right away if a run hasn't reached the map yet
				if (instance_exists(oCutsceneManager)) oCutsceneManager.cutscenes[0].seen = dbg.skip_intro;
				if (!dbg.skip_intro) progress_set("intro_seen", false); // so it plays again on the next launch too
				debug_say(dbg.skip_intro ? "The intro will be skipped" : "The intro will play when a run reaches the map");
			}
			yy += row_h * 1.5;

			var keys = [
				["F1 / Escape",	"Open and close this menu"],
				["F2 / F3 / F4", "Game speed x1 / x2 / x4"],
				["Space",		"Kill all enemies and finish the fight"],
				["Backspace",	"An enemy hits you for 20"],
				["H",			"Heal to full"],
				["D",			"Draw a die (in a fight)"],
				["N",			"Complete this spread (on the map)"],
				["R",			"Restart the game"],
				["C / L / A",	"Go to a normal / elite / alignment fight"],
				["S / E / B / T / W / X", "Shop / event / bounty / treasure / workbench / map"],
				["G",			"Gain every keepsake"],
				["Q",			"Show the dice in your bag"],
			];
			debug_label(cx, yy, "Hotkeys (only when run from GameMaker, with this menu closed)", c_yellow);
			yy += row_h;
			for (var k = 0; k < array_length(keys); k++) {
				debug_label(cx, yy, keys[k][0], c_aqua);
				debug_label(cx + third_w, yy, keys[k][1]);
				yy += row_h;
			}
		break;

		// -------------------------------------------------------------
		case "Run":
			if (!in_run) {
				debug_label(cx, cy, "Start a run first.");
				break;
			}

			var yy = cy;

			debug_label(cx, yy + 6, "HP  " + string(global.player_hp) + " / " + string(global.player_max_hp));
			yy += row_h;
			if (debug_button(cx,				yy, quarter_w, row_h, "-10"))		global.player_hp = max(1, global.player_hp - 10);
			if (debug_button(cx + quarter_w,	yy, quarter_w, row_h, "+10"))		global.player_hp = min(global.player_max_hp, global.player_hp + 10);
			if (debug_button(cx + quarter_w*2,	yy, quarter_w, row_h, "Full"))		global.player_hp = global.player_max_hp;
			if (debug_button(cx + quarter_w*3,	yy, quarter_w, row_h, "Set to 1"))	global.player_hp = 1;
			yy += row_h;
			if (debug_button(cx,				yy, quarter_w, row_h, "Max -10")) {
				global.player_max_hp = max(1, global.player_max_hp - 10);
				global.player_hp = min(global.player_hp, global.player_max_hp);
			}
			if (debug_button(cx + quarter_w,	yy, quarter_w, row_h, "Max +10"))	global.player_max_hp += 10;
			yy += row_h * 1.5;

			debug_label(cx, yy + 6, "Gold  " + string(oRunManager.credits));
			yy += row_h;
			if (debug_button(cx,				yy, quarter_w, row_h, "+100"))		oRunManager.credits += 100;
			if (debug_button(cx + quarter_w,	yy, quarter_w, row_h, "+1000"))		oRunManager.credits += 1000;
			if (debug_button(cx + quarter_w*2,	yy, quarter_w, row_h, "Set to 0"))	oRunManager.credits = 0;
			yy += row_h * 1.5;

			debug_label(cx, yy + 6, "Alignment  " + string(global.player_alignment) + "  (0 to 100)");
			yy += row_h;
			if (debug_button(cx,				yy, quarter_w, row_h, "-10"))		global.player_alignment = clamp(global.player_alignment - 10, 0, 100);
			if (debug_button(cx + quarter_w,	yy, quarter_w, row_h, "+10"))		global.player_alignment = clamp(global.player_alignment + 10, 0, 100);
			if (debug_button(cx + quarter_w*2,	yy, quarter_w, row_h, "Set to 50"))	global.player_alignment = 50;
			yy += row_h * 1.5;

			debug_label(cx, yy + 6, "Luck  " + string(global.player_luck) + "  (50 is normal)");
			yy += row_h;
			if (debug_button(cx,				yy, quarter_w, row_h, "-10"))		global.player_luck -= 10;
			if (debug_button(cx + quarter_w,	yy, quarter_w, row_h, "+10"))		global.player_luck += 10;
			if (debug_button(cx + quarter_w*2,	yy, quarter_w, row_h, "Set to 50"))	global.player_luck = 50;
			yy += row_h * 1.5;

			debug_label(cx, yy + 6, "Insight at the start of every turn  " + string(dbg.turn_intel));
			yy += row_h;
			var intel_steps = [-3, 0, 5, 10]; // Blotted, Faded, Legible, Quill
			var intel_w = floor(cw / array_length(intel_steps));
			for (var i = 0; i < array_length(intel_steps); i++) {
				if (debug_button(cx + intel_w * i, yy, intel_w, row_h, string(intel_steps[i]), dbg.turn_intel == intel_steps[i])) {
					dbg.turn_intel = intel_steps[i];
				}
			}
			yy += row_h * 1.5;

			debug_label(cx, yy + 6, "Chapter " + string(oWorldManager.chapter) + "   spread " + string(oWorldManager.spreads_cleared + 1) + " of " + string(CHAPTER_SPREADS + 1) + " (the last is the boss)");
			yy += row_h;
			if (debug_button(cx, yy, half_w, row_h, "Make the next spread the boss")) {
				oWorldManager.spreads_cleared = CHAPTER_SPREADS;
				debug_say("The boss appears when the next spread starts");
			}
			if (debug_button(cx + half_w, yy, half_w, row_h, "Complete this spread")) {
				debug_complete_spread();
			}
			yy += row_h * 1.5;
			
			debug_label(cx, yy + 6, "Game speed  x" + string(dbg.speed_multiplier));
			yy += row_h;
			var speed_steps = [0.5, 1, 2, 4];
			for (var i = 0; i < array_length(speed_steps); i++) {
				if (debug_button(cx + quarter_w * i, yy, quarter_w, row_h, "x" + string(speed_steps[i]), dbg.speed_multiplier == speed_steps[i])) {
					debug_set_speed(speed_steps[i]);
				}
			}
		break;

		// -------------------------------------------------------------
		case "Fight":
			if (!in_run) {
				debug_label(cx, cy, "Start a run first.");
				break;
			}

			var yy = cy;

			// Current line-up
			var lineup = "Line-up: ";
			if (array_length(dbg.fight_picks) == 0) lineup += "(click enemies below, up to 3)";
			for (var i = 0; i < array_length(dbg.fight_picks); i++) {
				lineup += (i > 0 ? " + " : "") + dbg.fight_picks[i];
			}
			debug_label(cx, yy + 6, lineup, c_aqua);
			yy += row_h;

			// Fight type
			for (var i = 0; i < array_length(dbg.fight_types); i++) {
				if (debug_button(cx + quarter_w * i, yy, quarter_w, row_h, dbg.fight_types[i].name, dbg.fight_type == i)) dbg.fight_type = i;
			}
			yy += row_h;

			if (debug_button(cx, yy, half_w, row_h, "START FIGHT", true, array_length(dbg.fight_picks) > 0)) {
				debug_start_fight(dbg.fight_picks, dbg.fight_types[dbg.fight_type].node_type);
			}
			if (debug_button(cx + half_w, yy, half_w, row_h, "Clear line-up")) dbg.fight_picks = [];
			yy += row_h * 1.5;

			// Enemy list, two columns
			for (var i = 0; i < array_length(dbg.enemy_names); i++) {
				var col = i mod 2;
				var row = i div 2;
				if (debug_button(cx + half_w * col, yy + row * row_h, half_w, row_h, dbg.enemy_names[i])) {
					if (array_length(dbg.fight_picks) < 3) {
						array_push(dbg.fight_picks, dbg.enemy_names[i]);
					} else {
						debug_say("A fight holds 3 enemies at most");
					}
				}
			}
		break;

		// -------------------------------------------------------------
		case "Combat":
			if (!in_combat) {
				debug_label(cx, cy, "Only works during a fight.");
				break;
			}

			var yy = cy;

			if (debug_button(cx, yy, half_w, row_h, "Kill targeted enemy")) {
				debug_kill_enemy(oCombat.room_enemies[| oCombat.enemy_target_index]);
				debug_say("Killed the targeted enemy");
			}
			if (debug_button(cx + half_w, yy, half_w, row_h, "Kill all enemies (win)")) {
				debug_kill_all_and_end_turn();
				debug_say("Killed all enemies");
			}
			yy += row_h;

			if (debug_button(cx, yy, half_w, row_h, "All enemies to 1 HP")) {
				for (var i = 0; i < ds_list_size(oCombat.room_enemies); i++) {
					var enemy = oCombat.room_enemies[| i];
					if (!enemy.dead) enemy.hp = 1;
				}
			}
			if (debug_button(cx + half_w, yy, half_w, row_h, "Strip enemy block")) {
				for (var i = 0; i < ds_list_size(oCombat.room_enemies); i++) {
					oCombat.room_enemies[| i].block_amount = 0;
				}
			}
			yy += row_h * 1.5;

			if (debug_button(cx, yy, half_w, row_h, "Draw 1 die")) {
				oCombat.dice_to_deal += 1;
				oCombat.is_dealing_dice = true;
			}
			if (debug_button(cx + half_w, yy, half_w, row_h, "+1 die playable this turn")) {
				oCombat.dice_allowed_this_turn_bonus += 1;
			}
			yy += row_h;

			if (debug_button(cx, yy, half_w, row_h, "+20 block")) {
				oCombat.player_block_amount += 20;
			}
			if (debug_button(cx + half_w, yy, half_w, row_h, "Clear my buffs and debuffs")) {
				ds_list_clear(global.player_debuffs);
			}
			yy += row_h * 1.5;

			// Live read-out
			debug_label(cx, yy, "Turn " + string(oCombat.turn_count)
				+ "   Insight " + string(oCombat.player_intel) + " (" + string(intel_state(oCombat.intel_level).name) + ")"
				+ "   Dice played " + string(oCombat.dice_played) + " / " + string(oCombat.dice_allowed_per_turn));
			yy += row_h;
			debug_label(cx, yy, "Bag " + string(ds_list_size(global.dice_bag))
				+ "   Discard " + string(ds_list_size(global.discard_pile))
				+ "   Slots " + string(ds_list_size(oCombat.action_queue)));
			yy += row_h;

			for (var i = 0; i < ds_list_size(oCombat.room_enemies); i++) {
				var enemy = oCombat.room_enemies[| i];
				var line = enemy.data.name + "   HP " + string(enemy.hp) + "/" + string(enemy.max_hp) + "   Block " + string(enemy.block_amount);
				if (enemy.dead) line += "   (dead)";
				if (!enemy.dead) line += "   Next: " + enemy.intent.move.move_name;

				for (var d = 0; d < ds_list_size(enemy.debuffs); d++) {
					var buff = enemy.debuffs[| d];
					line += "   [" + buff.template.name + " x" + string(buff.amount) + (buff.permanent ? " perm" : " " + string(buff.remaining) + "t") + "]";
				}
				debug_label(cx, yy, line, i == oCombat.enemy_target_index ? c_yellow : c_white);
				yy += row_h;
			}

			var my_buffs = "You:";
			for (var d = 0; d < ds_list_size(global.player_debuffs); d++) {
				var buff = global.player_debuffs[| d];
				my_buffs += "   [" + buff.template.name + " x" + string(buff.amount) + (buff.permanent ? " perm" : " " + string(buff.remaining) + "t") + "]";
			}
			debug_label(cx, yy, my_buffs, c_lime);
		break;

		// -------------------------------------------------------------
		case "Dice":
			if (!in_run) {
				debug_label(cx, cy, "Start a run first.");
				break;
			}

			var yy = cy;

			debug_label(cx, yy + 6, "Clicking a die gives it to:");
			yy += row_h;
			if (debug_button(cx,			yy, half_w, row_h, "Bag", !dbg.dice_to_hand))								dbg.dice_to_hand = false;
			if (debug_button(cx + half_w,	yy, half_w, row_h, "Hand right now (in a fight)", dbg.dice_to_hand))		dbg.dice_to_hand = true;
			yy += row_h * 1.5;

			// Every die the game defines: rewards, starters and alignment dice
			var all_dice = [];
			var sources = [global.master_dice_list, global.starter_dice_list, global.alignment_dice_list];
			for (var s = 0; s < array_length(sources); s++) {
				var source_list = sources[s];
				for (var i = 0; i < ds_list_size(source_list); i++) array_push(all_dice, source_list[| i]);
			}

			var list_rows = max(1, floor((cy + ch - yy) / row_h));
			var per_page = list_rows * 2;
			dbg.scroll = clamp(dbg.scroll, 0, max(0, ceil(array_length(all_dice) / 2) - list_rows));

			var first = dbg.scroll * 2;
			for (var i = first; i < min(array_length(all_dice), first + per_page); i++) {
				var die = all_dice[i];
				var slot = i - first;
				var label = die.name + "   d" + string(die.dice_value) + " " + string(die.possible_type);
				var bx = cx + half_w * (slot mod 2);
				var by = yy + (slot div 2) * row_h;
				if (debug_hovered(bx, by, half_w, row_h)) debug_tip(die.name, die_description(die), sDiceIcon, get_dice_index(die.dice_value), die);
				if (debug_button(bx, by, half_w, row_h, label)) {
					debug_give_die(die);
				}
			}
		break;

		// -------------------------------------------------------------
		case "Keepsakes":
			if (!in_run) {
				debug_label(cx, cy, "Start a run first.");
				break;
			}

			var yy = cy;

			debug_label(cx, yy + 6, "Click to gain. Click a green one to remove it.");
			yy += row_h;
			if (debug_button(cx, yy, half_w, row_h, "Remove all keepsakes")) {
				ds_list_clear(oRunManager.keepsakes);
				debug_say("Removed all keepsakes");
			}
			yy += row_h * 1.5;

			var total = ds_list_size(global.master_keepsake_list);
			var list_rows = max(1, floor((cy + ch - yy) / row_h));
			var per_page = list_rows * 2;
			dbg.scroll = clamp(dbg.scroll, 0, max(0, ceil(total / 2) - list_rows));

			var first = dbg.scroll * 2;
			for (var i = first; i < min(total, first + per_page); i++) {
				var keepsake = global.master_keepsake_list[| i];
				var slot = i - first;
				var owned_index = debug_keepsake_index(keepsake);

				var bx = cx + half_w * (slot mod 2);
				var by = yy + (slot div 2) * row_h;
				if (debug_hovered(bx, by, half_w, row_h)) debug_tip(keepsake.name, keepsake.desc, sKeepsake, keepsake.sub_image);
				if (debug_button(bx, by, half_w, row_h, keepsake.name, owned_index != -1)) {
					if (owned_index != -1) {
						ds_list_delete(oRunManager.keepsakes, owned_index);
						debug_say("Removed " + keepsake.name);
					} else {
						gain_keepsake(keepsake);
						debug_say("Gained " + keepsake.name);
					}
				}
			}
		break;

		// -------------------------------------------------------------
		case "Items":
			if (!in_run) {
				debug_label(cx, cy, "Start a run first.");
				break;
			}

			var yy = cy;

			debug_label(cx, yy + 6, "Click to add to a free item slot.");
			yy += row_h;
			if (debug_button(cx, yy, half_w, row_h, "Empty my item slots")) {
				for (var i = 0; i < array_length(oRunManager.items); i++) oRunManager.items[i] = undefined;
				oRunManager.holding_item = false;
			}
			yy += row_h * 1.5;

			var total = ds_list_size(global.master_item_list);
			var list_rows = max(1, floor((cy + ch - yy) / row_h));
			var per_page = list_rows * 2;
			dbg.scroll = clamp(dbg.scroll, 0, max(0, ceil(total / 2) - list_rows));

			var first = dbg.scroll * 2;
			for (var i = first; i < min(total, first + per_page); i++) {
				var item = global.master_item_list[| i];
				var slot = i - first;

				var bx = cx + half_w * (slot mod 2);
				var by = yy + (slot div 2) * row_h;
				if (debug_hovered(bx, by, half_w, row_h)) {
					var core_die = undefined;
					if (item.type == "core") {
						core_die = clone_die(global.dice_d6_atk, "");
						core_die.distribution = item.distribution;
					}
					debug_tip(item.name, item.description, item.sprite, item.index, core_die);
				}
				if (debug_button(bx, by, half_w, row_h, item.name + "   (" + string(item.type) + ")")) {
					if (get_first_free_item_slot() == -1) {
						debug_say("No free item slot");
					} else {
						gain_item(item);
						debug_say("Gained " + item.name);
					}
				}
			}
		break;

		// -------------------------------------------------------------
		case "Events":
			if (!in_run) {
				debug_label(cx, cy, "Start a run first.");
				break;
			}

			var yy = cy;

			debug_label(cx, yy + 6, "Click an event to play it now.");
			yy += row_h * 1.5;

			for (var i = 0; i < array_length(dbg.event_names); i++) {
				if (debug_button(cx + half_w * (i mod 2), yy + (i div 2) * row_h, half_w, row_h, dbg.event_names[i])) {
					dbg.forced_event = dbg.event_names[i];
					debug_goto_room(rmEvent);
				}
			}
		break;

		// -------------------------------------------------------------
		case "Rooms":
			if (!in_run) {
				debug_label(cx, cy, "Start a run first.");
				break;
			}

			var yy = cy;

			debug_label(cx, yy + 6, "Jump straight to a room.");
			yy += row_h * 1.5;

			var room_list = [
				{ name: "Map",				target: rmMap },
				{ name: "Shop",				target: rmShop },
				{ name: "Workbench",		target: rmWorkbench },
				{ name: "Treasure",			target: rmTreasure },
				{ name: "Bounty board",		target: rmBounty },
				{ name: "Random event",		target: rmEvent },
			];

			for (var i = 0; i < array_length(room_list); i++) {
				if (debug_button(cx + half_w * (i mod 2), yy + (i div 2) * row_h, half_w, row_h, room_list[i].name)) {
					debug_goto_room(room_list[i].target);
				}
			}			
			// What the map will roll for the next draft (this used to be the Alt panel)
			var odds_y = yy + (ceil(array_length(room_list) / 2) + 1) * row_h;
			debug_label(cx, odds_y, "Next draft odds (nodes of this type so far)", c_yellow);
			odds_y += row_h;
			with (oWorldManager) {
				var odds = [
					["Combat",		combat_chance,		combat_nodes_this_voyage],
					["Event",		event_chance,		event_nodes_this_voyage],
					["Shop",		shop_chance,		shop_nodes_this_voyage],
					["Bounty",		bounty_chance,		bounty_nodes_this_voyage],
					["Elite",		elite_chance,		elite_nodes_this_voyage],
					["Alignment",	alignment_chance,	alignment_nodes_this_voyage],
				];
				for (var o = 0; o < array_length(odds); o++) {
					debug_label(cx + half_w * (o mod 2), odds_y + (o div 2) * row_h, odds[o][0] + "  " + string(odds[o][1]) + "%  (" + string(odds[o][2]) + ")");
				}
			}

		break;
	}

	// Tooltip for the list entry under the mouse, on top of everything
	if (dbg.hover_tip != undefined && instance_exists(oRunManager)) {
		var _tip = dbg.hover_tip;
		global.total_tooltip_height = 0;
		draw_single_tooltip(device_mouse_x_to_gui(0) + 20, device_mouse_y_to_gui(0) + 20, _tip.name, _tip.desc, _tip.icon, _tip.index, _tip.dice);
	}

	// Message line
	if (dbg.message_timer > 0) {
		debug_label(cx, py + ph - pad - row_h + 6, dbg.message, c_lime);
	}

	// Leave the draw state as other code expects it
	draw_set_alpha(1.0);
	draw_set_color(c_white);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
}

// =====================================================================
// HOOKS: the only places the game itself touches the debug menu.
// Each one does nothing unless the menu has asked for something.
// =====================================================================

/// oCombat Create: replace the enemy line-up with the one built in the menu.
function debug_apply_pending_fight() {
	if (!DEBUG_TOOLS) exit;

	var _fight = global.dbg.pending_fight;
	if (_fight == undefined) exit;

	global.dbg.pending_fight = undefined;

	with (oWorldManager) {
		ds_list_clear(room_enemies);
		for (var i = 0; i < array_length(_fight.names); i++) {
			var _enemy = enemy_find_by_name(_fight.names[i]);
			if (_enemy != undefined) ds_list_add(room_enemies, _enemy);
		}
		current_node_type = _fight.node_type;
	}
}

/// deal_single_die: the next die the menu wants dealt to hand, or undefined to draw from the bag as normal.
function debug_take_next_die() {
	if (!DEBUG_TOOLS) return undefined;
	if (array_length(global.dbg.next_dice) == 0) return undefined;

	var _die = global.dbg.next_dice[0];
	array_delete(global.dbg.next_dice, 0, 1);
	return _die;
}

/// generate_event: index in global.master_event_list of the event the menu asked for, or -1 for a random one.
function debug_take_forced_event_index() {
	if (!DEBUG_TOOLS) return -1;

	var _name = global.dbg.forced_event;
	if (_name == "") return -1;

	global.dbg.forced_event = "";

	// The event may already have been used this run, in which case rebuild the list and look again
	repeat (2) {
		for (var i = 0; i < ds_list_size(global.master_event_list); i++) {
			if (global.master_event_list[| i].name == _name) return i;
		}
		define_events();
	}

	return -1;
}

/// oCombat START_TURN: intel granted at the start of every turn.
function debug_turn_intel() {
	if (!DEBUG_TOOLS) return 0;
	return global.dbg.turn_intel;
}

/// Mark every node left on the current spread as cleared, exactly as sailing to each one would,
/// so the page turns. Skipped nodes don't count towards the map's difficulty ramp (nodes_cleared).
function debug_complete_spread() {
	if (!debug_in_run()) exit;
	
	if (room != rmMap) {
		debug_say("Go to the map first");
		exit;
	}
	
	with (oWorldManager) {
		if (world_state != WORLD_STATE.EXPLORING || node_to_move_to != undefined || nodes_til_drafting <= 0) {
			debug_say("Only while sailing a spread, with no move in progress");
			exit;
		}
		
		for (var n = 0; n < ds_list_size(all_nodes) && nodes_til_drafting > 0; n++) {
			var _node = all_nodes[| n];
			if (_node.cleared) continue;
			
			// the same bookkeeping as arriving at a node in oWorldManager Step
			_node.cleared = true;
			nodes_til_drafting--;
			nodes_til_page_cleared--;
			
			if (nodes_til_page_cleared == 0) {
				pages_cleared++;
				if (pages_cleared % 2 == 0) spreads_cleared++;
				if (nodes_til_drafting > 0) nodes_til_page_cleared = nodes_til_drafting;
			}
			
			last_node = _node;
		}
		next_node = undefined;
		
		// turn the page (or end the chapter) straight away
		world_finish_spread_if_done();
	}
	
	debug_menu_close(true);
	debug_say("Spread completed");
}

/// Run the game at a multiple of its normal speed (everything, animations included).
function debug_set_speed(_multiplier) {
	global.dbg.speed_multiplier = _multiplier;
	game_set_speed(global.dbg.base_speed * _multiplier, gamespeed_fps);
	debug_say("Game speed x" + string(_multiplier));
}
