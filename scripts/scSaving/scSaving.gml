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
	
	var _last_node = (oWorldManager.last_node != undefined) ? {
		name: oWorldManager.last_node.name,
		cleared: oWorldManager.last_node.cleared,
		disappeared: oWorldManager.last_node.disappeared,
		x: oWorldManager.last_node.x,
		y: oWorldManager.last_node.y,
	} : undefined;

	var _save = {
        version: 1,
        credits: oRunManager.credits,
        player_hp: global.player_hp,
        player_max_hp: global.player_max_hp,
        alignment: global.player_alignment,
        items: _saved_items,
        tools: _saved_tools,
        keepsakes: _saved_keepsakes,
        dice_bag: _saved_bag,
		chosen_pages: _saved_pages,
		map_position: oWorldManager.map_position,
		map_offset: oWorldManager.map_offset,
		last_node: _last_node,
		choices_locked: oWorldManager.choices_locked,
		nodes_til_drafting: oWorldManager.nodes_til_drafting,
		pages_drafted: oWorldManager.pages_drafted,
        active_bounty: oRunManager.active_bounty,
        world_state: oWorldManager.world_state,
        combat_chance: oWorldManager.combat_chance,
        event_chance: oWorldManager.event_chance,
        elite_chance: oWorldManager.elite_chance,
        alignment_chance: oWorldManager.alignment_chance,
        bounty_chance: oWorldManager.bounty_chance,
        shop_chance: oWorldManager.shop_chance,
        nodes_til_drafting: oWorldManager.nodes_til_drafting,
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
		
        rng_seed: random_get_seed(),
    };

	var _json = json_stringify(_save);
    var _file = file_text_open_write("save_slot_" + string(_slot) + ".json");
    file_text_write_string(_file, _json);
    file_text_close(_file);
}


function load_game(_slot) {
    var _file = file_text_open_read("save_slot_" + string(_slot) + ".json");
    var _json = file_text_read_string(_file);
    file_text_close(_file);

    var _save = json_parse(_json);

    // Basic state
    oRunManager.credits = _save.credits;
    global.player_hp = _save.player_hp;
    global.player_max_hp = _save.player_max_hp;
    global.player_alignment = _save.alignment;
	oWorldManager.map_position = _save.map_position;
	oWorldManager.map_offset = _save.map_offset;
	oWorldManager.pages_drafted = _save.pages_drafted;
	oRunManager.active_bounty = (_save.active_bounty != undefined) ? deserialise_bounty(_save.active_bounty) : undefined;
	oWorldManager.choices_locked = _save.choices_locked;
	//oWorldManager.next_node = _save.next_node;
    oWorldManager.world_state = _save.world_state;
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
	
    random_set_seed(_save.rng_seed);
	
	oRunManager.items = [];
	for (var i = 0; i < array_length(_save.items); i++) {
		if (_save.items[i] == undefined) {
			array_push(oRunManager.items, undefined); 
			continue;
		}
	    array_push(oRunManager.items, clone_item(get_item_by_name(_save.items[i])));
	}

    // Rebuild ds_lists
    ds_list_destroy(oRunManager.tools);
	oRunManager.tools = ds_list_create();
	for (var i = 0; i < array_length(_save.tools); i++) {
	    ds_list_add(oRunManager.tools, get_tool_by_name(_save.tools[i]));
	}

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
}

function save_exists(_slot) {
    return file_exists("save_slot_" + string(_slot) + ".json");
}