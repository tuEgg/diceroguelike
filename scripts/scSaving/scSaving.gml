// Bump this whenever the save format changes, older saves are then ignored instead of loading wrongly
#macro SAVE_VERSION 2

function save_game(_slot) {
	// Serialise dice bag
    var _saved_bag = [];
    for (var i = 0; i < ds_list_size(global.dice_bag); i++) {
        var _die = global.dice_bag[| i];
        array_push(_saved_bag, {
            dice_name: _die.name,
            dice_value: _die.dice_value,
			distribution: _die.distribution,
			min_roll_bonus: _die.min_roll_bonus,
			keywords: _die.keywords,		// keywords gained from upgrades must survive a reload
			description: _die.description,
        });
    }
	
	var _saved_keepsakes = [];
	for (var i = 0; i < ds_list_size(oRunManager.keepsakes); i++) {
	    array_push(_saved_keepsakes, oRunManager.keepsakes[| i]._id);
	}
	
	var _saved_items = [];
	for (var i = 0; i < array_length(oRunManager.items); i++) {
		if (oRunManager.items[i] == undefined) {
			array_push(_saved_items, undefined);
			continue;
		}
	    array_push(_saved_items, oRunManager.items[i].name);
	}
	
	var _saved_tools = [];
	for (var i = 0; i < ds_list_size(oRunManager.tools); i++) {
	    array_push(_saved_tools, oRunManager.tools[| i].name);
	}
	
	var _saved_pages = [];
	for (var i = 0; i < ds_list_size(oWorldManager.chosen_pages); i++) {
	    array_push(_saved_pages, serialise_page(oWorldManager.chosen_pages[| i]));
	}
	
	// the three pages on offer while drafting, so quitting mid-draft can't reroll them
	var _saved_pages_shown = [];
	for (var i = 0; i < ds_list_size(oWorldManager.pages_shown); i++) {
	    array_push(_saved_pages_shown, serialise_page(oWorldManager.pages_shown[| i]));
	}

	// what is left to find this run: events not yet seen, keepsakes and tools still in their pools
	var _events_remaining = [];
	for (var i = 0; i < ds_list_size(global.master_event_list); i++) array_push(_events_remaining, global.master_event_list[| i].name);
	var _rollable_keepsakes = [];
	for (var i = 0; i < ds_list_size(global.rollable_keepsake_list); i++) array_push(_rollable_keepsakes, global.rollable_keepsake_list[| i]._id);
	var _shop_keepsakes = [];
	for (var i = 0; i < ds_list_size(global.shop_keepsake_list); i++) array_push(_shop_keepsakes, global.shop_keepsake_list[| i]._id);
	var _tool_pool = [];
	for (var i = 0; i < ds_list_size(global.master_tool_list); i++) array_push(_tool_pool, global.master_tool_list[| i].name);

	// GameMaker can't read back where the random number generator is up to, so start it from a fresh
	// seed now and save that seed. Continue then carries on with exactly the same random numbers.
	var _rng_seed = irandom(2147483646);
	random_set_seed(_rng_seed);

	var _last_node = (oWorldManager.last_node != undefined) ? {
		name: oWorldManager.last_node.name,
		cleared: oWorldManager.last_node.cleared,
		disappeared: oWorldManager.last_node.disappeared,
		x: oWorldManager.last_node.x,
		y: oWorldManager.last_node.y,
	} : undefined;

	var _save = {
        version: SAVE_VERSION,
		pages_cleared: oWorldManager.pages_cleared,
		spreads_cleared: oWorldManager.spreads_cleared,
		chapter: oWorldManager.chapter,
		new_run_offering: oRunManager.new_run_offering,	// still choosing the starting die and core
		boss_page_placed: oWorldManager.boss_page_placed,
		bounty_board: serialise_bounty_board(),
		boat_x: oWorldManager.boat_data.x,
		boat_y: oWorldManager.boat_data.y,
		page_image_indices: oWorldManager.page_image_indices,
        credits: oRunManager.credits,
        player_hp: global.player_hp,
        player_max_hp: global.player_max_hp,
        alignment: global.player_alignment,
        items: _saved_items,
        tools: _saved_tools,
        keepsakes: _saved_keepsakes,
        dice_bag: _saved_bag,
		chosen_pages: _saved_pages,
		last_node: _last_node,
		choices_locked: oWorldManager.choices_locked,
		nodes_til_drafting: oWorldManager.nodes_til_drafting,
		pages_drafted: oWorldManager.pages_drafted,
		pages_shown: _saved_pages_shown,
        world_state: oWorldManager.world_state,
        combat_chance: oWorldManager.combat_chance,
        event_chance: oWorldManager.event_chance,
        elite_chance: oWorldManager.elite_chance,
        alignment_chance: oWorldManager.alignment_chance,
        bounty_chance: oWorldManager.bounty_chance,
        shop_chance: oWorldManager.shop_chance,
		nodes_cleared: oWorldManager.nodes_cleared,
		bounty_nodes_this_voyage: oWorldManager.bounty_nodes_this_voyage,
		elite_nodes_this_voyage: oWorldManager.elite_nodes_this_voyage,
		alignment_nodes_this_voyage: oWorldManager.alignment_nodes_this_voyage,
		combat_nodes_this_voyage: oWorldManager.combat_nodes_this_voyage,
		event_nodes_this_voyage: oWorldManager.event_nodes_this_voyage,
		shop_nodes_this_voyage: oWorldManager.shop_nodes_this_voyage,
		workbench_nodes_this_voyage: oWorldManager.workbench_nodes_this_voyage,		
		elite_list_before_bounty: ds_list_to_array(oWorldManager.elite_list_before_bounty),
		possible_alignment_encounters: ds_list_to_array(oWorldManager.possible_alignment_encounters),
		possible_elites: ds_list_to_array(oWorldManager.possible_elites),
		possible_encounters: ds_list_to_array(oWorldManager.possible_encounters),
		active_bounty: (oRunManager.active_bounty != undefined) ? serialise_bounty(oRunManager.active_bounty) : undefined,
		
        rng_seed: _rng_seed,

		luck: global.player_luck,
		dutchman_taken: oRunManager.dutchman_taken,
		voyage: oRunManager.voyage,
		bonus_dice_next_combat: oRunManager.bonus_dice_next_combat,
		show_consumables_chance: oRunManager.show_consumables_chance,
		events_remaining: _events_remaining,
		rollable_keepsakes: _rollable_keepsakes,
		shop_keepsakes: _shop_keepsakes,
		tool_pool: _tool_pool,
		run_stats: oRunManager.run_stats, // F05 end-of-voyage summary
    };

	var _json = json_stringify(_save);
    var _file = file_text_open_write("save_slot_" + string(_slot) + ".json");
    file_text_write_string(_file, _json);
    file_text_close(_file);
}


/// @returns {bool} false if there was no readable save of this version, in which case nothing is changed
function load_game(_slot) {
	var _path = "save_slot_" + string(_slot) + ".json";
	if (!file_exists(_path)) return false;

	var _save;
	try {
	    var _file = file_text_open_read(_path);
	    var _json = file_text_read_string(_file);
	    file_text_close(_file);
	    _save = json_parse(_json);
	} catch (_error) {
		show_debug_message("Couldn't read " + _path + ": " + string(_error));
		return false;
	}

	if (!variable_struct_exists(_save, "version") || _save.version != SAVE_VERSION) {
		show_debug_message("Ignoring " + _path + ", it was saved by a different version of the game");
		return false;
	}

    // Basic state
    oRunManager.credits = _save.credits;
    global.player_hp = _save.player_hp;
    global.player_max_hp = _save.player_max_hp;
    global.player_alignment = _save.alignment;
	oWorldManager.pages_drafted = _save.pages_drafted;
	oRunManager.active_bounty = (_save.active_bounty != undefined) ? deserialise_bounty(_save.active_bounty) : undefined;
	oWorldManager.choices_locked = _save.choices_locked;
	//oWorldManager.next_node = _save.next_node;
    oWorldManager.world_state = _save.world_state;
	oWorldManager.pages_cleared = _save.pages_cleared;
	oWorldManager.spreads_cleared = _save.spreads_cleared;
	oWorldManager.page_image_indices = _save.page_image_indices;
	// chapter fields arrived after save version 2, so fall back to sensible values for saves without them
	oWorldManager.chapter = variable_struct_exists(_save, "chapter") ? _save.chapter : 1;
	// reloaded before choosing the starting die and core: offer it again
	oRunManager.new_run_offering = variable_struct_exists(_save, "new_run_offering") ? _save.new_run_offering : false;
	if (oRunManager.new_run_offering) global.ui_layer = UI_LAYER.POPUP;
	oWorldManager.boss_page_placed = variable_struct_exists(_save, "boss_page_placed") ? _save.boss_page_placed : false;
	// the same bounty contracts and potion as before (older saves roll a fresh board)
	if (variable_struct_exists(_save, "bounty_board")) deserialise_bounty_board(_save.bounty_board);
	
	// put the boat back where it was moored (older saves leave it at its starting spot)
	if (variable_struct_exists(_save, "boat_x")) {
		oWorldManager.boat_data.x = _save.boat_x;
		oWorldManager.boat_data.y = _save.boat_y;
		oWorldManager.boat_data.base_y = _save.boat_y;
	}
	if (array_length(oWorldManager.page_image_indices) < CHAPTER_SPREADS + 2) {
		with (oWorldManager) generate_book_pages();
	}
	// The book only animates open in the OPENING state, so show it already open when resuming mid-run
	if (oWorldManager.world_state != WORLD_STATE.OPENING) oWorldManager.book_open_scale = 1;
    oWorldManager.combat_chance = _save.combat_chance;
    oWorldManager.event_chance = _save.event_chance;
    oWorldManager.elite_chance = _save.elite_chance;
    oWorldManager.alignment_chance = _save.alignment_chance;
    oWorldManager.bounty_chance = _save.bounty_chance;
    oWorldManager.shop_chance = _save.shop_chance;
    oWorldManager.nodes_til_drafting = _save.nodes_til_drafting;
	oWorldManager.nodes_cleared = _save.nodes_cleared;
	oWorldManager.bounty_nodes_this_voyage = _save.bounty_nodes_this_voyage;
	oWorldManager.elite_nodes_this_voyage = _save.elite_nodes_this_voyage;
	oWorldManager.alignment_nodes_this_voyage = _save.alignment_nodes_this_voyage;
	oWorldManager.combat_nodes_this_voyage = _save.combat_nodes_this_voyage;
	oWorldManager.event_nodes_this_voyage = _save.event_nodes_this_voyage;
	oWorldManager.shop_nodes_this_voyage = _save.shop_nodes_this_voyage;
	oWorldManager.workbench_nodes_this_voyage = _save.workbench_nodes_this_voyage;
	
	oRunManager.items = [];
	for (var i = 0; i < array_length(_save.items); i++) {
		if (_save.items[i] == undefined) {
			array_push(oRunManager.items, undefined); 
			continue;
		}
	    array_push(oRunManager.items, clone_item(get_item_by_name(_save.items[i])));
	}

	// Toolbelt adds item slots when it is picked up, which doesn't happen again on load,
	// so the slot count comes from the save and the hover arrays are rebuilt to match
	oRunManager.max_items = array_length(oRunManager.items);
	oRunManager.items_hover = array_create(oRunManager.max_items, false);
	oRunManager.items_hover_scale = array_create(oRunManager.max_items, 1.0);

    // Rebuild ds_lists
    ds_list_destroy(oRunManager.tools);
	oRunManager.tools = ds_list_create();
	for (var i = 0; i < array_length(_save.tools); i++) {
		var _tool = undefined;
		with (oRunManager) _tool = get_tool_by_name(_save.tools[i]);
	    if (_tool != undefined) ds_list_add(oRunManager.tools, _tool);
	}
	ds_list_clear(oRunManager.tools_scale);
	repeat (ds_list_size(oRunManager.tools)) ds_list_add(oRunManager.tools_scale, 0.5);

	// Rebuild chosen_pages first
	ds_list_destroy(oWorldManager.chosen_pages);
	oWorldManager.chosen_pages = ds_list_create();
	for (var i = 0; i < array_length(_save.chosen_pages); i++) {
	    ds_list_add(oWorldManager.chosen_pages, deserialise_page(_save.chosen_pages[i]));
	}

	// Then rebuild all_nodes by pulling references from the pages
	ds_list_destroy(oWorldManager.all_nodes);
	oWorldManager.all_nodes = ds_list_create();
	for (var i = 0; i < ds_list_size(oWorldManager.chosen_pages); i++) {
	    var _page = oWorldManager.chosen_pages[| i];
	    for (var n = 0; n < ds_list_size(_page.nodes); n++) {
	        ds_list_add(oWorldManager.all_nodes, _page.nodes[| n]);
	    }
	}
	
	// Load
	if (_save.last_node != undefined) {
	    var _base = get_node_by_name(_save.last_node.name);
	    oWorldManager.last_node = clone_node_static(_base);
	    oWorldManager.last_node.cleared = _save.last_node.cleared;
	    oWorldManager.last_node.disappeared = _save.last_node.disappeared;
	    oWorldManager.last_node.x = _save.last_node.x;
	    oWorldManager.last_node.y = _save.last_node.y;
	} else {
	    oWorldManager.last_node = undefined;
	}

	ds_list_destroy(oWorldManager.elite_list_before_bounty);
	oWorldManager.elite_list_before_bounty = array_to_ds_list(_save.elite_list_before_bounty);

	ds_list_destroy(oWorldManager.possible_alignment_encounters);
	oWorldManager.possible_alignment_encounters = array_to_ds_list(_save.possible_alignment_encounters);

	ds_list_destroy(oWorldManager.possible_elites);
	oWorldManager.possible_elites = array_to_ds_list(_save.possible_elites);

	ds_list_destroy(oWorldManager.possible_encounters);
	oWorldManager.possible_encounters = array_to_ds_list(_save.possible_encounters);

    // Rebuild dice bag
    ds_list_destroy(global.dice_bag);
    global.dice_bag = ds_list_create();
    for (var i = 0; i < array_length(_save.dice_bag); i++) {
        var _die = deserialise_die(_save.dice_bag[i]);
        ds_list_add(global.dice_bag, _die);
    }
	
	// Re add keepsakes
	ds_list_destroy(oRunManager.keepsakes);
	oRunManager.keepsakes = ds_list_create();
	for (var i = 0; i < array_length(_save.keepsakes); i++) {
	    ds_list_add(oRunManager.keepsakes, get_keepsake_by_id(_save.keepsakes[i]));
	}

	// The rest of the run. Each check lets an older save without that field load with the defaults.
	if (variable_struct_exists(_save, "luck")) global.player_luck = _save.luck;
	if (variable_struct_exists(_save, "dutchman_taken")) oRunManager.dutchman_taken = _save.dutchman_taken;
	if (variable_struct_exists(_save, "voyage")) oRunManager.voyage = _save.voyage;
	if (variable_struct_exists(_save, "bonus_dice_next_combat")) oRunManager.bonus_dice_next_combat = _save.bonus_dice_next_combat;
	if (variable_struct_exists(_save, "show_consumables_chance")) oRunManager.show_consumables_chance = _save.show_consumables_chance;

	// the draft on offer, if the game was closed mid-draft
	if (variable_struct_exists(_save, "pages_shown")) {
		ds_list_clear(oWorldManager.pages_shown);
		for (var i = 0; i < array_length(_save.pages_shown); i++) {
			ds_list_add(oWorldManager.pages_shown, deserialise_page(_save.pages_shown[i]));
		}
	}

	// events already seen this run don't come round again
	if (variable_struct_exists(_save, "events_remaining")) {
		define_events();
		for (var i = ds_list_size(global.master_event_list) - 1; i >= 0; i--) {
			if (!array_contains(_save.events_remaining, global.master_event_list[| i].name)) ds_list_delete(global.master_event_list, i);
		}
	}

	// the keepsake and tool pools, as they were
	if (variable_struct_exists(_save, "rollable_keepsakes")) load_keepsake_pool(global.rollable_keepsake_list, _save.rollable_keepsakes);
	if (variable_struct_exists(_save, "shop_keepsakes")) load_keepsake_pool(global.shop_keepsake_list, _save.shop_keepsakes);
	if (variable_struct_exists(_save, "tool_pool")) {
		ds_list_clear(global.master_tool_list);
		for (var i = 0; i < array_length(_save.tool_pool); i++) {
			var _tool = undefined;
			with (oRunManager) _tool = get_tool_by_name(_save.tool_pool[i]);
			if (_tool != undefined) ds_list_add(global.master_tool_list, _tool);
		}
	}

	// the end-of-voyage summary stats (older saves start from zero)
	if (variable_struct_exists(_save, "run_stats") && is_struct(_save.run_stats)) {
		var _keys = variable_struct_get_names(oRunManager.run_stats);
		for (var i = 0; i < array_length(_keys); i++) {
			if (variable_struct_exists(_save.run_stats, _keys[i])) oRunManager.run_stats[$ _keys[i]] = _save.run_stats[$ _keys[i]];
		}
	}

	// last of all, so nothing above uses up random numbers: carry on the random sequence from the save
	random_set_seed(_save.rng_seed);

	return true;
}

/// @desc Refill a keepsake pool from saved ids, using the master list's keepsake structs.
function load_keepsake_pool(_pool, _ids) {
	ds_list_clear(_pool);
	for (var i = 0; i < array_length(_ids); i++) {
		var _keepsake = get_keepsake_by_id(_ids[i]);
		if (_keepsake != undefined) ds_list_add(_pool, _keepsake);
	}
}

function save_exists(_slot) {
    var _path = "save_slot_" + string(_slot) + ".json";
    if (!file_exists(_path)) return false;

	// Only count saves written by this version of the game, so Continue never loads an incompatible file
	try {
		var _file = file_text_open_read(_path);
		var _json = file_text_read_string(_file);
		file_text_close(_file);

		var _save = json_parse(_json);
		return (variable_struct_exists(_save, "version") && _save.version == SAVE_VERSION);
	} catch (_error) {
		show_debug_message("Unreadable save ignored: " + _path);
		return false;
	}
}

function delete_save(_slot) {
    var _path = "save_slot_" + string(_slot) + ".json";
    file_delete(_path);
    show_debug_message("Deleted: " + _path + " | Still exists: " + string(file_exists(_path)));
}

function save_settings() {
	apply_resolution();
	
	_save = {
		resolution_index: global.resolution_index,
		vol_master: global.vol_master,
		vol_music: global.vol_music,
		vol_sfx: global.vol_sfx,
		vol_ui: global.vol_ui,
		muted: global.muted,
		fullscreen: window_get_fullscreen(),
		combat_speed_index: global.combat_speed_index,
		custom_cursor: global.custom_cursor,
		action_icons: global.action_icons,
	}
	
	var _json = json_stringify(_save);
    var _file = file_text_open_write("settings.json");
    file_text_write_string(_file, _json);
    file_text_close(_file);
}

function load_settings() {
	var _file = file_text_open_read("settings.json");
    var _json = file_text_read_string(_file);
    file_text_close(_file);

    var _save = json_parse(_json);
	global.resolution_index = _save.resolution_index;
	global.vol_master = _save.vol_master;
	global.vol_music = _save.vol_music;
	global.vol_sfx = _save.vol_sfx;
	global.vol_ui = _save.vol_ui;
	global.muted = _save.muted;
	if (variable_struct_exists(_save, "combat_speed_index")) global.combat_speed_index = _save.combat_speed_index;
	if (variable_struct_exists(_save, "custom_cursor")) global.custom_cursor = _save.custom_cursor;
	if (variable_struct_exists(_save, "action_icons")) global.action_icons = _save.action_icons;

	// a browser only allows fullscreen from a click, so a web build doesn't restore it at start-up
	if (!IS_BROWSER) window_set_fullscreen(_save.fullscreen);
}

function check_settings() {
	if (file_exists("settings.json")) {
		var _file = file_text_open_read("settings.json");
	    var _json = file_text_read_string(_file);
	    file_text_close(_file);
		
		var _save = json_parse(_json);
		if (global.resolution_index != _save.resolution_index)
		|| (global.vol_master != _save.vol_master)
		|| (global.vol_music != _save.vol_music)
		|| (global.vol_sfx != _save.vol_sfx)
		|| (global.vol_ui != _save.vol_ui)
		|| (global.muted != _save.muted)
		|| (window_get_fullscreen() != _save.fullscreen)
		|| (variable_struct_exists(_save, "combat_speed_index") ? global.combat_speed_index != _save.combat_speed_index : global.combat_speed_index != 1)
		|| (variable_struct_exists(_save, "custom_cursor") ? global.custom_cursor != _save.custom_cursor : !global.custom_cursor)
		|| (variable_struct_exists(_save, "action_icons") ? global.action_icons != _save.action_icons : global.action_icons) {
			settings_changed = true;
		} else {
			settings_changed = false;
		}
	} else {
		settings_changed = false;
	}
}

// =====================================================================
// PROGRESS
// What this player has seen, kept in its own file (progress.json) so it outlives runs: the intro cutscene, the
// tutorial, and one-time tips. Settings > Gameplay can turn the tutorial back on (it also clears the tips).
// =====================================================================

/// @func progress_defaults()
function progress_defaults() {
	return {
		intro_seen: false,		// the intro cutscene has played once (B69)
		tutorial_done: false,	// the guided first fight was finished or skipped
		tips_seen: [],			// ids of one-time tips already shown
	};
}

/// @func progress_load()
/// @desc Read progress.json into global.progress, keeping defaults for anything missing (older files, new fields).
function progress_load() {
	global.progress = progress_defaults();
	if (!file_exists("progress.json")) return;

	var _file = file_text_open_read("progress.json");
	var _json = "";
	while (!file_text_eof(_file)) {
		_json += file_text_read_string(_file);
		file_text_readln(_file);
	}
	file_text_close(_file);

	var _saved;
	try { _saved = json_parse(_json); } catch (_e) { return; } // unreadable: start fresh rather than crash
	if (!is_struct(_saved)) return;

	var _keys = variable_struct_get_names(global.progress);
	for (var i = 0; i < array_length(_keys); i++) {
		if (variable_struct_exists(_saved, _keys[i])) global.progress[$ _keys[i]] = _saved[$ _keys[i]];
	}
	if (!is_array(global.progress.tips_seen)) global.progress.tips_seen = [];
}

/// @func progress_save()
function progress_save() {
	progress_ensure();
	var _file = file_text_open_write("progress.json");
	file_text_write_string(_file, json_stringify(global.progress));
	file_text_close(_file);
}

/// @func progress_ensure()
/// @desc Loads progress the first time anything asks for it.
function progress_ensure() {
	if (!variable_global_exists("progress") || !is_struct(global.progress)) progress_load();
}

/// @func progress_get(_key)
function progress_get(_key) {
	progress_ensure();
	return global.progress[$ _key];
}

/// @func progress_set(_key, _value)
/// @desc Change one field and save straight away.
function progress_set(_key, _value) {
	progress_ensure();
	global.progress[$ _key] = _value;
	progress_save();
}

/// @func tip_seen(_tip_id)
/// @desc Has this one-time tip already been shown?
function tip_seen(_tip_id) {
	progress_ensure();
	return array_contains(global.progress.tips_seen, _tip_id);
}

/// @func tip_mark_seen(_tip_id)
function tip_mark_seen(_tip_id) {
	if (tip_seen(_tip_id)) return;
	array_push(global.progress.tips_seen, _tip_id);
	progress_save();
}

/// @func progress_set_tutorial(_on)
/// @desc Settings > Gameplay: on means the next new run plays the tutorial again (and shows the tips again).
function progress_set_tutorial(_on) {
	progress_ensure();
	global.progress.tutorial_done = !_on;
	if (_on) global.progress.tips_seen = [];
	progress_save();
}
