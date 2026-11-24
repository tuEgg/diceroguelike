// drafting cards (F178, option A): a landscape sheet of sea chart drawn in code (draw_page), so its size is free
#macro DRAFT_CARD_W 500
#macro DRAFT_CARD_H 330
#macro DRAFT_CARD_SEA make_color_rgb(150, 186, 190)

/// @func generate_pages
function generate_pages() {
	pool_refresh();
	var num_combat = 0; // generate no more than 5 across all 3 pages
	var num_event = 0; // generate no more than 3 across all 3 pages
	var num_shop = 0; // generate no more than 2 across all 3 pages
	var num_bounty = 0; // generate no more than 1 bounty across all 3 pages
	var num_elite = 0; // each page has an elite at the same time???
	var num_alignment = 0; // generate no more than 1 across all 3 pages
	
	// Generate 4 pages (2026-11-24: draft 2 of 4)
	repeat (4) {
		var _index = irandom(5);
		var _num_nodes = choose(1,2,2);
		var _left = 0;
		var _right = 0;
		var _top = 0;
		var _bottom = 0;
		
		// offset the position of the nodes and lines depending on the page sprite index
		//switch(_index) {
		//	case 0:
		//		_left = 60;
		//		_right = 55;
		//		_top = 20;
		//	break;
		//	case 1:
		//		_left = 40;
		//		_right = 30;
		//	break;
		//	case 2:
		//		_left = 40;
		//		_right = 50;
		//		_bottom = 20;
		//	break;
		//	case 3:
		//		_left = 40;
		//		_right = 60;
		//		_bottom = 20;
		//	break;
		//	case 4:
		//		_left = 60;
		//		_right = 30;
		//	break;
		//	case 5:
		//		_left = 40;
		//		_right = 30;
		//	break;
		//}
		
		// create the page data
		var _page = {
			index: _index,
			island_index: irandom(3),
			num_nodes: _num_nodes,
			nodes: ds_list_create(),
			layout: _num_nodes == 1 ? "single" : choose("horizontal", "diagonal-down"),
			map_connection_in: { x: 0, y: 0 },
			map_connection_out: { x: 0, y: 0 },
			margin: {
				left: _left,
				right: _right,
				bottom: _bottom,
				top: _top,
			},
			x: 0,
			y: 0,
			y_offset: 0,
			chosen: false,
			locked: false,
			cleared: false
		}
		
		// the connection points on the maps
		switch (_page.layout) {
			case "vertical":
				_page.map_connection_in.x = sprite_get_height(sMapParchment)/2;
			break;
			case "horizontal":
				_page.map_connection_in.x = sprite_get_height(sMapParchment)/2;
			break;
			default: _page.map_connection_in.x = sprite_get_height(sMapParchment)/2;
		}
		
		// the page's stops are drawn from the chapter's pool (2026-11-24, pool_draw): tokens on pages you don't take
		// go back (pool_return_page), so what you sail to over a chapter converges on what's in the pool
		repeat (_page.num_nodes) {
			var _tpl = pool_draw(_page);
			var _took = pool_drew; // false: the pool was empty, so this stop holds no token
			// the first stop of a run is always a fight
			if (oWorldManager.nodes_cleared == 0 && ds_list_size(_page.nodes) == 0 && _tpl.type != NODE_TYPE.COMBAT) {
				if (_took) pool_give_back(_tpl.type);
				_took = pool_take(NODE_TYPE.COMBAT);
				_tpl = node_combat;
			}
			var _nd = clone_node_static(_tpl);
			_nd.pool_type = _took ? _tpl.type : -1; // -1 gives nothing back (pool_key)
			ds_list_add(_page.nodes, _nd);
		}
	
		ds_list_add(pages_shown, _page);
	}
	pages_ensure_fights();
	pages_elite_pity();
	pages_assign_passages(); // each page brings the sea stop after its island (B+, 2026-11-21)
}

// =====================================================================
// THE CHAPTER POOL (2026-11-24, Jared's design brief): instead of every stop rolling its own chance, each chapter has a
// pool of stop tokens. Pages draw their stops from it; tokens on pages you don't take (burned, or left over) go back, so
// only the stops you sail to are used up. Rules on top: no elites in a chapter's first spread; the elite pity (spreads
// 3-4, no elite fought yet: 2 of the 4 pages get one); crossroads tokens by alignment distance; one bounty token from
// chapter 2 once you've fought an elite; the fight guarantee (pages_ensure_fights). Treasure is the fixed stop (F240).
// Tune the counts in pool_new.
// =====================================================================

/// @func pool_key(_type)
function pool_key(_type) {
	switch (_type) {
		case NODE_TYPE.COMBAT: return "combat";
		case NODE_TYPE.EVENT: return "event";
		case NODE_TYPE.SHOP: return "shop";
		case NODE_TYPE.ELITE: return "elite";
		case NODE_TYPE.ALIGNMENT: return "alignment";
		case NODE_TYPE.BOUNTY: return "bounty";
	}
	return "";
}

/// @func pool_new()
/// @desc A chapter's stop tokens. About 13 island stops are sailed to a chapter (4 spreads, 2 pages, 1-2 stops each),
///       so most of these get used: roughly 5-10 fights, 1-3 elites, 2-3 island events (sea events add 2 or so), 2-3 shops.
function pool_new() {
	stop_pool = { combat: 9, event: 3, shop: 3, elite: 3, alignment: 0, bounty: 0 };
	elites_fought_chapter = 0;
	alignment_fought_chapter = 0;
	bounty_seen_chapter = false;
	pool_refresh();
}

/// @func pool_alignment_target()
/// @desc Crossroads fights a chapter by how far alignment is from neutral: none at exactly 50, then 1, 2, 3, up to 4.
function pool_alignment_target() {
	var _d = abs(global.player_alignment - 50);
	if (_d == 0) return 0;
	if (_d <= 15) return 1;
	if (_d <= 30) return 2;
	if (_d <= 40) return 3;
	return 4;
}

/// @func pool_refresh()
/// @desc Before each draft: crossroads tokens follow your alignment now (less the ones fought this chapter), and the
///       bounty token is in from chapter 2 once any elite has been fought this run (one a chapter, not while one's active).
function pool_refresh() {
	if (!is_struct(stop_pool)) { pool_new(); return; }
	stop_pool.alignment = max(0, pool_alignment_target() - alignment_fought_chapter);
	var _elites_run = (instance_exists(oRunManager) && is_struct(oRunManager.run_stats) && variable_struct_exists(oRunManager.run_stats, "elites_won")) ? oRunManager.run_stats.elites_won : 0;
	stop_pool.bounty = (chapter >= 2 && _elites_run > 0 && !bounty_seen_chapter && oRunManager.active_bounty == undefined) ? 1 : 0;
}

/// @func pool_take(_type) / pool_give_back(_type)
/// @desc pool_take returns whether there was a token to take: a stop made without one gets pool_type -1, so it can't
///       give one back that was never taken.
function pool_take(_type) {
	var _k = pool_key(_type);
	if (_k == "" || !is_struct(stop_pool) || stop_pool[$ _k] <= 0) return false;
	stop_pool[$ _k] -= 1;
	return true;
}
function pool_give_back(_type) {
	var _k = pool_key(_type);
	if (_k != "" && is_struct(stop_pool)) stop_pool[$ _k] += 1;
}

/// @func pool_draw(_page)
/// @desc One stop for a page, drawn by weight from the pool (and taken from it). No elite in a chapter's first spread,
///       and at most one elite, crossroads or bounty a page. An empty pool gives a fight.
function pool_draw(_page) {
	pool_drew = false; // whether a token was taken (generate_pages reads it)
	if (!is_struct(stop_pool)) pool_new();
	var _has = {};
	for (var n = 0; n < ds_list_size(_page.nodes); n++) _has[$ pool_key(_page.nodes[| n].type)] = true;
	var _keys = ["combat", "event", "shop", "elite", "alignment", "bounty"];
	var _tpls = [node_combat, node_event, node_shop, node_elite, node_alignment, node_bounty];
	var _w = array_create(6, 0), _total = 0;
	for (var i = 0; i < 6; i++) {
		var _c = stop_pool[$ _keys[i]];
		if (_keys[i] == "elite" && spreads_cleared == 0) _c = 0;
		if (i >= 3 && variable_struct_exists(_has, _keys[i])) _c = 0; // one elite / crossroads / bounty a page
		if (_keys[i] == "shop" && variable_struct_exists(_has, "shop")) _c = 0;
		_w[i] = _c;
		_total += _c;
	}
	if (_total <= 0) return node_combat;
	var _r = irandom_range(1, _total);
	for (var i = 0; i < 6; i++) {
		_r -= _w[i];
		if (_r <= 0) {
			stop_pool[$ _keys[i]] -= 1;
			pool_drew = true;
			return _tpls[i];
		}
	}
	return node_combat;
}

/// @func pool_return_page(_page)
/// @desc A page you didn't take (burned, or left over): its stops' tokens go back in the pool.
function pool_return_page(_page) {
	if (!is_struct(_page) || !ds_safe_exists(_page.nodes, ds_type_list)) return;
	for (var n = 0; n < ds_list_size(_page.nodes); n++) {
		var _nd = _page.nodes[| n];
		pool_give_back(variable_struct_exists(_nd, "pool_type") ? _nd.pool_type : _nd.type);
	}
}

/// @func pages_elite_pity()
/// @desc Spreads 3 and 4 with no elite fought yet this chapter: make sure 2 of the 4 pages offer one (a page's first
///       stop that isn't a fight or a treasure becomes an elite; if none, its first combat does). elite_pity_active keeps
///       the burn from taking the last one (draft_choose_burn).
function pages_elite_pity() {
	elite_pity_active = (spreads_cleared >= 2 && elites_fought_chapter == 0);
	if (!elite_pity_active) return;
	var _with = 0;
	for (var p = 0; p < ds_list_size(pages_shown); p++) {
		var _pg = pages_shown[| p];
		for (var n = 0; n < ds_list_size(_pg.nodes); n++) if (_pg.nodes[| n].type == NODE_TYPE.ELITE) { _with++; break; }
	}
	for (var p = 0; p < ds_list_size(pages_shown) && _with < 2; p++) {
		var _pg = pages_shown[| p];
		var _has = false;
		for (var n = 0; n < ds_list_size(_pg.nodes); n++) if (_pg.nodes[| n].type == NODE_TYPE.ELITE) _has = true;
		if (_has) continue;
		var _at = -1;
		for (var n = 0; n < ds_list_size(_pg.nodes) && _at == -1; n++) if (!node_is_fight(_pg.nodes[| n]) && _pg.nodes[| n].type != NODE_TYPE.TREASURE) _at = n;
		for (var n = 0; n < ds_list_size(_pg.nodes) && _at == -1; n++) if (_pg.nodes[| n].type == NODE_TYPE.COMBAT) _at = n;
		if (_at == -1) continue;
		var _old = _pg.nodes[| _at];
		pool_give_back(variable_struct_exists(_old, "pool_type") ? _old.pool_type : _old.type);
		var _e = clone_node_static(node_elite);
		_e.pool_type = pool_take(NODE_TYPE.ELITE) ? NODE_TYPE.ELITE : -1; // an empty elite pool still gives one: the pity wins
		_pg.nodes[| _at] = _e;
		_with++;
	}
}

/// @func draft_choose_burn()
/// @desc Draft 2 of 4 (2026-11-24): after your first pick one of the other pages burns. Random, with a guard: the pages left
///       to choose from must still hold a fight (and, while the elite pity is on, an elite). One function, so in co-op or
///       head-to-head the burn can become the other player's pick. Returns the page to burn.
function draft_choose_burn() {
	var _open = [];
	for (var i = 0; i < ds_list_size(pages_shown); i++) if (!pages_shown[| i].chosen) array_push(_open, pages_shown[| i]);
	if (array_length(_open) == 0) return undefined;
	var _ok = [];
	for (var i = 0; i < array_length(_open); i++) {
		var _fight = false, _elite = false;
		for (var j = 0; j < array_length(_open); j++) {
			if (j == i) continue;
			if (page_has_fight(_open[j])) _fight = true;
			for (var n = 0; n < ds_list_size(_open[j].nodes); n++) if (_open[j].nodes[| n].type == NODE_TYPE.ELITE) _elite = true;
		}
		var _need_elite = variable_instance_exists(id, "elite_pity_active") && elite_pity_active;
		if (_fight && (_elite || !_need_elite)) array_push(_ok, _open[i]);
	}
	if (array_length(_ok) == 0) _ok = _open;
	return _ok[irandom(array_length(_ok) - 1)];
}

/// @func node_is_fight(_node)
/// @desc A stop that's a fight: combat, elite, the crossroads fight or the boss.
function node_is_fight(_node) {
	return is_struct(_node) && (_node.type == NODE_TYPE.COMBAT || _node.type == NODE_TYPE.ELITE || _node.type == NODE_TYPE.ALIGNMENT || _node.type == NODE_TYPE.BOSS);
}

/// @func page_has_fight(_page)
function page_has_fight(_page) {
	for (var n = 0; n < ds_list_size(_page.nodes); n++) if (node_is_fight(_page.nodes[| n])) return true;
	return false;
}

/// @func page_give_fight(_page)
/// @desc Makes the page's first stop that isn't a treasure (or already a fight) a combat, so the page opens with a fight
///       where it can.
function page_give_fight(_page) {
	for (var n = 0; n < ds_list_size(_page.nodes); n++) {
		var _nd = _page.nodes[| n];
		if (_nd.type == NODE_TYPE.TREASURE) continue;
		pool_give_back(variable_struct_exists(_nd, "pool_type") ? _nd.pool_type : _nd.type);
		var _c = clone_node_static(node_combat);
		_c.pool_type = pool_take(NODE_TYPE.COMBAT) ? NODE_TYPE.COMBAT : -1;
		_page.nodes[| n] = _c;
		return;
	}
}

/// @func pages_ensure_fights()
/// @desc After generate_pages rolls the three pages (Jared, 2026-11-22: there were long stretches with no fight and no
///       choice in it): there's always a fight on at least one of them, and once you've gone
///       FIGHT_DROUGHT_ROOMS stops without one (oRunManager.rooms_since_fight), every page has one.
#macro FIGHT_DROUGHT_ROOMS 4
function pages_ensure_fights() {
	var _n = ds_list_size(pages_shown);
	if (_n == 0) return;
	var _drought = instance_exists(oRunManager) && oRunManager.rooms_since_fight >= FIGHT_DROUGHT_ROOMS;
	var _any = false;
	for (var p = 0; p < _n; p++) {
		var _pg = pages_shown[| p];
		if (_drought && !page_has_fight(_pg)) page_give_fight(_pg);
		if (page_has_fight(_pg)) _any = true;
	}
	if (!_any) page_give_fight(pages_shown[| irandom(_n - 1)]);
}

/// @function node_find_by_id(_id)
function node_find_by_id(_id) {
    for (var i = 0; i < ds_list_size(node_list); i++) {
        var n = node_list[| i];
        if (n.node_id == _id) return n;
    }
    return undefined;
}

/// @function enemy_find_by_name(_name)
function enemy_find_by_name(_name) {
    for (var i = 0; i < ds_list_size(global.enemy_list); i++) {
        var n = global.enemy_list[| i];
        if (n.name == _name) return n;
    }
    return undefined;
}

function enter_node(_node) {
	// Everything random about this node is decided once and kept on the node, and the game is saved
	// on the way in, so quitting and pressing Continue brings back the same fight or event
	var _memory_node = _node;
	current_node = _node;
	
	if (_node.type == NODE_TYPE.EVENT) {
		if (!variable_struct_exists(_node, "event_roll")) _node.event_roll = irandom_range(1, 100);
		var rand = _node.event_roll;
		if (rand <= 8) {
			_node = clone_node_static(node_combat);
		} else if (rand <= 16 && !oRunManager.dutchman_taken) { // no shops once the Dutchman has sailed through
			_node = clone_node_static(node_shop);
		}
	}
	
	if (_node.type == NODE_TYPE.ALIGNMENT) {
		alignment_chance = 0;
	}
	
	get_combat_enemies(_node, _memory_node);
	current_node_type = _node.type;
	// stops since your last fight (pages_ensure_fights); counted once per stop, not again when a save reloads into it
	if (!variable_struct_exists(_memory_node, "fight_counted")) {
		_memory_node.fight_counted = true;
		// what the chapter pool's rules count (2026-11-24)
		if (_node.type == NODE_TYPE.ELITE) elites_fought_chapter++;
		if (_node.type == NODE_TYPE.ALIGNMENT) alignment_fought_chapter++;
		if (_node.type == NODE_TYPE.BOUNTY) bounty_seen_chapter = true;
		if (!(variable_struct_exists(_memory_node, "sea") && _memory_node.sea)) oRunManager.rooms_since_fight = node_is_fight(_node) ? 0 : oRunManager.rooms_since_fight + 1;
	}
	
	// an event node picks its event now (the event room shows it), so it can be saved with the node
	if (_node.type == NODE_TYPE.EVENT) {
		var _has_event = variable_struct_exists(_memory_node, "event_name") && is_string(_memory_node.event_name) && _memory_node.event_name != "";
		if (!_has_event) {
			if (ds_list_size(global.master_event_list) == 0) define_events();
			// island events on islands, sea events at sea (2026-11-24); any event if that pool has run dry
			var _sea = variable_struct_exists(_memory_node, "sea") && _memory_node.sea;
			// each chapter has its own events (event_chapter, 2026-11-24): this chapter's first, then an earlier chapter's,
			// then island/sea is let go, then anything left
			var _fit = [];
			for (var _pass = 0; _pass < 4 && array_length(_fit) == 0; _pass++) {
				for (var e = 0; e < ds_list_size(global.master_event_list); e++) {
					var _nm = global.master_event_list[| e].name;
					var _ch = event_chapter(_nm);
					var _ok = false;
					switch (_pass) {
						case 0: _ok = (_ch == chapter && event_is_sea(_nm) == _sea); break;
						case 1: _ok = (_ch <= chapter && event_is_sea(_nm) == _sea); break;
						case 2: _ok = (_ch <= chapter); break;
						case 3: _ok = true; break;
					}
					if (_ok) array_push(_fit, _nm);
				}
			}
			_memory_node.event_name = _fit[irandom(array_length(_fit) - 1)];
		}
	}
	
	// a shop rolls its shelves now, and a treasure room its keepsake, for the same reason
	if (_node.type == NODE_TYPE.SHOP && !(variable_struct_exists(_memory_node, "shop_stock") && is_struct(_memory_node.shop_stock))) {
		_memory_node.shop_stock = roll_shop_stock();
	}
	if (_node.type == NODE_TYPE.TREASURE && !(variable_struct_exists(_memory_node, "treasure_keepsake") && is_string(_memory_node.treasure_keepsake) && _memory_node.treasure_keepsake != "")) {
		var _rolled = ds_list_create();
		generate_keepsake_rewards(_rolled, global.rollable_keepsake_list, 1);
		if (ds_list_size(_rolled) > 0) _memory_node.treasure_keepsake = _rolled[| 0]._id;
		ds_list_destroy(_rolled);
	}
	
	// saved before the node is marked cleared, so Continue comes back to the map with this node still to play
	save_game(1);
	
	room_goto(_node.linked_room);
}

/// @param _node			the node being entered (an event may have turned into a combat clone)
/// @param _memory_node	the node on the map, which remembers the encounter it rolled
function get_combat_enemies(_node, _memory_node = _node) {

	// the guided first fight (tutorial) is always a lone Pirate Ruffian: a plain attacker and blocker
	if (_node.type == NODE_TYPE.COMBAT && tutorial_wanted()) {
		ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Pirate Ruffian"));
		return;
	}

	if (_node.type == NODE_TYPE.COMBAT) {

		// Refill the pool if we've fought everything, so we never start an empty fight
		if (ds_list_size(possible_encounters) == 0) {
			for (var i = 1; i <= 7; i++) ds_list_add(possible_encounters, "Encounter " + string(i));
		}

		// Find a random encounter in the list of possible encounters
		var encounter_key = node_pick_encounter(_memory_node, possible_encounters);
		
		// Add the relevant enemies
		switch (encounter_key) {
			case "Early 1":
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Deckhand"));
			break;
			
			case "Early 2":
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Baby Kraken"));
			break;
			
			case "Early 3":
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Seagull"));
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Seagull"));
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Seagull"));
			break;
			
			case "Early 4":
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Thug"));
			break;
		
			
			case "Encounter 1":
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Deckhand"));
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Barrel o' Fish"));
			break;
			
			case "Encounter 2":
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Thug"));
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Driftnet Fish"));
			break;
			
			case "Encounter 3":
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Driftnet Fish"));
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Driftnet Fish"));
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Driftnet Fish"));
			break;
			
			case "Encounter 4":
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Corsair Gunner"));
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Seagull"));
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Seagull"));
			break;
			
			case "Encounter 5":
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Turtle"));
			break;
		
			case "Encounter 6":
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Pirate Ruffian"));
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Parrot"));
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Peg-leg"));
			break;
		
			case "Encounter 7":
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Pufferfish"));
			break;
		}

		
	} else if (_node.type == NODE_TYPE.ELITE) {

		// Refill the pool if it's empty, so we never start an empty fight
		if (ds_list_size(possible_elites) == 0) {
			for (var i = 1; i <= 3; i++) ds_list_add(possible_elites, "Elite " + string(i));
		}

		// Find a random encounter in the list of possible encounters
		var encounter_key = node_pick_encounter(_memory_node, possible_elites);
		
		switch (encounter_key) {
			case "Elite 1":
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Pirate Captain"));
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Deckhand"));
			break;
			
			case "Elite 2":
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Giant Conch"));
			break;
			
			case "Elite 3":
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Pirate Captain"));
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Deckhand"));
			break;
		}

	} else if (_node.type == NODE_TYPE.ALIGNMENT) {

		// Refill the pool if it's empty, so we never start an empty fight
		if (ds_list_size(possible_alignment_encounters) == 0) {
			ds_list_add(possible_alignment_encounters, "Alignment 1");
		}

		// Find a random encounter in the list of possible encounters
		var encounter_key = node_pick_encounter(_memory_node, possible_alignment_encounters);
		
		switch (encounter_key) {
			case "Alignment 1":
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Elizabeak"));
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Bill"))
			break;
		}

	} else if (_node.type == NODE_TYPE.BOSS) {
		ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Barnacle Titan"));
	}
	
	
}

function draw_dotted_path(page, n, num_nodes, node_x, node_y) {
	
	/// Get start/end
	var x1 = node_x[n];
	var y1 = node_y[n];
	var x2 = node_x[n+1];
	var y2 = node_y[n+1];

	/// Special case for first segment
	if (n == 0) {
	    y1 += page.map_connection_in.x;
	}

	/// Build a path
	var _path = path_add();
	path_set_kind(_path, true);
	path_set_closed(_path, false);

	/// Base points
	path_add_point(_path, x1, y1, 0);

	/// OPTIONAL: auto-curve midpoint
	/// You can tweak this or replace with your own control logic
	var mx = lerp(x1, x2, 0.5);
	var my = lerp(y1, y2, 0.5);

	// Offset midpoint to create a curve
	switch(n) {
		case 0: my -= (y1 - y2) / 2; break;
		case num_nodes: my += (y1 - y2) / 2; break;
		default: my += 0;
	}// push upward (positive = down)
	path_add_point(_path, mx, my, 0);

	/// End point
	path_add_point(_path, x2, y2, 0);


	/// Measure total path length
	var len = path_get_length(_path);
	
	var all_nodes_cleared = true;
	for (var c = 0; c < page.num_nodes; c++) {
		if (page.nodes[| c].cleared == false) {
			all_nodes_cleared = false;
			break;
		}
	}

	/// Dot spacing
	var spacing = 12;
	var radius  = 4;
	var color   = choices_locked || all_nodes_cleared ? c_white : c_black;


	/// March along actual distance
	for (var d = 0; d <= len; d += spacing) {
	    var t = d / len;
    
	    var xx = path_get_x(_path, t);
	    var yy = path_get_y(_path, t);
    
	    draw_set_color(color);
		if (xx > boat_data.x) draw_circle(xx, yy, radius, false);
	}
	
	//// For debugging
	//draw_path(_path, node_x[0], node_y[0], true);


	/// Cleanup
	path_delete(_path);
}

function draw_page( _page, _x, _y, _index, _shadow, _locked) {
	var page = _page;
	var page_x = _x;
	var page_y = _y;
	
	var _scale;
	
	if _index == -1 {
		_scale = 1;
	} else {
		_scale = page_scale[| _index];
	}
	
	/// at the top of draw_page, right after you receive _page
	if (!is_struct(_page) || !variable_struct_exists(_page, "num_nodes")) {
	    show_debug_message("BAD PAGE: missing num_nodes");

	    show_debug_message("TYPE: " + typeof(_page));
    
	    if (is_struct(_page)) {
	        var keys = variable_struct_get_names(_page);
	        show_debug_message("FIELDS: " + string(keys));
	    } else {
	        show_debug_message("VALUE: " + string(_page));
	    }

	    show_debug_message("FULL PAGE LIST: " + ds_list_write(pages_shown));

	    return false; // or exit; but don't fall through to the for-loop
	}

	// check to see if we've cleared all the nodes of this map
	var all_nodes_cleared = true;
	for (var n = 0; n < _page.num_nodes; n++) {
		if (_page == undefined || _page.nodes == undefined) {
		} else {
			if (_page.nodes[| n].cleared == false) {
				all_nodes_cleared = false;
				break;
			}
		}
	}
		
	var _sprite = sMapParchment;
	
	var _alpha;

	if (all_nodes_cleared || _locked) {
	    _alpha = 0.0;
	} else  {
		_alpha = 1.0;
	}
	
	var _blend;
	var _icon_blend = c_white;

	if (page.chosen && !page.locked) {
	    // chosen in this draft: plain paper, outlined in green below
	    _blend = c_white;
	}
	else if (!page.chosen || all_nodes_cleared) {
	    // either unselected or fully cleared
	    _blend = c_white;
	}
	else {
	    // selected but has uncleared nodes
	    _blend = make_color_rgb(30,30,30);
		_icon_blend = _blend;
	}

	
	var page_width = sprite_get_width(_sprite);
	var page_height = sprite_get_height(_sprite);
		
	// a drafting card is a landscape sheet of sea chart, drawn in code so it can be any size (option A of
	// docs/mockups/draft-cards.html; Jared 2026-11-21): sea blue all over with a torn ink edge (ui_paper), the island in
	// its left part (_icx) and the sea stop in its right part (page_passage_preview), with room round both.
	var _land = (_index != -1);
	var pages_hover = mouse_hovering(page_x, page_y, (_land ? DRAFT_CARD_W : page_width) * _scale, (_land ? DRAFT_CARD_H : page_height) * _scale, true, soPaperHover, soClick4, !_locked * !page.chosen, UI_LAYER.BASE, "page:" + string(_index) + ":" + string(page.index) + ":" + string(page.island_index)); // a steady id (it grows on hover)
	_scale = lerp(_scale, (pages_hover && _land) ? 1.04 : 1.0, 0.2);

	var draw_scale = _scale;
	if (!_shadow) draw_scale = 1;
	var _cw = DRAFT_CARD_W * draw_scale, _ch = DRAFT_CARD_H * draw_scale;
	var _cx1 = page_x - _cw / 2, _cy1 = page_y - _ch / 2, _cx2 = page_x + _cw / 2, _cy2 = page_y + _ch / 2;
	var _seed = page.index * 13 + page.island_index * 7 + max(0, _index) * 3 + 1;
	var _icx = page_x - (_land ? _cw * 0.19 : 0); // the island's centre: left on a drafting card
	if (_land) {
		// picked in this draft: a thick green edge behind it (Jared's mockup)
		if (page.chosen && !page.locked && _alpha > 0) ui_paper(_cx1 - 8, _cy1 - 8, _cx2 + 8, _cy2 + 8, _seed + 5, make_color_rgb(70, 220, 90), _alpha * pages_alpha, 0, false);
		ui_paper(_cx1, _cy1, _cx2, _cy2, _seed, DRAFT_CARD_SEA, _alpha * pages_alpha, 4, _alpha > 0);
	} else {
		if (_shadow) draw_sprite_ext(_sprite, page.index, page_x + 20, page_y + 20, _scale * 0.98, _scale * 0.98, 0, c_black, 0.5 * pages_alpha);
		draw_sprite_ext(_sprite, page.index, page_x, page_y, draw_scale, draw_scale, 0, _blend, _alpha * pages_alpha);
	}
	
	
	
	// Draw islands - they draw to their own surface so we can mask them out
	var surf_w = display_get_gui_width(); // the GUI is always 1920x1080 (B83), so the island surfaces match it
	var surf_h = display_get_gui_height();
	
	// Rebuild the surfaces if the resolution has changed since they were made
	if (surface_exists(island_surf) && (surface_get_width(island_surf) != surf_w || surface_get_height(island_surf) != surf_h)) {
		surface_free(island_surf);
		if (surface_exists(island_mask_surf)) surface_free(island_mask_surf);
	}
	
	if (_alpha == 1) {
		if (!surface_exists(island_surf)) {
			island_surf = surface_create(surf_w, surf_h);
		}
	
		if (!surface_exists(island_mask_surf)) {
			island_mask_surf = surface_create(surf_w, surf_h);
		}
		
		// build the mask
		surface_set_target(island_mask_surf);
		draw_clear_alpha(c_black, 0);
		if (_land) ui_paper(_cx1, _cy1, _cx2, _cy2, _seed, c_white, 1, 0, false); // the card's own shape
		else draw_sprite_ext(_sprite, page.index, page_x, page_y, draw_scale, draw_scale, 0, _blend, _alpha);
		surface_reset_target();

		surface_set_target(island_surf);
		draw_clear_alpha(c_black, 0);

		// content — correct alpha accumulation
		gpu_set_blendmode_ext_sepalpha(bm_src_alpha, bm_inv_src_alpha, bm_one, bm_inv_src_alpha);
	}
	
	// draw sprites
	var island_alpha = !_locked ? pages_alpha : 1;
	
	// a drafting card is drawn bigger, island and stops too (_is), so the preview looks like the page will (2026-11-21)
	var _is = _land ? draw_scale * 0.78 : 1; // a drafting card's island, a little smaller so it has room round it
	shader_set(shWhiteFill)
	for (var i = 0; i < 3; i++) {
		draw_sprite_ext(sIslands, page.island_index, _icx, page_y, (1 + i / 3) * _is, (1 + i / 3) * _is, 0, c_white, 0.2);
	}
	shader_reset();

	draw_sprite_ext(sIslands, page.island_index, _icx, page_y, _is, _is, 0, c_white, island_alpha);

	if (_alpha == 1) {
		// apply the mask, over the page only: shErode reads ~80 pixels for each one, and run over the whole screen for
		// every drafting card it slowed the game right down until the draft was done (Jared, 2026-11-22)
		var _bx1, _by1, _bx2, _by2;
		if (_land) { _bx1 = _cx1 - 16; _by1 = _cy1 - 16; _bx2 = _cx2 + 16; _by2 = _cy2 + 16; }
		else {
			_bx1 = page_x - sprite_get_xoffset(_sprite) * draw_scale - 16; _by1 = page_y - sprite_get_yoffset(_sprite) * draw_scale - 16;
			_bx2 = _bx1 + sprite_get_width(_sprite) * draw_scale + 32; _by2 = _by1 + sprite_get_height(_sprite) * draw_scale + 32;
		}
		_bx1 = clamp(floor(_bx1), 0, surf_w); _by1 = clamp(floor(_by1), 0, surf_h);
		_bx2 = clamp(ceil(_bx2), 0, surf_w); _by2 = clamp(ceil(_by2), 0, surf_h);
		var _bw = max(1, _bx2 - _bx1), _bh = max(1, _by2 - _by1);
		shader_set(shErode);
		shader_set_uniform_f(u_erode_texel, 1 / surf_w, 1 / surf_h);
		shader_set_uniform_f(u_erode_radius, 5);
		gpu_set_blendmode_ext(bm_zero, bm_src_alpha);
		draw_surface_part(island_mask_surf, _bx1, _by1, _bw, _bh, _bx1, _by1);
		shader_reset();
		gpu_set_blendmode(bm_normal);
		surface_reset_target();

		// draw out premultiplied
		gpu_set_blendmode_ext(bm_one, bm_inv_src_alpha);
		draw_surface_part(island_surf, _bx1, _by1, _bw, _bh, _bx1, _by1);
		gpu_set_blendmode(bm_normal);
	}
	
		
	var paper_w = sprite_get_width(_sprite);
	var paper_h = sprite_get_height(_sprite);
		
	page_y += page.margin.top - page.margin.bottom;
		
	node_x[0] = page_x - paper_w/2 + page.margin.left;
	node_y[0] = page_y - paper_h/2;
		
	// Draw connecting lines
	for (var n = 0; n <= ds_list_size(page.nodes); n++) {
		var node = page.nodes[| n];
		var num_nodes = ds_list_size(page.nodes);
			
		switch (page.layout) {
			case "horizontal":
				node_x[n+1] = node_x[n] + paper_w/(num_nodes*1.75) - (n == 0 ? page.margin.left/2 : 0);
				node_y[n+1] = page_y + (3-n * paper_h/5);
			break;
			case "diagonal-down":
				node_x[n+1] = node_x[n] + paper_w/(num_nodes*1.75) - (n == 0 ? page.margin.left/2 : 0);
				node_y[n+1] = node_y[n] + paper_h/(num_nodes*1.5);
			break;
			case "single":
				node_x[1] = page_x;
				node_y[1] = page_y;
			break;
			default:
				node_x[n+1] = node_x[n] + paper_w/2;
				node_y[n+1] = node_y[n] + paper_h/2;
		}
			
		if (n == num_nodes) {
			node_x[num_nodes + 1] = page_x + paper_w/2 - page.margin.right;
			node_y[num_nodes + 1] = page_y;
		}
			
		if (!choices_locked) {
			//draw_dotted_path(page, n, num_nodes, node_x, node_y);
		}
	}
		
	// a landscape card: its stops move and scale with the island
	if (_land) {
		for (var n = 0; n < array_length(node_x); n++) {
			node_x[n] = _icx + (node_x[n] - _x) * _is;
			node_y[n] = _y + (node_y[n] - _y) * _is;
		}
	}

	// while drafting, each page's course between its stops (once sailing, spread_routes_draw inks them)
	if (!choices_locked) {
		for (var n = 1; n < ds_list_size(page.nodes); n++) route_draw(node_x[n], node_y[n], node_x[n + 1], node_y[n + 1], 0.55 * (_locked ? 0.4 : 1) * ((_index == -1) ? 1 : pages_alpha));
	}

	// Draw icons on top
	for (var n = 0; n < ds_list_size(page.nodes); n++) {
		var node = page.nodes[| n];
		
		node.x = node_x[n+1] + (node_drift * node.cleared);
		node.y = node_y[n+1];
		
		if (node.x < -30) node.disappeared = true;
	
		// if the node isn't off screen yet
		if (!node.disappeared) {
			var _alph;

			// if we haven't locked our page choices or this is the next node we can reach
			if (!choices_locked || node == next_node) {
			    _alph = 1.0;
			}
			// or if the node is cleared
			else if (node.cleared) {
			    _alph = 1.0;
			}
			// or if the choices are locked and the page is chosen
			else if (choices_locked && page.chosen) {
			    _alph = pages_alpha;
			}
			// otherwise they show up slightly grey
			else {
			    _alph = 1.0;
				_icon_blend = c_grey;
			}

			// if we haven't locked our two page choices
			if (!choices_locked) {
				// and this particular page isn't locked
				if (!_locked) {
					
					// check if we are hovering this node
					var node_hover = mouse_hovering( node.x, node.y, sprite_get_width(sMapIcon) * node.scale, sprite_get_height(sMapIcon) * node.scale, true);
					
					// animate scale
					node.scale = lerp(node.scale, node_hover ? 1.5 : 1.0, 0.2);
					
					// show tooltip
					if (node_hover) queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), node.name, node.text + ((variable_struct_exists(node, "linked") && node.linked) ? "\nOnly one page can keep this." : ""), sMapIcon, node.subimg, undefined);
					
					// draw the node
					map_node_icon_draw(node, node.scale, _alph);
				} else if _locked {
					// if this page is locked, don't animate scale or show tooltip
					map_node_icon_draw(node, 1, _alph);
				}
			}
			// if our page choices are locked
			else {
				
				// check if we are hovering this node
				var node_hover = mouse_hovering( node.x, node.y, sprite_get_width(sMapIcon) * node.scale, sprite_get_height(sMapIcon) * node.scale, true);
			
				draw_set_color(c_black);
				draw_set_halign(fa_left);
				draw_set_font(ftDefault);
			
				// animate scale and draw node
				node.scale = lerp(node.scale, node_hover ? 1.5 : 1.0, 0.2);
				map_node_icon_draw(node, node.scale, _alph);

				// if we are hovering this node
				if (node_hover) {
					// show tooltip
					queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), node.name, node.text, sMapIcon, node.subimg, undefined);
					 
					// on click, if we haven't picked a node to move to and we are on the base layer of the UI, set this node as the next node ot move to.
					if (mouse_check_button_pressed(mb_left) && node_to_move_to == undefined && global.ui_layer == UI_LAYER.BASE && !map_sailing_to_sea()) { // not while sailing to a sea stop
						var _blocked = map_node_blocked_reason(node);
						if (_blocked != "") {
							throw_error("Not yet", _blocked);
						} else if (node == next_node) {
							node_to_move_to = node; // (it used to be nudged 10 px down here, which made the stop and its courses jump for a frame)
						} else {
							throw_error("Not yet", "Clear the next stop first.");
						}
					}
				}
			}
		
			// a done stop: circled, with a tick (Jared, 2026-11-21: no fading, no green)
			if (node.cleared) map_done_ring(node.x, node.y, 30 * node.scale, _alph); // its tick (the grey disc is under the icon)
			// its name underneath, like the sea stops (in ink with a paper halo)
			draw_set_font(font_tip());
			draw_set_halign(fa_center);
			draw_set_valign(fa_top);
			draw_outline_text((variable_struct_exists(node, "morph_t") && node.morph_t < 10) ? node.morph_name : node.name, global.ui_col.paper_hi, global.ui_col.ink, 2, node.x, node.y + 24 + 6 * node.scale, 1, _alph, 0);
			draw_set_halign(fa_left);
		}
	}
	
	// if this page is locked draw a chain over it
	if (page.locked && !variable_struct_exists(page, "burn_t")) draw_sprite_ext(sRewardChain, 0, page_x, page_y, 1.4, 1.4, 0, c_white, pages_alpha); // a lost draft page burns instead (page_burn_draw)
	
	// update page scale ds list for next frame
	if (_index != -1) {
	    page_scale[| _index] = _scale;
	}
	
	return pages_hover;
}


/// @func clone_page(_page_struct)
function clone_page(_src) {
    var c = {
        index: _src.index,
		island_index: _src.island_index,
		is_boss: page_is_boss(_src),
		passage: variable_struct_exists(_src, "passage") ? _src.passage : "", // the sea stop after its island (B+)
		passage_done: false,
		harbour_done: false,
		treasure_stop: false, // F240: a treasure stop before this spread's islands (the left page of spread 3)
		treasure_done: false,
		treasure_keepsake: "",
        num_nodes: _src.num_nodes,
        nodes: ds_list_create(),
        layout: _src.layout,
        map_connection_in: { x: _src.map_connection_in.x, y: _src.map_connection_in.y },
        map_connection_out: { x: _src.map_connection_out.x, y: _src.map_connection_out.y },
        margin: {
            left: _src.margin.left,
            right: _src.margin.right,
            top: _src.margin.top,
            bottom: _src.margin.bottom
        },
        chosen: false,
        locked: false,
        cleared: false,
        x: _src.x,
        y: _src.y,
        y_offset: _src.y_offset,
    };

    // Deep clone nodes (struct only)
    for (var i = 0; i < _src.num_nodes; i++) {
        var old_node = _src.nodes[| i];
        var new_node = clone_node_static(old_node); // important
        ds_list_add(c.nodes, new_node);
    }

    return c;
}

/// @func clone_node_static(_src)
/// Creates a safe node copy for map storage.
/// Does NOT clone nested combat data.
function clone_node_static(_src) {

    return {
        type: _src.type,
		name: _src.name,
        subimg: _src.subimg,
        text: _src.text,

        // Keep room link so we know where to go
        linked_room: _src.linked_room,

        // Visual state
        scale: 1.0,        // reset to sane default
        cleared: false,    // reset for overworld logic
        disappeared: false,

        // Position set later by draw_page
        x: 0,
        y: 0,
    };
}

function serialise_page(_page) {
    var _saved_nodes = [];
    for (var i = 0; i < ds_list_size(_page.nodes); i++) {
        var _node = _page.nodes[| i];
        array_push(_saved_nodes, {
            name: _node.name,
            cleared: _node.cleared,
            disappeared: _node.disappeared,
            x: _node.x,
            y: _node.y,
            encounter: variable_struct_exists(_node, "encounter") ? _node.encounter : "", // "" and -1 mean "not rolled yet" (JSON null would load back as pointer_null)
            event_roll: variable_struct_exists(_node, "event_roll") ? _node.event_roll : -1,
            event_name: variable_struct_exists(_node, "event_name") ? _node.event_name : "",
            shop_stock: (variable_struct_exists(_node, "shop_stock") && is_struct(_node.shop_stock)) ? _node.shop_stock : "",
            treasure_keepsake: variable_struct_exists(_node, "treasure_keepsake") ? _node.treasure_keepsake : "",
            pool_type: variable_struct_exists(_node, "pool_type") ? _node.pool_type : _node.type,
        });
    }
    return {
        index: _page.index,
        island_index: _page.island_index,
        is_boss: page_is_boss(_page),
        passage: variable_struct_exists(_page, "passage") ? _page.passage : "",
        passage_done: variable_struct_exists(_page, "passage_done") ? _page.passage_done : true,
        harbour_done: variable_struct_exists(_page, "harbour_done") ? _page.harbour_done : false,
        treasure_stop: variable_struct_exists(_page, "treasure_stop") ? _page.treasure_stop : false,
        treasure_done: variable_struct_exists(_page, "treasure_done") ? _page.treasure_done : false,
        treasure_keepsake: variable_struct_exists(_page, "treasure_keepsake") ? _page.treasure_keepsake : "",
        num_nodes: _page.num_nodes,
        layout: _page.layout,
        map_connection_in: _page.map_connection_in,
        map_connection_out: _page.map_connection_out,
        margin: _page.margin,
        chosen: _page.chosen,
        locked: _page.locked,
        cleared: _page.cleared,
        x: _page.x,
        y: _page.y,
        y_offset: _page.y_offset,
        nodes: _saved_nodes,
    };
}

function deserialise_page(_data) {
    var _page = {
        index: _data.index,
        island_index: _data.island_index,
        is_boss: variable_struct_exists(_data, "is_boss") ? _data.is_boss : false,
        // a page saved before B+ has no passage (and counts it as passed); the strait then falls back to calm water
        passage: variable_struct_exists(_data, "passage") ? _data.passage : "",
        passage_done: variable_struct_exists(_data, "passage_done") ? _data.passage_done : true,
        harbour_done: variable_struct_exists(_data, "harbour_done") ? _data.harbour_done : false,
        treasure_stop: variable_struct_exists(_data, "treasure_stop") ? _data.treasure_stop : false,
        treasure_done: variable_struct_exists(_data, "treasure_done") ? _data.treasure_done : false,
        treasure_keepsake: variable_struct_exists(_data, "treasure_keepsake") ? _data.treasure_keepsake : "",
        num_nodes: _data.num_nodes,
        nodes: ds_list_create(),
        layout: _data.layout,
        map_connection_in: _data.map_connection_in,
        map_connection_out: _data.map_connection_out,
        margin: _data.margin,
        chosen: _data.chosen,
        locked: _data.locked,
        cleared: _data.cleared,
        x: _data.x,
        y: _data.y,
        y_offset: _data.y_offset,
    };
    
    for (var i = 0; i < array_length(_data.nodes); i++) {
        var _saved_node = _data.nodes[i];
        var _base_node = get_node_by_name(_saved_node.name);
        var _node = clone_node_static(_base_node);
        _node.cleared = _saved_node.cleared;
        _node.disappeared = _saved_node.disappeared;
        _node.x = _saved_node.x;
        _node.y = _saved_node.y;
        // what this node already rolled, so Continue brings back the same fight or event
        if (variable_struct_exists(_saved_node, "encounter") && is_string(_saved_node.encounter) && _saved_node.encounter != "") _node.encounter = _saved_node.encounter;
        if (variable_struct_exists(_saved_node, "event_roll") && is_real(_saved_node.event_roll) && _saved_node.event_roll > 0) _node.event_roll = _saved_node.event_roll;
        if (variable_struct_exists(_saved_node, "event_name") && is_string(_saved_node.event_name) && _saved_node.event_name != "") _node.event_name = _saved_node.event_name;
        if (variable_struct_exists(_saved_node, "shop_stock") && is_struct(_saved_node.shop_stock)) _node.shop_stock = _saved_node.shop_stock;
        if (variable_struct_exists(_saved_node, "treasure_keepsake") && is_string(_saved_node.treasure_keepsake) && _saved_node.treasure_keepsake != "") _node.treasure_keepsake = _saved_node.treasure_keepsake;
        if (variable_struct_exists(_saved_node, "pool_type") && is_real(_saved_node.pool_type)) _node.pool_type = _saved_node.pool_type;
        ds_list_add(_page.nodes, _node);
    }
    
    return _page;
}

function start_drafting() {
	world_state = WORLD_STATE.DRAFTING;
	strait = undefined; // the next spread plans its own (strait_build)
	for (var n = 0; n < ds_list_size(all_nodes); n++) {
		if (!all_nodes[| n].disappeared) all_nodes[| n].disappeared = true;
	}
	current_page_turn = 1;
}

// =====================================================================
// CHAPTERS
// The book is one long logbook. Each chapter is CHAPTER_SPREADS drafted
// spreads followed by a boss spread, then the next chapter begins.
// =====================================================================

#macro CHAPTER_SPREADS 4				// drafted spreads before the boss spread (Q13: was 7, then 3; 4 since 2026-11-21)
#macro CHAPTER_COUNT 3				// chapters in a voyage, beating the last boss wins the run
#macro CHAPTER_ENEMY_HP_GROWTH 0.5		// each chapter after the first adds this fraction of an enemy's health
#macro CHAPTER_ENEMY_BONUS_GROWTH 3		// each chapter after the first adds this to every enemy attack and block
#macro ENEMY_ATTACK_BOOST 0.2			// every enemy attack, from chapter 1, adds about this share of its average roll (Q11)

/// @desc Picks the paper art for every page of this chapter's book, never the same twice in a row.
///       One page per spread plus the two outer pages, so the boss spread still has a right-hand page.
function generate_book_pages() {
	var _count = CHAPTER_SPREADS + 2;
	page_image_indices = array_create(_count);
	
	var _last_index = -1;
	for (var i = 0; i < _count; i++) {
		var _rand_index;
		do {
			_rand_index = irandom_range(2, 7);
		} until (_rand_index != _last_index);
		
		page_image_indices[i] = _rand_index;
		_last_index = _rand_index;
	}
}

/// @desc Is this the page that holds the chapter's boss?
function page_is_boss(_page) {
	return variable_struct_exists(_page, "is_boss") && _page.is_boss;
}

/// @desc Name shown on the chapter title screen.
function chapter_title(_chapter) {
	switch (_chapter) {
		case 1: return "The Wreck of the Dawnchaser";
		case 2: return "The Ragged Coast";
		default: return "Uncharted Waters";
	}
}

/// @desc The boss spread isn't drafted. Lay the boss page straight onto the right-hand page and set sail.
function place_boss_page() {
	var _page = {
		index: 0,
		island_index: irandom(3),
		num_nodes: 1,
		nodes: ds_list_create(),
		layout: "single",
		map_connection_in: { x: 0, y: 0 },
		map_connection_out: { x: 0, y: 0 },
		margin: { left: 0, right: 0, bottom: 0, top: 0 },
		x: display_get_gui_width() * 0.666,
		y: display_get_gui_height() * 0.5,
		y_offset: 0,
		chosen: true,
		locked: false,
		cleared: false,
		is_boss: true,
		passage: "",
		passage_done: true,
		harbour_done: false, // the harbour before the boss (harbour_draw): rest or refit, once
	};
	
	var _node = clone_node_static(node_boss);
	ds_list_add(_page.nodes, _node);
	
	ds_list_add(chosen_pages, _page);
	ds_list_add(all_nodes, _node);
	
	// the same bookkeeping drafting two pages would have done
	nodes_til_drafting = 1;
	nodes_til_page_cleared = 1;
	pages_drafted = 1;
	choices_locked = true;
	next_node = undefined;
	
	boss_page_placed = true;
}

/// @desc Called once the boss is beaten and the player continues: a fresh book for the next chapter.
function start_new_chapter() {
	chapter++;
	
	// the old chapter's pages are finished with
	for (var p = 0; p < ds_list_size(chosen_pages); p++) {
		var _nodes = chosen_pages[| p].nodes;
		if (ds_safe_exists(_nodes, ds_type_list)) ds_list_destroy(_nodes);
	}
	ds_list_clear(chosen_pages);
	ds_list_clear(all_nodes);
	ds_list_clear(pages_shown);
	
	next_node = undefined;
	last_node = undefined;
	node_to_move_to = undefined;
	
	// the boss spread was a single page, keep the page count even so spreads still tick over after two pages
	if (pages_cleared mod 2 != 0) pages_cleared++;
	spreads_cleared = 0;
	boss_page_placed = false;
	nodes_til_drafting = 0;
	nodes_til_page_cleared = 0;
	pages_drafted = 0;
	choices_locked = false;
	pages_alpha = 0;
	resting_alpha = 0;
	current_page_turn = 1;
	
	// every regular and elite encounter is available again
	ds_list_clear(possible_encounters);
	for (var i = 1; i <= 7; i++) ds_list_add(possible_encounters, "Encounter " + string(i));
	ds_list_clear(possible_elites);
	for (var i = 1; i <= 3; i++) ds_list_add(possible_elites, "Elite " + string(i));

	// elites, the bounty board and the crossroads fight come back each chapter (F239, Jared 2026-11-23: they were once
	// a run, so chapter 3 could have no elites and keepsakes dried up)
	elite_nodes_this_voyage = 0;
	bounty_nodes_this_voyage = 0;
	alignment_nodes_this_voyage = 0;
	pool_new(); // the chapter pool (2026-11-24)
	elite_chance = 0;
	bounty_chance = 0;
	alignment_chance = 0;
	
	// a new book opens
	generate_book_pages();
	book_open_scale = 0;
	chapter_end_alpha = 0;
	world_state = WORLD_STATE.OPENING;
	
	boat_data.x = 300;
	boat_data.y = display_get_gui_height() / 2;
	
	// the chapter break is a safe place to resume from
	save_game(1);
}

/// @desc Enemies get tougher each chapter. Works on the per-fight copy, never the shared definition.
function enemy_apply_chapter_scaling(_enemy_copy) {
	// every attack hits about a fifth harder, from the first chapter (Q11): at least +1, from its average roll
	for (var m = 0; m < ds_list_size(_enemy_copy.moves); m++) {
		var _mv = _enemy_copy.moves[| m];
		if (string_pos("ATK", _mv.action_type) > 0) {
			var _avg = _mv.dice_amount * (_mv.dice_value + 1) / 2 + _mv.bonus_amount;
			if (_avg > 0) _mv.bonus_amount += max(1, round(_avg * ENEMY_ATTACK_BOOST));
		}
	}

	var _extra_chapters = oWorldManager.chapter - 1;
	if (_extra_chapters <= 0) return;
	
	_enemy_copy.max_hp = round(_enemy_copy.max_hp * (1 + CHAPTER_ENEMY_HP_GROWTH * _extra_chapters));
	_enemy_copy.current_hp = _enemy_copy.max_hp;
	
	for (var m = 0; m < ds_list_size(_enemy_copy.moves); m++) {
		var _move = _enemy_copy.moves[| m];
		if (string_pos("ATK", _move.action_type) > 0 || string_pos("BLK", _move.action_type) > 0 || _move.action_type == "MIMIC") {
			_move.bonus_amount += CHAPTER_ENEMY_BONUS_GROWTH * _extra_chapters;
		}
	}
}

/// @desc When every node on the current spread is done: turn the page, or end the chapter if that was the boss.
///       Called on room start and every step on the map, so a loaded game can never be left with nowhere to go.
function world_finish_spread_if_done() {
	if (world_state != WORLD_STATE.EXPLORING || nodes_til_drafting != 0 || node_to_move_to != undefined) return;
	
	var _last_page = chosen_pages[| ds_list_size(chosen_pages) - 1];
	if (_last_page != undefined && page_is_boss(_last_page)) {
		world_state = WORLD_STATE.CHAPTER_END;
	} else {
		// the strait: the spread's end is a fork of sea stops on the map (planned since the spread began, strait_draw)
		world_state = WORLD_STATE.STRAIT;
	}
}

/// @desc Draws a finished spread's page while the book page turns over it. Islands and node icons
///       follow the turning page: the right-hand page squashes in towards the spine as it lifts,
///       and the left-hand page is covered as the turned page comes down over it.
///       Draw only, nothing here can be hovered or clicked.
/// @param _page		a page from chosen_pages
/// @param _turn		current_page_turn: 1 = flat on the right, 0 = upright, -1 = flat on the left
/// @param _pivot_x		where the turning page is hinged, for the right-hand page
/// @param _cover_x		where the turned page lands from, for the left-hand page
/// @param _page_w		on-screen width of a book page
function draw_page_turning(_page, _turn, _pivot_x, _cover_x, _page_w) {
	var _on_right = (_page.x > _pivot_x);
	
	// right-hand page: everything squashes towards the hinge, and is gone once the page is upright
	if (_on_right && _turn <= 0) return;
	var _xscale = _on_right ? _turn : 1;
	
	// both pages fade out as the right page lifts, and stay gone (the left island used to vanish, then pop back as the
	// turned page came over: Jared, 2026-11-22)
	var _fade = clamp(_turn, 0, 1);

	// island, with the same white glow draw_page gives it
	var _island_x = _on_right ? _pivot_x + (_page.x - _pivot_x) * _xscale : _page.x;
	var _island_alpha = _fade;
	
	if (_island_alpha > 0) {
		shader_set(shWhiteFill);
		for (var i = 0; i < 3; i++) {
			draw_sprite_ext(sIslands, _page.island_index, _island_x, _page.y, (1 + i / 3) * _xscale, 1 + i / 3, 0, c_white, 0.2 * _island_alpha);
		}
		shader_reset();
		draw_sprite_ext(sIslands, _page.island_index, _island_x, _page.y, _xscale, 1, 0, c_white, _island_alpha);
	}
	
	// node icons, at the positions they were last drawn at
	for (var n = 0; n < ds_list_size(_page.nodes); n++) {
		var _node = _page.nodes[| n];
		var _node_x = _on_right ? _pivot_x + (_node.x - _pivot_x) * _xscale : _node.x;
		var _node_alpha = _fade;
		if (_node_alpha <= 0) continue;
		
		draw_sprite_ext(sMapIcon, _node.subimg, _node_x, _node.y, _xscale, 1, 0, c_white, _node_alpha);
	}
}

/// @desc The encounter for a fight node. Rolled from _pool the first time the node is entered,
///       then remembered on the node, so re-entering it (after Continue) gives the same fight.
function node_pick_encounter(_memory_node, _pool) {
	if (variable_struct_exists(_memory_node, "encounter") && is_string(_memory_node.encounter) && _memory_node.encounter != "") {
		return _memory_node.encounter;
	}
	
	var _index = irandom(ds_list_size(_pool) - 1);
	var _key = _pool[| _index];
	ds_list_delete(_pool, _index);
	
	_memory_node.encounter = _key;
	return _key;
}

/// @desc A folder-style divider tab sticking out to the right, with its label running down it.
///       x0 is the inner end (hidden under the page), x1 the outer end; the outer corners are cut.
///       _visible_w is how much sticks out past the page, the label is centred on that part.
function draw_chapter_tab(_x0, _y0, _x1, _y1, _slant, _label, _col, _visible_w, _alpha, _label_alpha = 1) {
	var _outline = 4;
	
	draw_set_alpha(_alpha);
	
	// black outline: the same shape, a little larger
	draw_set_color(c_black);
	draw_tab_shape(_x0, _y0 - _outline, _x1 + _outline, _y1 + _outline, _slant);
	
	draw_set_color(_col);
	draw_tab_shape(_x0, _y0, _x1, _y1, _slant);
	
	// label, reading top to bottom, centred on the part that sticks out
	draw_set_font(ftDefault);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	var _visible_mid_x = _x1 - _visible_w / 2;
	if (_label != "") draw_outline_text(_label, c_black, c_white, 2, _visible_mid_x, (_y0 + _y1) / 2, 1, _alpha * _label_alpha, -90); // "": no label (the tab's tooltip names it)
	
	draw_set_alpha(1.0);
}

/// @desc Filled tab outline: square at the inner end, cut corners at the outer end.
function draw_tab_shape(_x0, _y0, _x1, _y1, _slant) {
	draw_rectangle(_x0, _y0, _x1 - _slant, _y1, false);
	draw_rectangle(_x1 - _slant, _y0 + _slant, _x1, _y1 - _slant, false);
	draw_triangle(_x1 - _slant, _y0, _x1, _y0 + _slant, _x1 - _slant, _y0 + _slant, false);
	draw_triangle(_x1 - _slant, _y1, _x1, _y1 - _slant, _x1 - _slant, _y1 - _slant, false);
}

/// @desc The colour of a chapter's divider tab: teal for chapter 2, violet for chapter 3.
function chapter_tab_colour(_chapter) {
	switch (_chapter) {
		case 2: return make_color_rgb(70, 190, 170);
		case 3: return make_color_rgb(140, 95, 200);
		default: return make_color_rgb(200, 150, 70);
	}
}

/// @desc The voyage at a glance, like a floor counter: a row of markers under the book, one per spread,
///       grouped by chapter, with the boss as a larger diamond at the end of each chapter.
///       Done spreads are filled, the current one pulses, the rest are hollow. Hover any marker for detail.
function draw_voyage_progress(_cx, _y, _alpha) {
	if (_alpha <= 0) return;
	
	var _spacing = 22;		// between markers
	var _chapter_gap = 34;	// between chapters
	var _boss_gap = 4;		// extra room before a boss diamond: its points reach 4px further than a circle, so the gaps look even
	var _radius = 6;
	var _per_chapter = CHAPTER_SPREADS + 1; // drafted spreads, then the boss
	var _total_w = CHAPTER_COUNT * ((_per_chapter - 1) * _spacing + _boss_gap) + (CHAPTER_COUNT - 1) * _chapter_gap;
	var _x = _cx - _total_w / 2;
	var _pulse = 1 + 0.25 * sin(current_time / 180);
	
	draw_set_alpha(_alpha);
	
	for (var c = 1; c <= CHAPTER_COUNT; c++) {
		var _col = chapter_tab_colour(c);
		
		for (var s = 0; s < _per_chapter; s++) {
			var _is_boss = (s == _per_chapter - 1);
			
			// how far along is this marker?
			var _done = (c < chapter) || (c == chapter && (s < spreads_cleared || world_state == WORLD_STATE.CHAPTER_END));
			var _current = (c == chapter && s == spreads_cleared && world_state != WORLD_STATE.CHAPTER_END);
			
			var _r = _is_boss ? _radius + 4 : _radius;
			if (_current) _r *= _pulse;
			
			// black outline, then the fill (hollow for markers still to come)
			draw_set_color(c_black);
			// a diamond's edges are at 45 degrees, so its outline needs to reach sqrt(2) times further to look as thick
			if (_is_boss) draw_diamond(_x, _y, _r + 3 * sqrt(2)); else draw_circle(_x, _y, _r + 3, false);
			
			draw_set_color(_done || _current ? (_current ? c_white : _col) : make_color_rgb(90, 70, 50));
			if (_is_boss) draw_diamond(_x, _y, _r); else draw_circle(_x, _y, _r, false);
			
			if (mouse_hovering(_x, _y, _spacing, _spacing, true)) {
				var _what = _is_boss ? "Boss" : "Leg " + string(s + 1) + " of " + string(CHAPTER_SPREADS);
				var _when = _done ? "Done." : (_current ? "You are here." : "Still to come.");
				queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Chapter " + string(c) + ": " + _what, chapter_title(c) + ". " + _when);
			}
			
			if (s < _per_chapter - 1) _x += _spacing;
			if (s == _per_chapter - 2) _x += _boss_gap; // the next marker is the boss
		}
		
		_x += _chapter_gap;
	}
	
	draw_set_alpha(1.0);
}

/// @desc A filled diamond (a square on its point), used for boss markers.
function draw_diamond(_x, _y, _r) {
	draw_triangle(_x - _r, _y, _x, _y - _r, _x + _r, _y, false);
	draw_triangle(_x - _r, _y, _x, _y + _r, _x + _r, _y, false);
}

// =====================================================================
// SPREAD END (F02): Heal, plus two choices rolled from a pool, or Continue
// =====================================================================

/// @func spread_end_roll_options()
/// @desc Two different choices for beside Heal: a core, remove a die, sharpen a die, or gold.
function spread_end_roll_options() {
	var _pool = ["core", "trim", "whet", "gold"];
	var _a = irandom(3);
	var _b = (_a + 1 + irandom(2)) mod 4; // a different one
	return [_pool[_a], _pool[_b]];
}

/// @func spread_end_option_info(_id, _heal_amount, _can_heal)
/// @desc What a spread-end choice shows: { flavour, label, tip, ok, reason }.
function spread_end_option_info(_id, _heal_amount, _can_heal) {
	switch (_id) {
		case "heal":
			return { flavour: "Recover below deck", label: "Heal " + string(_heal_amount) + " HP", tip: "Heal " + string(_heal_amount) + " HP.", ok: _can_heal, reason: "You're at full health." };
		case "core":
			return { flavour: "Search the hold", label: "Gain a core", tip: "Gain a random core.", ok: true, reason: "" }; // full slots: delete an item for it, or sail past (pending_item_draw)
		case "trim":
			return { flavour: "Lighten the hold", label: "Remove a die", tip: "Remove a die from your bag.", ok: ds_list_size(global.dice_bag) > 6, reason: "Your bag has 6 dice or fewer." };
		case "whet":
			return { flavour: "Sharpen a die", label: "+1 min roll", tip: "Give a die +1 minimum roll.", ok: ds_list_size(global.dice_bag) > 0, reason: "Your bag is empty." };
		case "gold":
			return { flavour: "Sell some cargo", label: "Gain 50 gold", tip: "Gain 50 gold.", ok: true, reason: "" };
	}
	return { flavour: "", label: "?", tip: "", ok: false, reason: "" };
}

/// @func spread_end_apply(_id, _heal_amount)
/// @desc Do the chosen spread-end choice. Removing or sharpening opens the bag's dice picker.
function spread_end_apply(_id, _heal_amount, _x = -1, _y = -1) {
	switch (_id) {
		case "heal":
			global.player_hp = min(global.player_max_hp, global.player_hp + _heal_amount);
			var _hs = ui_health_spot();
			particle_emit(_hs.x, _hs.y, "burst", c_lime); // where your health is in the top bar
			break;
		case "core":
			var _opts = ds_list_create();
			generate_item_rewards(_opts, global.master_item_list, 1, "core");
			if (ds_list_size(_opts) > 0) {
				if (get_first_free_item_slot() != -1) gain_item(_opts[| 0]);
				else oRunManager.pending_item = _opts[| 0]; // no room: it waits (pending_item_draw)
			}
			ds_list_destroy(_opts);
			break;
		case "trim":
			with (oRunManager) {
				dice_selection = 1;
				dice_selection_message = "Choose a die to throw overboard";
				dice_selection_event = function(_die) {
					var _i = ds_list_find_index(global.dice_bag, _die);
					if (_i == -1) return;
					particle_emit(115, 1000, "burst", get_dice_color(_die.possible_type), 30);
					spawn_floating_number("bag", 0, _die.name + " removed", _die.color, 0, -1, 0);
					ds_list_delete(global.dice_bag, _i);
				};
			}
			break;
		case "whet":
			with (oRunManager) {
				dice_selection = 1;
				dice_selection_message = "Choose a die to gain +1 min roll";
				dice_selection_filter = "min_room";
				dice_selection_event = function(_die) {
					_die.min_roll_bonus += 1;
					particle_emit(115, 1000, "rise", get_dice_color(_die.possible_type), 30);
					spawn_floating_number("bag", 0, _die.name + " +1 min roll", _die.color, 0, -1, 0);
				};
			}
			break;
		case "gold":
			// off the stop itself when we know where it is (flotsam), else the middle of the screen
			gain_coins((_x >= 0) ? _x : display_get_gui_width() / 2, (_y >= 0) ? _y : display_get_gui_height() / 2, 50);
			break;
	}
}

// =====================================================================
// THE STRAIT (F112): the end of a spread is a place on the map, not a panel. After the last island the route forks
// into sea stops; sail to one and it happens there. Only Calm water heals (Q14).
// Between a spread's two pages, a buoy offers the workbench the same way (sail to it, or past it).
// =====================================================================

/// @func strait_build()
/// @desc oWorldManager: plans this spread's strait as soon as it's being sailed (strait_draw), so its stops are on the
///       map from the start: since B+ (2026-11-21) just the right page's own sea stop. (spread_end_roll_options is unused now.)
///       Whether each can be taken is checked when you reach it (strait_activate).
function strait_build() {
	// B+ (2026-11-21): the spread ends at the right page's own sea stop, drafted with it. (It used to be a fork of four.)
	var _n = ds_list_size(chosen_pages);
	var _id = (_n > 0) ? page_passage(chosen_pages[| _n - 1]) : "";
	if (_id == "") _id = "calm"; // a page from before B+
	strait = { ids: [_id], scales: [1], heal: 0, chosen: -1, arrived: false, healed: false, stamp: 0, active: false, leaving: false };
}

/// @func strait_activate()
/// @desc The spread's islands are done (WORLD_STATE.STRAIT): the stops can be sailed to. Works out what passing through
///       heals (keepsakes like Salted Pork add to it), and adds calm water (the heal alone) if no stop can be taken.
function strait_activate() {
	if (!is_struct(strait)) strait_build();
	if (strait.active) return;
	strait.active = true;
	oRunManager.can_visit_workbench = false;
	strait.heal = passage_heal_amount();
	// a stop that can't be used now (no tool has work, item slots full, a small bag) becomes calm water
	for (var i = 0; i < array_length(strait.ids); i++) strait.ids[i] = passage_resolve(strait.ids[i]);
}

/// @func spread_sea_spots()
/// @desc Where this spread's sea stops sit, from its two islands' pages: { buoy: {x, y} } just past the left page's
///       island, { strait: {x, y} } past the right page's. Undefined parts on a single-page (boss) spread.
function spread_sea_spots() {
	var _n = ds_list_size(chosen_pages);
	var _out = { buoy: undefined, strait: undefined, left: undefined, right: undefined };
	if (_n < 2 || world_state == WORLD_STATE.DRAFTING || world_state == WORLD_STATE.OPENING) return _out;
	var _l = chosen_pages[| _n - 2], _r = chosen_pages[| _n - 1];
	if (page_is_boss(_r)) return _out;
	var _half = sprite_get_width(sMapParchment) / 2;
	_out.left = _l; _out.right = _r;
	_out.buoy = { x: _l.x + _half + 70, y: _l.y };
	_out.strait = { x: _r.x + _half + 80, y: _r.y };
	return _out;
}

/// @func strait_stop_info(_id, _heal)
/// @desc A sea stop's name and what it does: { name, tip, ok, reason }. Short: what it does, nothing more (Jared, 2026-11-21).
function strait_stop_info(_id, _heal) {
	switch (_id) {
		case "anchor":    return { name: "Drop Anchor", tip: "Rest: heal " + ((_heal > 0) ? string(_heal) + " HP" : string(round(oWorldManager.rest_amount * 100)) + "% of your health") + ". Or go below to the workbench.", ok: true, reason: "" };
		case "sea":       return { name: "Open water", tip: "An event at sea.", ok: true, reason: "" };
		case "workbench": return { name: "Shipwright's buoy", tip: "Use your tools on your dice.", ok: workbench_useful(), reason: "No tool has work to do." };
		case "calm":      return { name: "Calm water", tip: "Heal " + ((_heal > 0) ? string(_heal) + " HP." : string(round(oWorldManager.rest_amount * 100)) + "% of your health."), ok: true, reason: "" };
		case "core":      return { name: "The wreck", tip: "Gain a core.", ok: true, reason: "" }; // full slots: delete an item for it, or sail past (pending_item_draw)
		case "trim":      return { name: "Squall", tip: "Remove a die from your bag.", ok: ds_list_size(global.dice_bag) > 6, reason: "Your bag has 6 dice or fewer." };
		case "whet":      return { name: "Whetstone reef", tip: "Give a die +1 minimum roll.", ok: ds_list_size(global.dice_bag) > 0, reason: "Your bag is empty." };
		case "gold":      return { name: "Flotsam", tip: "Gain 50 gold.", ok: true, reason: "" };
	}
	return { name: "", tip: "", ok: false, reason: "" };
}

/// @func map_visited_tick(_x, _y, _scale, _alpha)
/// @desc A place on the chart you've been (F148): a faded ink tick, as if checked off in pen, with a paper halo so it
///       reads on any icon. Islands' nodes, the Shipwright's buoy and the strait's stops all use it.
function map_visited_tick(_x, _y, _scale = 1, _alpha = 1) {
	var _s = _scale;
	draw_set_alpha(_alpha * 0.8);
	draw_set_color(global.ui_col.paper_hi);
	draw_line_width(_x - 9 * _s, _y, _x - 3 * _s, _y + 7 * _s, 7 * _s);
	draw_line_width(_x - 3 * _s, _y + 7 * _s, _x + 10 * _s, _y - 9 * _s, 7 * _s);
	draw_set_alpha(_alpha * 0.75);
	draw_set_color(global.ui_col.ink);
	draw_line_width(_x - 8 * _s, _y, _x - 3 * _s, _y + 6 * _s, 3.5 * _s);
	draw_line_width(_x - 3 * _s, _y + 6 * _s, _x + 9 * _s, _y - 8 * _s, 3 * _s);
	draw_set_alpha(1);
	draw_set_color(c_white);
}

/// @func sea_stop_draw(_id, _x, _y, _scale, _alpha, _ok, [_done])
/// @desc A sea stop on the map: a round inked badge with what it offers inside (code-drawn, like the dice), greyed
///       when it can't be taken.
function sea_stop_draw(_id, _x, _y, _scale, _alpha, _ok, _done = false) {
	var _s = _scale;
	var _ink = make_color_rgb(42, 29, 18);
	var _blend = _ok ? c_white : c_gray;
	// one soft sea-blue disc (Jared, 2026-11-21: the three rings went), so the dotted courses stop short of the icon
	// the way they do round the island stops. Jared may draw new icons for these.
	if (_done) map_done_disc(_x, _y, 26 * _s, _alpha); // done: grey at half opacity (with its tick, map_done_ring)
	else {
		draw_set_alpha(_alpha * 0.85);
		draw_set_color(_ok ? make_color_rgb(150, 186, 190) : make_color_rgb(150, 150, 150));
		draw_circle(_x, _y, 26 * _s, false);
	}
	draw_set_alpha(_alpha);
	switch (_id) {
		case "anchor": // an anchor: ring, shank, stock and two flukes
			draw_set_color(_ink);
			draw_circle(_x, _y - 13 * _s, 3.5 * _s, true);
			draw_line_width(_x, _y - 10 * _s, _x, _y + 12 * _s, 3 * _s);
			draw_line_width(_x - 7 * _s, _y - 6 * _s, _x + 7 * _s, _y - 6 * _s, 2.5 * _s);
			draw_arc_thick_deg(_x, _y + 2 * _s, 9 * _s, 11.5 * _s, 20, 160, 10); // (this helper's angles run clockwise on screen: 90 is down)
			draw_triangle(_x - 13 * _s, _y - 1 * _s, _x - 7 * _s, _y + 5 * _s, _x - 12 * _s, _y + 7 * _s, false); // flukes point up
			draw_triangle(_x + 13 * _s, _y - 1 * _s, _x + 7 * _s, _y + 5 * _s, _x + 12 * _s, _y + 7 * _s, false);
			break;
		case "sea": // a question mark on the waves
			draw_set_font(ftBig);
			draw_set_halign(fa_center);
			draw_set_valign(fa_middle);
			draw_set_color(_ink);
			draw_text_transformed(_x, _y - 3 * _s, "?", _s, _s, 0);
			draw_line_width(_x - 12 * _s, _y + 13 * _s, _x - 4 * _s, _y + 10 * _s, 2 * _s);
			draw_line_width(_x - 4 * _s, _y + 10 * _s, _x + 4 * _s, _y + 13 * _s, 2 * _s);
			draw_line_width(_x + 4 * _s, _y + 13 * _s, _x + 12 * _s, _y + 10 * _s, 2 * _s);
			break;
		case "workbench": draw_sprite_ext(sToolbag, 0, _x, _y + 2 * _s, 0.62 * _s, 0.62 * _s, 0, _blend, _alpha); break;
		case "core":      draw_sprite_ext(sCores, 0, _x, _y, 0.5 * _s, 0.5 * _s, 0, _blend, _alpha); break;
		case "trim":      draw_sprite_ext(sToolSilhouettes, 1, _x, _y, 0.46 * _s, 0.46 * _s, 0, _ink, _alpha); break;
		case "gold":      draw_sprite_ext(sCoin, 0, _x, _y, 0.55 * _s, 0.55 * _s, 0, _blend, _alpha); break;
		case "whet":
			draw_die_shape(_x - 4 * _s, _y + 2 * _s, 14 * _s, 6, _ink, 0, _alpha);
			draw_die_shape(_x - 4 * _s, _y + 2 * _s, 11 * _s, 6, _ok ? make_color_rgb(242, 210, 74) : c_gray, 0, _alpha);
			draw_set_font(font_tip());
			draw_set_halign(fa_center);
			draw_set_valign(fa_middle);
			draw_outline_text("+1", c_black, c_white, 2, _x + 10 * _s, _y - 10 * _s, _s, _alpha, 0);
			break;
		case "calm":
			draw_set_color(_ink);
			for (var w = -1; w <= 1; w++) {
				var _wy = _y + w * 8 * _s;
				for (var k = 0; k < 3; k++) {
					var _wx = _x - 12 * _s + k * 8 * _s;
					draw_line_width(_wx, _wy, _wx + 4 * _s, _wy - 3 * _s, 2 * _s);
					draw_line_width(_wx + 4 * _s, _wy - 3 * _s, _wx + 8 * _s, _wy, 2 * _s);
				}
			}
			break;
	}
	draw_set_alpha(1);
	draw_set_color(c_white);
}

/// @func strait_stop_spot(_i, _n, _ax, _ay)
/// @desc Where stop _i of _n sits round the strait's anchor: stacked down the page, staggered a little in and out.
function strait_stop_spot(_i, _n, _ax, _ay) {
	return { x: _ax + ((_i mod 2) ? 24 : -24) * (_n > 2), y: _ay + (_i - (_n - 1) / 2) * 130 };
}

/// @func strait_draw(_ax, _ay)
/// @desc oWorldManager Draw GUI, in WORLD_STATE.STRAIT: the stops stacked round _ax, _ay (the outer side of the right
///       page), a dotted course to each. Hover: what it is and the heal; click: the ship sails there. On arrival you
///       heal and the stop happens (trim and whet open the dice picker; the buoy opens the workbench, and the page
///       turns when you come back); an ink stamp shows what you got, then the page turns.
function strait_draw(_ax, _ay) {
	if (!is_struct(strait)) strait_build();
	if (world_state == WORLD_STATE.STRAIT) strait_activate();
	var _n = array_length(strait.ids);
	var _gap = 130;
	var _ok_input = (global.ui_layer == UI_LAYER.BASE) && strait.active;
	for (var i = 0; i < _n; i++) {
		var _id = strait.ids[i];
		var _sp = strait_stop_spot(i, _n, _ax, _ay);
		var _sx = _sp.x, _sy = _sp.y;
		var _info = strait_stop_info(_id, strait.heal);
		var _taken = (strait.chosen == i);
		var _alpha = (strait.chosen == -1 || _taken) ? (strait.active ? 1 : 0.85) : 0.35;
		var _hov = mouse_hovering(_sx, _sy, 64, 64, true, soSlotHover, noone); // it grows under the mouse, like the island stops
		strait.scales[i] = lerp(strait.scales[i], _hov ? 1.25 : 1, 0.2);
		sea_stop_draw(_id, _sx, _sy, strait.scales[i], _alpha, _info.ok || !strait.active, _taken && strait.arrived);
		draw_set_font(font_tip());
		draw_set_halign(fa_center);
		draw_set_valign(fa_top);
		draw_outline_text(_info.name, global.ui_col.paper_hi, (_info.ok || !strait.active) ? global.ui_col.ink : global.ui_col.ink_soft, 2, _sx, _sy + 36 * strait.scales[i], 1, _alpha, 0); // ink, like the chart
		if (_hov && strait.chosen == -1) {
			// ahead (the islands aren't done yet): what it is, and that it's at the end of the spread
			if (!strait.active) queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), _info.name, _info.tip);
			else {
				queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), _info.name, (_info.ok ? _info.tip : _info.reason));
			}
			if (mouse_check_button_pressed(mb_left) && _ok_input) {
				if (_info.ok) strait.chosen = i;
				else throw_error("Not now", _info.reason);
			}
		}

		// Drop Anchor: rest here, or go below to the workbench
		if (_taken && variable_struct_exists(strait, "choosing") && strait.choosing) {
			var _pick = anchor_choice_draw(strait, _sx, _sy);
			if (_pick == "rest") {
				strait.choosing = false;
				strait.arrived = true;
				strait.ids[i] = "calm";
				strait.healed = global.player_hp < global.player_max_hp;
				if (strait.healed) spread_end_apply("heal", strait.heal);
				strait.stamp = 1;
			} else if (_pick == "workbench") {
				world_state = WORLD_STATE.TURNING;
				strait = undefined;
				save_game(1);
				room_goto(rmWorkbench);
				return;
			}
			continue;
		}

		// sailing there
		if (_taken && !strait.arrived && !(variable_struct_exists(strait, "moored") && strait.moored)) {
			if (boat_sail_toward(_sx - 48, _sy + 24)) { // moored beside it, so the tick shows
				strait.arrived = true;
				// Drop Anchor asks first; a sea event goes to the event room (the page turns while you're there)
				if (_id == "anchor") { strait.choosing = true; strait.arrived = false; strait.moored = true; continue; }
				if (_id == "sea") {
					world_state = WORLD_STATE.TURNING;
					strait = undefined;
					sea_event_enter();
					return;
				}
				// only Calm water heals (Q14)
				strait.healed = (_id == "calm") && (global.player_hp < global.player_max_hp);
				if (strait.healed) spread_end_apply("heal", strait.heal);
				if (_id == "workbench") {
					// the page turns while you're at the bench, and the draft is waiting when you come back
					world_state = WORLD_STATE.TURNING;
					strait = undefined;
					room_goto(rmWorkbench);
					return;
				}
				if (_id != "calm") spread_end_apply(_id, strait.heal, _sx, _sy);
				strait.stamp = 1;
			}
		}

		// been there (F148)
		if (_taken && strait.arrived) map_done_ring(_sx, _sy, 31 * strait.scales[i], 1);

		// the ink stamp: what you got, rising off the stop
		if (_taken && strait.arrived) {
			var _what = (_id == "calm") ? "Rested" : _info.name;
			if (strait.healed) _what += "  +" + string(strait.heal) + " HP";
			draw_set_font(ftBig);
			draw_set_halign(fa_center);
			draw_set_valign(fa_middle);
			draw_outline_text(_what, c_black, make_color_rgb(242, 210, 74), 3, _sx, _sy - 56 - 20 * (1 - strait.stamp), 1, min(1, strait.stamp * 2), 0);
		}
	}

	// once the stamp has faded (and any dice picker is closed), the ship sails out to the book's edge; then the page turns
	if (strait.arrived) {
		if (oRunManager.dice_selection == false && oRunManager.pending_item == undefined) strait.stamp = max(0, strait.stamp - 1 / 70);
		if (strait.stamp <= 0) {
			strait.leaving = true;
			if (boat_sail_toward(book_right_x - 10, _ay)) {
				strait = undefined;
				world_state = WORLD_STATE.TURNING;
			}
		}
	}
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
}

/// @func passage_left_draw(_bx, _by)
/// @desc oWorldManager Draw GUI: the left page's sea stop (B+, 2026-11-21), in the gutter between a spread's pages at
///       _bx, _by (spread_sea_spots), on the map the whole spread. Once the left island is done you must sail through
///       it before the right island (map_node_blocked_reason): click it, the ship sails there and it happens
///       (passage_arrive). page.passage_done remembers it (saved with the page). sea_buoy holds its look and stamp.
function passage_left_draw(_bx, _by) {
	var _n = ds_list_size(chosen_pages);
	if (_n < 2) return;
	var _l = chosen_pages[| _n - 2];
	var _id = page_passage(_l);
	if (_id == "") return; // a page from before B+
	if (!is_struct(sea_buoy) || sea_buoy.spread != _n) sea_buoy = { scale: 1, sailing: false, active: false, spread: _n, stamp: 0, healed: false, heal: 0, id: _id, x: _bx, y: _by };
	var _b = sea_buoy;
	_b.x = _bx; _b.y = _by;
	var _done = page_passage_done(_l);
	_b.active = (world_state == WORLD_STATE.EXPLORING) && page_nodes_cleared(_l) && !_done && node_to_move_to == undefined && !_b.sailing;
	var _shown = _b.sailing || _done ? _b.id : _id;
	var _info = strait_stop_info(_shown, passage_heal_amount());
	var _hov = !_b.sailing && mouse_hovering(_bx, _by, 64, 64, true, soSlotHover, noone);
	var _breathe = _b.active ? 0.08 * (0.5 + 0.5 * sin(current_time / 220)) : 0; // it's your next stop: it breathes
	_b.scale = lerp(_b.scale, _hov ? 1.25 : 1 + _breathe, 0.2); // grows under the mouse, like the island stops
	var _salpha = (_done || _b.active || _b.sailing) ? 1 : 0.85; // done: circled with a tick (map_done_ring), not faded
	sea_stop_draw(_shown, _bx, _by, _b.scale, _salpha, true, _done && !_b.sailing);
	draw_set_font(font_tip());
	draw_set_halign(fa_center);
	draw_set_valign(fa_top);
	draw_outline_text(_info.name, global.ui_col.paper_hi, global.ui_col.ink, 2, _bx, _by + 36 * _b.scale, 1, max(_salpha, 0.6), 0); // ink, like the chart
	if (_done && !_b.sailing) map_done_ring(_bx, _by, 31 * _b.scale, 1); // been there (F148)
	draw_set_halign(fa_left);
	if (_hov) {
		var _tip = _info.tip;
		if (!_info.ok && !_done) _tip += "\n" + _info.reason + " For now it's calm water.";
		queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), _info.name, _tip);
		if (mouse_check_button_pressed(mb_left) && _b.active && global.ui_layer == UI_LAYER.BASE) {
			_b.sailing = true;
			_b.id = passage_resolve(_id); // what it really is now (an unusable stop is calm water)
		}
	}
	if (_b.sailing) {
		if (boat_sail_toward(_bx - 48, _by + 24)) { // moored beside it, so the tick shows
			_b.sailing = false;
			oRunManager.can_visit_workbench = false;
			if (_b.id == "anchor") _b.choosing = true; // Drop Anchor: rest or the workbench (anchor_choice_draw, below)
			else if (_b.id == "sea") {
				_l.passage_done = true;
				sea_event_enter(); // the event room; back here after
				return;
			} else {
				_l.passage_done = true;
				if (passage_arrive(_b.id, _b, _bx, _by)) return; // gone to the workbench
			}
		}
	}
	if (variable_struct_exists(_b, "choosing") && _b.choosing) {
		var _pick = anchor_choice_draw(_b, _bx, _by);
		if (_pick != "") {
			_b.choosing = false;
			_l.passage_done = true;
			_b.id = (_pick == "rest") ? "calm" : "workbench";
			if (passage_arrive(_b.id, _b, _bx, _by)) return; // gone to the workbench
		}
	}
	// the ink stamp: what you got, rising off the stop
	if (_b.stamp > 0) {
		var _what = (_b.id == "calm") ? "Rested" : strait_stop_info(_b.id, _b.heal).name;
		if (_b.healed) _what += "  +" + string(_b.heal) + " HP";
		draw_set_font(ftBig);
		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		draw_outline_text(_what, c_black, make_color_rgb(242, 210, 74), 3, _bx, _by - 56 - 20 * (1 - _b.stamp), 1, min(1, _b.stamp * 2), 0);
		if (oRunManager.dice_selection == false && oRunManager.pending_item == undefined) _b.stamp = max(0, _b.stamp - 1 / 70);
		draw_set_halign(fa_left);
		draw_set_valign(fa_top);
	}
}

/// @func passage_arrive(_id, _b)
/// @desc A sea stop reached (the left page's, or the harbour's): it happens. Calm water heals (if hurt); the Shipwright
///       saves and opens the workbench (returns true: the room is changing); the rest apply (spread_end_apply: trim
///       and whet open the dice picker). _b gets heal, healed and stamp for the ink stamp.
function passage_arrive(_id, _b, _x = -1, _y = -1) {
	_b.heal = passage_heal_amount();
	_b.healed = false;
	if (_id == "calm") {
		if (global.player_hp < global.player_max_hp) { spread_end_apply("heal", _b.heal); _b.healed = true; }
	} else if (_id == "workbench") {
		save_game(1); // so Continue doesn't offer this stop again
		room_goto(rmWorkbench);
		return true;
	} else {
		spread_end_apply(_id, _b.heal, _x, _y);
	}
	_b.stamp = 1;
	return false;
}

/// @func anchor_choice_draw(_st, _x, _y)
/// @desc Drop Anchor (2026-11-24): moored at a sea stop, two paper buttons over it: Rest (heal) or Workbench (go
///       below). Returns "rest", "workbench" or "" while you choose. _st keeps the buttons' scales.
function anchor_choice_draw(_st, _x, _y) {
	if (!variable_struct_exists(_st, "anchor_scales")) _st.anchor_scales = [1, 1];
	var _heal = passage_heal_amount();
	var _hurt = global.player_hp < global.player_max_hp;
	var _bench = workbench_useful();
	var _by = _y - 110;
	draw_set_font(font_tip());
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_outline_text("Drop Anchor", global.ui_col.paper_hi, global.ui_col.ink, 2, _x, _by - 52, 1, 1, 0);
	var _rest = ui_button(_x - 95, _by, 170, 56, _st.anchor_scales[0], _hurt ? "Rest  +" + string(_heal) + " HP" : "Rest", global.ui_neutral, true, "", UI_LAYER.BASE, 1, ftDefault);
	_st.anchor_scales[0] = _rest.scale;
	var _wb = ui_button(_x + 95, _by, 170, 56, _st.anchor_scales[1], "Workbench", global.ui_neutral, _bench, "No tool has work to do.", UI_LAYER.BASE, 1, ftDefault);
	_st.anchor_scales[1] = _wb.scale;
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	if (_rest.click) return "rest";
	if (_wb.click && _bench) return "workbench";
	return "";
}

/// @func sea_event_enter()
/// @desc A sea stop's event (2026-11-24): an event node drawn from the sea events (event_is_sea), entered like an
///       island's (enter_node saves and opens the event room). It never turns into a fight or a shop.
function sea_event_enter() {
	var _node = clone_node_static(node_event);
	_node.sea = true;
	_node.event_roll = 100; // no chance of becoming a fight or a shop
	enter_node(_node);
}

/// @func passage_pool()
/// @desc The sea stops a page can bring, with how often (B+). Calm water is the only heal (Q14). Its odds follow your
///       health: 1 at full, up to 5 near death. The Shipwright's go up 2 for each core you hold, up to +4 (Q16).
function passage_pool() {
	// every sea stop is Drop Anchor (rest or the workbench), a sea event, the wreck or Flotsam (Jared, 2026-11-24).
	// 5:3:2:2 gives about 3 Drop Anchors and 2 sea events a chapter (8 sea stops), near the 65/35 asked for
	return [["anchor", 5], ["sea", 3], ["core", 2], ["gold", 2]];
}

/// @func passage_cores_held()
/// @desc How many cores are in your item slots.
function passage_cores_held() {
	var _n = 0;
	for (var i = 0; i < array_length(oRunManager.items); i++) {
		var _it = oRunManager.items[i];
		if (is_struct(_it) && variable_struct_exists(_it, "type") && _it.type == "core") _n++;
	}
	return _n;
}

/// @func pages_assign_passages()
/// @desc generate_pages: gives each offered page its sea stop, all different, and makes sure one of them is Calm water or
///       the Shipwright (the Shipwright only while a tool has work), so bad luck can't leave a spread with neither.
function pages_assign_passages() {
	var _pool = passage_pool();
	var _used = [];
	for (var p = 0; p < ds_list_size(pages_shown); p++) {
		// rolled by weight, repeats allowed (2026-11-24: with four pages, "all different" would force one of each)
		var _total = 0;
		for (var i = 0; i < array_length(_pool); i++) _total += _pool[i][1];
		var _r = irandom_range(1, max(1, _total)), _pick = "anchor";
		for (var i = 0; i < array_length(_pool); i++) {
			_r -= _pool[i][1];
			if (_r <= 0) { _pick = _pool[i][0]; break; }
		}
		array_push(_used, _pick);
		pages_shown[| p].passage = _pick;
		pages_shown[| p].passage_done = false;
	}
	// (2026-11-24: the Shipwright guarantees went with the Shipwright; Drop Anchor holds the workbench now)
}

/// @func page_passage(_page) / page_passage_done(_page) / page_nodes_cleared(_page)
function page_passage(_page) { return (is_struct(_page) && variable_struct_exists(_page, "passage")) ? _page.passage : ""; }
function page_passage_done(_page) { return !is_struct(_page) || !variable_struct_exists(_page, "passage_done") || _page.passage_done; }
function page_nodes_cleared(_page) {
	for (var i = 0; i < ds_list_size(_page.nodes); i++) if (!_page.nodes[| i].cleared) return false;
	return true;
}

/// @func passage_resolve(_id)
/// @desc What a sea stop really is when you get there: itself, or Calm water if it can't be used now (no tool has work,
///       a bag of 6 or fewer). The wreck stays itself with full item slots (pending_item_draw).
function passage_resolve(_id) {
	if (_id == "calm" || _id == "") return "calm";
	if (_id == "anchor" || _id == "sea") return _id; // always usable (Drop Anchor's workbench half can be greyed)
	return strait_stop_info(_id, 0).ok ? _id : "calm";
}

/// @func passage_heal_amount()
/// @desc What Calm water heals now: rest_amount of your health, after on_rest keepsakes (Salted Pork).
function passage_heal_amount() {
	var _ctx = { rest_amount: oWorldManager.rest_amount };
	runmanager_trigger_keepsakes("on_rest", _ctx);
	return ceil(global.player_max_hp * _ctx.rest_amount);
}

/// @func map_sailing_to_sea()
/// @desc Is the ship on its way to a sea stop (the left page's, or the harbour's)? Island clicks wait for it.
function map_sailing_to_sea() {
	with (oWorldManager) {
		if (is_struct(sea_buoy) && sea_buoy.sailing) return true;
		if (is_struct(harbour) && harbour.chosen != -1 && !harbour.arrived) return true;
	}
	return false;
}

/// @func map_node_blocked_reason(_node)
/// @desc Why this island stop can't be sailed to yet, or "": the left page's sea stop comes before the right island,
///       and the harbour before the boss.
function map_node_blocked_reason(_node) {
	with (oWorldManager) {
		var _n = ds_list_size(chosen_pages);
		if (_n == 0) return "";
		var _last = chosen_pages[| _n - 1];
		if (page_is_boss(_last)) {
			if (!(variable_struct_exists(_last, "harbour_done") && _last.harbour_done)) return "Stop at the harbour first.";
			return "";
		}
		// the treasure stop opening spread 3 comes before both islands (F240)
		var _tl = (_n mod 2 == 0) ? chosen_pages[| _n - 2] : _last;
		if (page_treasure_waits(_tl)) return "Open the treasure first.";
		if (_n >= 2 && ds_list_find_index(_last.nodes, _node) != -1) {
			var _l = chosen_pages[| _n - 2];
			if (page_passage(_l) != "" && !page_passage_done(_l) && page_nodes_cleared(_l)) return "Sail through " + strait_stop_info(page_passage(_l), 0).name + " first.";
		}
	}
	return "";
}

/// @func page_passage_badge(_page, _x, _y, _scale, _alpha)
/// @desc A drafting page's sea stop, small, on its bottom right corner, with its name; hover for what it is. Shows what
///       you're drafting along with the island (B+).
function page_passage_badge(_page, _x, _y, _scale, _alpha) {
	var _id = page_passage(_page);
	if (_id == "") return;
	var _info = strait_stop_info(_id, passage_heal_amount());
	var _hov = (_alpha > 0.5) && mouse_hovering(_x, _y, 56 * _scale, 56 * _scale, true, noone, noone);
	sea_stop_draw(_id, _x, _y, _scale * (_hov ? 1.12 : 1), _alpha, true);
	draw_set_font(font_tip());
	draw_set_halign(fa_center);
	draw_set_valign(fa_top);
	draw_outline_text(_info.name, global.ui_col.paper_hi, global.ui_col.ink, 2, _x, _y + 32 * _scale, 1, _alpha, 0);
	draw_set_halign(fa_left);
	if (_hov) queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), _info.name, _info.tip + (_info.ok ? "" : "\n" + _info.reason + " For now it's calm water."));
}

/// @func harbour_draw(_bp)
/// @desc The boss spread (B+): a harbour before the boss, on the left page. Two moorings, Calm water (rest) and the
///       Shipwright (refit); choose one, sail there, then on to the boss (map_node_blocked_reason waits for it).
///       _bp.harbour_done is saved with the page.
function harbour_draw(_bp) {
	var _gw = display_get_gui_width(), _gh = display_get_gui_height();
	var _hx = _gw * 0.36;
	var _ids = ["calm", "workbench"], _names = ["Drop Anchor: rest", "Drop Anchor: workbench"];
	var _ys = [_gh / 2 - 120, _gh / 2 + 120];
	if (!is_struct(harbour) || harbour.chapter != chapter) harbour = { chapter: chapter, scales: [1, 1], chosen: -1, arrived: false, stamp: 0, healed: false, heal: 0 };
	var _h = harbour;
	var _done = variable_struct_exists(_bp, "harbour_done") && _bp.harbour_done;
	var _bn = (ds_list_size(_bp.nodes) > 0) ? _bp.nodes[| 0] : undefined;
	var _heal = passage_heal_amount();
	for (var i = 0; i < 2; i++) {
		var _sx = _hx + ((i == 0) ? -20 : 20), _sy = _ys[i];
		var _mine = (_h.chosen == i);
		var _a_route = _mine ? 0.85 : ((_h.chosen == -1 && !_done) ? 0.38 : 0.12);
		route_draw(book_left_x, _gh / 2, _sx, _sy, _a_route);
		if (_bn != undefined) route_draw(_sx, _sy, _bn.x, _bn.y, (_mine && _bn.cleared) ? 0.85 : _a_route);
	}
	for (var i = 0; i < 2; i++) {
		var _id = _ids[i];
		var _sx = _hx + ((i == 0) ? -20 : 20), _sy = _ys[i];
		var _info = strait_stop_info(_id, _heal);
		var _can = !_done && _h.chosen == -1 && world_state == WORLD_STATE.EXPLORING && node_to_move_to == undefined && !boat_data.entering;
		var _hov = mouse_hovering(_sx, _sy, 64, 64, true, soSlotHover, noone);
		var _alpha = (_h.chosen == -1 && !_done) ? 1 : ((_h.chosen == i) ? 1 : 0.35);
		_h.scales[i] = lerp(_h.scales[i], _hov ? 1.25 : 1, 0.2);
		sea_stop_draw(_id, _sx, _sy, _h.scales[i], _alpha, _info.ok || _done, _h.chosen == i && _h.arrived);
		draw_set_font(font_tip());
		draw_set_halign(fa_center);
		draw_set_valign(fa_top);
		draw_outline_text(_names[i], global.ui_col.paper_hi, global.ui_col.ink, 2, _sx, _sy + 36 * _h.scales[i], 1, _alpha, 0);
		draw_set_halign(fa_left);
		if (_h.chosen == i && _h.arrived) map_done_ring(_sx, _sy, 31 * _h.scales[i], 1);
		if (_hov) {
			var _tip = _info.ok ? _info.tip : _info.reason;
			queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), _names[i], _tip);
			if (mouse_check_button_pressed(mb_left) && _can && global.ui_layer == UI_LAYER.BASE) {
				if (_info.ok) _h.chosen = i;
				else throw_error("Not now", _info.reason);
			}
		}
		if (_h.chosen == i && !_h.arrived) {
			if (boat_sail_toward(_sx - 48, _sy + 24)) { // moored beside it, so the tick shows
				_h.arrived = true;
				_bp.harbour_done = true;
				if (passage_arrive(_id, _h, _sx, _sy)) return; // gone to the workbench
			}
		}
		if (_h.chosen == i && _h.stamp > 0) {
			var _what = (_id == "calm") ? "Rested" : "Refitted";
			if (_h.healed) _what += "  +" + string(_h.heal) + " HP";
			draw_set_font(ftBig);
			draw_set_halign(fa_center);
			draw_set_valign(fa_middle);
			draw_outline_text(_what, c_black, make_color_rgb(242, 210, 74), 3, _sx, _sy - 56 - 20 * (1 - _h.stamp), 1, min(1, _h.stamp * 2), 0);
			_h.stamp = max(0, _h.stamp - 1 / 70);
			draw_set_halign(fa_left);
			draw_set_valign(fa_top);
		}
	}
}

/// @func page_treasure_waits(_page)
/// @desc Does this (left) page have a treasure stop still to open? (F240)
function page_treasure_waits(_page) {
	return is_struct(_page) && variable_struct_exists(_page, "treasure_stop") && _page.treasure_stop && !(variable_struct_exists(_page, "treasure_done") && _page.treasure_done);
}

/// @func treasure_stop_pos(_lp)
/// @desc Where the treasure stop sits: in the sea between the book's left edge and the left island's first stop.
function treasure_stop_pos(_lp) {
	var _gh = display_get_gui_height();
	var _fx = (ds_list_size(_lp.nodes) > 0) ? _lp.nodes[| 0].x : display_get_gui_width() * 0.3;
	return { x: lerp(book_left_x, _fx, 0.5), y: _gh / 2 - 90 };
}

/// @func treasure_stop_draw(_lp)
/// @desc Spread 3 of every chapter opens with a treasure stop before the two drafted islands (F240, Jared 2026-11-23:
///       instead of forcing a treasure onto the pages and linking them). Click it, the ship sails there, and the
///       treasure room opens (enter_node with a treasure node; its keepsake is rolled here and kept on the page, so a
///       save brings back the same one). The islands wait for it (map_node_blocked_reason).
function treasure_stop_draw(_lp) {
	if (!is_struct(_lp) || !variable_struct_exists(_lp, "treasure_stop") || !_lp.treasure_stop) return;
	var _p = treasure_stop_pos(_lp);
	if (!is_struct(treasure_stop) || treasure_stop.page != _lp) treasure_stop = { page: _lp, node: clone_node_static(node_treasure), scale: 1, sailing: false };
	var _ts = treasure_stop;
	_ts.node.x = _p.x;
	_ts.node.y = _p.y;
	var _done = _lp.treasure_done;
	var _can = !_done && !_ts.sailing && world_state == WORLD_STATE.EXPLORING && node_to_move_to == undefined;
	var _hov = !_done && mouse_hovering(_p.x, _p.y, 64, 64, true, soSlotHover, noone);
	_ts.scale = lerp(_ts.scale, _hov ? 1.25 : 1, 0.2);
	if (!_done) {
		// it breathes until it's opened
		var _br = 0.5 + 0.5 * sin(current_time / 260);
		draw_set_alpha(0.6 + 0.4 * _br);
		draw_set_color(global.ui_col.brass);
		for (var k = 0; k < 4; k++) draw_circle(_p.x, _p.y, (30 + 2 * _br) * _ts.scale + k, true);
		draw_set_alpha(1);
	}
	map_node_icon_draw(_ts.node, _ts.scale, 1);
	if (_done) map_done_ring(_p.x, _p.y, 31, 1);
	draw_set_font(font_tip());
	draw_set_halign(fa_center);
	draw_set_valign(fa_top);
	draw_outline_text("Treasure", global.ui_col.paper_hi, global.ui_col.ink, 2, _p.x, _p.y + 36 * _ts.scale, 1, 1, 0);
	draw_set_halign(fa_left);
	if (_hov) {
		queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Treasure", "Gain a keepsake.");
		if (mouse_check_button_pressed(mb_left) && _can && global.ui_layer == UI_LAYER.BASE) {
			_ts.sailing = true;
			boat_data.entering = false; // it takes over from sailing in from the book's edge
			boat_data.voyage = undefined;
		}
	}
	if (_ts.sailing && boat_sail_toward(_p.x - 48, _p.y + 24)) { // moored beside it, so the tick shows
		_ts.sailing = false;
		if (_lp.treasure_keepsake == "") {
			var _rolled = ds_list_create();
			generate_keepsake_rewards(_rolled, global.rollable_keepsake_list, 1);
			if (ds_list_size(_rolled) > 0) _lp.treasure_keepsake = _rolled[| 0]._id;
			ds_list_destroy(_rolled);
		}
		var _node = clone_node_static(node_treasure);
		_node.treasure_keepsake = _lp.treasure_keepsake;
		enter_node(_node); // saves first, with the treasure still to open, so quitting in the room keeps it (room_goto waits a step)
		_lp.treasure_done = true; // saved when the map room starts again
	}
}

/// @func route_draw(_x1, _y1, _x2, _y2, _alpha)
/// @desc A dotted S-curve course between two map stops (a cubic Bezier leaving and arriving level), its dots stopping
///       short of both ends so they don't run under the icons. Ink brown; _alpha says taken (strong) or possible (faint).
function route_draw(_x1, _y1, _x2, _y2, _alpha) {
	if (_alpha <= 0) return;
	var _mx = (_x1 + _x2) / 2;
	var _steps = 48, _px = _x1, _py = _y1, _len = 0;
	var _xs = [_x1], _ys = [_y1], _ls = [0];
	for (var i = 1; i <= _steps; i++) {
		var _t = i / _steps, _u = 1 - _t;
		var _x = _u*_u*_u*_x1 + 3*_u*_u*_t*_mx + 3*_u*_t*_t*_mx + _t*_t*_t*_x2;
		var _y = _u*_u*_u*_y1 + 3*_u*_u*_t*_y1 + 3*_u*_t*_t*_y2 + _t*_t*_t*_y2;
		_len += point_distance(_px, _py, _x, _y);
		array_push(_xs, _x); array_push(_ys, _y); array_push(_ls, _len);
		_px = _x; _py = _y;
	}
	draw_set_color(make_color_rgb(42, 29, 18));
	draw_set_alpha(_alpha);
	var _k = 0;
	for (var _d = 30; _d <= _len - 30; _d += 13) {
		while (_k < _steps - 1 && _ls[_k + 1] < _d) _k++;
		var _f = (_ls[_k + 1] > _ls[_k]) ? (_d - _ls[_k]) / (_ls[_k + 1] - _ls[_k]) : 0;
		draw_circle(lerp(_xs[_k], _xs[_k + 1], _f), lerp(_ys[_k], _ys[_k + 1], _f), 3.2, false);
	}
	draw_set_alpha(1);
	draw_set_color(c_white);
}

/// @func spread_routes_draw(_spots)
/// @desc The courses between this spread's stops, like a chart (oWorldManager Draw GUI, over the islands, under the
///       stops and ship): each island's nodes in order; the left island's last to the buoy and to the right island's
///       first (sail past); the buoy on to it; the right island's last to each strait stop; in from the book's left
///       edge and out from each strait stop to its right edge (book_left_x, book_right_x). Taken courses are inked
///       strong, possible ones faint, ones you passed by fainter still.
function spread_routes_draw(_spots) {
	if (_spots.left == undefined) return;
	var _taken = 0.85, _poss = 0.38, _gone = 0.12;
	var _L = _spots.left.nodes, _R = _spots.right.nodes;
	var _ln = ds_list_size(_L), _rn = ds_list_size(_R);
	// in from the book's left edge to the first island (by the treasure stop on spread 3, F240)
	if (_ln > 0) {
		if (variable_struct_exists(_spots.left, "treasure_stop") && _spots.left.treasure_stop) {
			var _tp = treasure_stop_pos(_spots.left);
			route_draw(book_left_x, display_get_gui_height() / 2, _tp.x, _tp.y, _spots.left.treasure_done ? _taken : _poss);
			route_draw(_tp.x, _tp.y, _L[| 0].x, _L[| 0].y, _L[| 0].cleared ? _taken : _poss);
		} else route_draw(book_left_x, display_get_gui_height() / 2, _L[| 0].x, _L[| 0].y, _L[| 0].cleared ? _taken : _poss);
	}
	for (var i = 0; i < _ln - 1; i++) route_draw(_L[| i].x, _L[| i].y, _L[| i + 1].x, _L[| i + 1].y, _L[| i + 1].cleared ? _taken : _poss);
	for (var i = 0; i < _rn - 1; i++) route_draw(_R[| i].x, _R[| i].y, _R[| i + 1].x, _R[| i + 1].y, _R[| i + 1].cleared ? _taken : _poss);
	if (_ln > 0 && _rn > 0) {
		var _a = _L[| _ln - 1], _b = _R[| 0];
		// B+: through the left page's sea stop, always (an old save's page has none: straight across)
		var _bx = _spots.buoy.x, _by = _spots.buoy.y;
		if (page_passage(_spots.left) != "") {
			var _passed = page_passage_done(_spots.left);
			route_draw(_a.x, _a.y, _bx, _by, _passed ? _taken : _poss);
			route_draw(_bx, _by, _b.x, _b.y, _b.cleared ? _taken : _poss);
		} else route_draw(_a.x, _a.y, _b.x, _b.y, _b.cleared ? _taken : _poss);
	}
	if (_rn > 0 && is_struct(strait)) {
		var _z = _R[| _rn - 1];
		var _n = array_length(strait.ids);
		for (var s = 0; s < _n; s++) {
			var _sp = strait_stop_spot(s, _n, _spots.strait.x, _spots.strait.y);
			route_draw(_z.x, _z.y, _sp.x, _sp.y, (strait.chosen == s) ? _taken : (strait.chosen == -1 ? _poss : _gone));
			// and out of the spread from each, to the book's right edge
			route_draw(_sp.x, _sp.y, book_right_x, _spots.strait.y, (strait.chosen == s && strait.leaving) ? _taken : (strait.chosen == -1 || strait.chosen == s ? _poss : _gone));
		}
	}
}

/// @func boat_sail_toward(_tx, _ty)
/// @desc oWorldManager: moves the ship one frame along a voyage to _tx, _ty and returns true once it's there. A voyage
///       eases in and out (smootherstep over a time set by its length), and it's perilous: the ship weaves side to side
///       across its course (strongest mid-voyage, none at the ends), pitches into each turn and heels over with the
///       weave (boat_data.tilt, added to its angle when drawn). A new target starts a new voyage from where it is.
function boat_sail_toward(_tx, _ty) {
	var _v = boat_data.voyage;
	if (!is_struct(_v) || point_distance(_v.x1, _v.y1, _tx, _ty) > 40) {
		var _len = point_distance(boat_data.x, boat_data.y, _tx, _ty);
		_v = { x0: boat_data.x, y0: boat_data.y, x1: _tx, y1: _ty, t: 0, dur: clamp(_len / 4.6, 26, 95), waves: max(1, round(_len / 200)) }; // (round 2: a third quicker)
		boat_data.voyage = _v;
	}
	_v.x1 = _tx; _v.y1 = _ty; // a stop that drifts a little is followed, not restarted
	_v.t = min(1, _v.t + 1 / _v.dur);
	var _t = _v.t;
	var _e = _t * _t * (3 - 2 * _t); // smoothstep: eased at both ends, but quicker off the mark than smootherstep (round 2)
	var _dir = point_direction(_v.x0, _v.y0, _v.x1, _v.y1);
	// the weave: across the course, swelling mid-voyage
	var _amp = 16 * sin(_t * pi);
	var _side = _amp * sin(_t * pi * 2 * _v.waves);
	boat_data.x = lerp(_v.x0, _v.x1, _e) + lengthdir_x(_side, _dir + 90);
	boat_data.y = lerp(_v.y0, _v.y1, _e) + lengthdir_y(_side, _dir + 90);
	// heel with the weave and pitch with the swell
	boat_data.tilt = 9 * sin(_t * pi) * cos(_t * pi * 2 * _v.waves) + 4 * sin(_t * pi * 6) * sin(_t * pi);
	if (_t >= 1) {
		boat_data.voyage = undefined;
		boat_data.x = _v.x1; boat_data.y = _v.y1;
		return true;
	}
	return false;
}

/// @func map_waves_draw(_x1, _y1, _x2, _y2)
/// @desc oWorldManager Draw GUI, over the book's water pages and under the islands: now and then a small wave rises,
///       drifts a little and fades, somewhere on the sea (Jared, 2026-11-21: subtle and infrequent, like the clouds in
///       a fight). A few at a time; the islands drawn after cover any that land on them.
function map_waves_draw(_x1, _y1, _x2, _y2) {
	if (!variable_instance_exists(id, "map_waves")) map_waves = [];
	if (random(1) < 1 / 50 && array_length(map_waves) < 6) {
		array_push(map_waves, { x: random_range(_x1 + 30, _x2 - 30), y: random_range(_y1 + 30, _y2 - 30), t: 0, life: irandom_range(150, 230), w: random_range(14, 24) });
	}
	for (var i = array_length(map_waves) - 1; i >= 0; i--) {
		var _w = map_waves[i];
		_w.t++;
		if (_w.t >= _w.life) { array_delete(map_waves, i, 1); continue; }
		var _f = _w.t / _w.life;
		var _a = 0.32 * sin(_f * pi); // fades in, then out
		var _x = _w.x + _f * 10, _y = _w.y - _f * 3; // drifts with the wind
		draw_set_alpha(_a);
		draw_set_color(make_color_rgb(240, 246, 244));
		// two little crests, like an inked "~"
		for (var c = 0; c < 2; c++) {
			var _cx = _x + c * _w.w * 0.9, _cy = _y + c * 4;
			var _steps = 8, _px = _cx - _w.w / 2, _py = _cy;
			for (var k = 1; k <= _steps; k++) {
				var _nx = _cx - _w.w / 2 + _w.w * k / _steps;
				var _ny = _cy - sin(k / _steps * pi) * 4;
				draw_line_width(_px, _py, _nx, _ny, 2);
				_px = _nx; _py = _ny;
			}
		}
	}
	draw_set_alpha(1);
	draw_set_color(c_white);
}

/// @func map_icon_draw(_spr, _sub, _x, _y, _scale, _alpha, _done)
/// @desc A map stop's icon: Jared's sprite in full colour, reachable or not (Jared, 2026-11-21). _done: it sits on a
///       50% grey disc (map_done_ring adds the tick).
function map_icon_draw(_spr, _sub, _x, _y, _scale, _alpha, _done = false) {
	if (_done) map_done_disc(_x, _y, 30 * _scale, _alpha);
	draw_sprite_ext(_spr, _sub, _x, _y, _scale, _scale, 0, c_white, _alpha);
}

/// @func map_done_disc(_x, _y, _r, _alpha)
/// @desc Behind a done stop: a grey disc at half opacity (not green).
function map_done_disc(_x, _y, _r, _alpha = 1) {
	draw_set_alpha(0.5 * _alpha);
	draw_set_color(make_color_rgb(128, 128, 128));
	draw_circle(_x, _y, _r, false);
	draw_set_alpha(1);
	draw_set_color(c_white);
}

/// @func map_done_ring(_x, _y, _r, _alpha) (now just the tick: the grey disc is drawn under the icon, map_done_disc)
/// @desc A stop you've been to: circled in ink (with a paper halo so it reads on land or sea), and a tick on the ring's
///       top right (Jared, 2026-11-21: no fading).
function map_done_ring(_x, _y, _r, _alpha = 1) {
	map_visited_tick(_x + _r * 0.72, _y - _r * 0.72, 1.1, _alpha);
}

/// @func page_passage_preview(_page, _px, _py, _scale, _alpha)
/// @desc While drafting: a page's sea stop where it will sit on the chart (to the right of the page, level with its
///       middle, as spread_sea_spots puts it), with the dotted course from the page's last stop out to it (Jared,
///       2026-11-21: previews that look like the real layout). _px, _py: the page's centre; _scale: its drawn scale.
function page_passage_preview(_page, _px, _py, _scale, _alpha, _inside = false) {
	if (page_passage(_page) == "") return;
	var _sx = _px + (sprite_get_width(sMapParchment) / 2 + 66) * _scale, _sy = _py;
	// on a drafting card (_inside): in its right part, with room round it (the whole card is sea, so no box behind it)
	if (_inside) _sx = _px + DRAFT_CARD_W * _scale * 0.29;
	var _n = ds_list_size(_page.nodes);
	if (_n > 0) {
		var _last = _page.nodes[| _n - 1];
		route_draw(_last.x, _last.y, _sx, _sy, 0.55 * _alpha);
	}
	page_passage_badge(_page, _sx, _sy, _scale, _alpha);
}

/// @func page_burn_draw(_page, _x, _y, _index)
/// @desc The draft page the first pick lost (Jared, 2026-11-21: not chains, it burns away): drawn as usual into burn_surf,
///       then through shBurn, whose flame front scorches it brown, glows ember orange at its edge and leaves nothing
///       behind, over about 62 frames (page.burn_t 0 to 1). A few embers and wisps of smoke rise off it (kept sparse so the
///       shader shows).
function page_burn_draw(_page, _x, _y, _index) {
	if (!variable_struct_exists(_page, "burn_t")) {
		_page.burn_t = 0;
		particle_emit_later(_x, _y, "burst", make_color_rgb(255, 150, 50), 8); // it catches
		sfx_play(soTorch, AUDIO_GROUP.SFX, 0.05, 0.8);
	}
	if (_page.burn_t >= 1) return;
	_page.burn_t = min(1, _page.burn_t + 1 / 62); // about a second (Jared: a little quicker)
	var _gw = display_get_gui_width(), _gh = display_get_gui_height();
	if (!surface_exists(burn_surf)) burn_surf = surface_create(_gw, _gh);
	surface_set_target(burn_surf);
	draw_clear_alpha(c_black, 0);
	draw_page(_page, _x, _y, _index, true, false);
	page_passage_preview(_page, _x, _y, (_index < ds_list_size(page_scale)) ? page_scale[| _index] : 1, pages_alpha, true);
	surface_reset_target();

	// the flame front: slow to catch, then quicker (eased), from just before the page to past it
	var _f = _page.burn_t;
	var _t = lerp(-0.15, 1.05, _f * _f * (3 - 2 * _f));
	shader_set(shBurn);
	shader_set_uniform_f(shader_get_uniform(shBurn, "u_t"), _t);
	shader_set_uniform_f(shader_get_uniform(shBurn, "u_seed"), _index * 3.7 + _page.island_index * 1.3);
	shader_set_uniform_f(shader_get_uniform(shBurn, "u_scale"), _gw / 120, _gh / 120);
	draw_surface(burn_surf, 0, 0);
	shader_reset();

	// embers (and a little smoke) rising off the card while it burns
	var _hw = DRAFT_CARD_W / 2, _hh = DRAFT_CARD_H / 2;
	if (_f < 0.9) {
		if (random(1) < 0.5) particle_emit_later(_x + random_range(-_hw, _hw), _y + random_range(-_hh, _hh), "rise", choose(make_color_rgb(255, 170, 60), make_color_rgb(255, 110, 30), make_color_rgb(255, 220, 120)), 1);
		if (random(1) < 0.12) particle_emit_later(_x + random_range(-_hw, _hw), _y + random_range(-_hh, _hh), "rise", make_color_rgb(70, 64, 58), 1);
	}
}

/// @func node_morph_into(_old, _template)
/// @desc A drafting page's stop that has to change (only one page keeps its treasure or elite): the new node, which
///       remembers what it was and shows the old icon until the lost page has burned, then turns into the new one
///       (map_node_icon_draw). Jared, 2026-11-21.
function node_morph_into(_old, _template) {
	var _new = clone_node_static(_template);
	_new.morph_from = _old.subimg;
	_new.morph_name = _old.name;
	_new.morph_t = -62; // about the burn's length, then the change
	if (variable_struct_exists(_old, "pool_type")) _new.pool_type = _old.pool_type; // the token it came from goes back if the page isn't taken
	return _new;
}

/// @func page_has_morph(_page)
function page_has_morph(_page) {
	for (var i = 0; i < ds_list_size(_page.nodes); i++) if (variable_struct_exists(_page.nodes[| i], "morph_t")) return true;
	return false;
}

/// @func map_node_icon_draw(_node, _scale, _alpha)
/// @desc A map stop's icon (map_icon_draw), with its change if it's turning into something else (node_morph_into): the
///       old icon until morph_t reaches 0, then it shrinks away, a puff, and the new one pops up.
function map_node_icon_draw(_node, _scale, _alpha) {
	var _linked = variable_struct_exists(_node, "linked") && _node.linked;
	if (_linked) {
		// linked to the same stop on another page: a gold ring that breathes (thicker: Jared, 2026-11-22)
		var _lp = 0.5 + 0.5 * sin(current_time / 260);
		draw_set_alpha(_alpha * (0.6 + 0.4 * _lp));
		draw_set_color(global.ui_col.brass);
		for (var k = 0; k < 6; k++) draw_circle(_node.x, _node.y, (30 + 2 * _lp) * _scale + k, true);
		draw_set_alpha(1);
	}
	map_node_icon_body(_node, _scale, _alpha);
	if (_linked) map_link_badge(_node.x, _node.y + 33 * _scale, _scale, _alpha); // a chain link on the ring's bottom edge
}

/// @func map_link_badge(_x, _y, _scale, _alpha)
/// @desc A small brass disc with two chain links on it: the mark of a linked stop (map_node_icon_draw).
function map_link_badge(_x, _y, _scale, _alpha) {
	var _r = 11 * _scale;
	draw_set_alpha(_alpha);
	draw_set_color(global.ui_col.ink);
	draw_circle(_x, _y, _r + 2, false);
	draw_set_color(global.ui_col.brass);
	draw_circle(_x, _y, _r, false);
	draw_set_color(global.ui_col.ink);
	for (var s = -1; s <= 1; s += 2) {
		var _lx = _x + s * 3.5 * _scale;
		for (var t = 0; t < 2; t++) draw_ellipse(_lx - 5.5 * _scale - t, _y - 3.5 * _scale - t, _lx + 5.5 * _scale + t, _y + 3.5 * _scale + t, true);
	}
	draw_set_alpha(1);
}

/// @func map_node_icon_body(_node, _scale, _alpha)
/// @desc The icon itself, mid-change or not (map_node_icon_draw).
function map_node_icon_body(_node, _scale, _alpha) {
	if (variable_struct_exists(_node, "morph_t")) {
		_node.morph_t++;
		var _t = _node.morph_t;
		if (_t < 0) { map_icon_draw(sMapIcon, _node.morph_from, _node.x, _node.y, _scale, _alpha, false); return; }
		if (_t < 10) { map_icon_draw(sMapIcon, _node.morph_from, _node.x, _node.y, _scale * (1 - _t / 10), _alpha, false); return; }
		if (_t == 10) particle_emit_later(_node.x, _node.y, "burst", global.ui_col.brass, 10);
		if (_t < 26) { map_icon_draw(sMapIcon, _node.subimg, _node.x, _node.y, _scale * (1 + 0.45 * sin((_t - 10) / 16 * pi)), _alpha, false); return; }
		variable_struct_remove(_node, "morph_t");
	}
	map_icon_draw(sMapIcon, _node.subimg, _node.x, _node.y, _scale, _alpha, _node.cleared);
}

/// @func draft_links_mark(_count)
/// @desc oWorldManager Draw GUI, drafting: marks the treasure and elite stops that more than one offered page has
///       (node.linked), since picking one page takes them off the others. Only before the first pick.
function draft_links_mark(_count) {
	var _types = [NODE_TYPE.TREASURE, NODE_TYPE.ELITE];
	for (var t = 0; t < array_length(_types); t++) {
		var _found = [];
		for (var p = 0; p < _count; p++) {
			var _pg = pages_shown[| p];
			for (var n = 0; n < ds_list_size(_pg.nodes); n++) {
				var _nd = _pg.nodes[| n];
				_nd.linked = false;
				if (_nd.type == _types[t] && !_pg.locked) array_push(_found, _nd);
			}
		}
		if (array_length(_found) >= 2 && pages_drafted == 0) for (var i = 0; i < array_length(_found); i++) _found[i].linked = true;
	}
}

/// @func draft_links_draw(_count)
/// @desc Draws the links between linked stops (draft_links_mark): a dashed brass line from each to the next, across
///       the cards, so it's plain that only one page keeps it.
function draft_links_draw(_count) {
	var _types = [NODE_TYPE.TREASURE, NODE_TYPE.ELITE];
	for (var t = 0; t < array_length(_types); t++) {
		var _pts = [];
		for (var p = 0; p < _count; p++) {
			var _pg = pages_shown[| p];
			for (var n = 0; n < ds_list_size(_pg.nodes); n++) {
				var _nd = _pg.nodes[| n];
				if (_nd.type == _types[t] && variable_struct_exists(_nd, "linked") && _nd.linked) array_push(_pts, _nd);
			}
		}
		for (var i = 1; i < array_length(_pts); i++) {
			var _a = _pts[i - 1], _b = _pts[i];
			var _len = point_distance(_a.x, _a.y, _b.x, _b.y), _dir = point_direction(_a.x, _a.y, _b.x, _b.y);
			var _off = (current_time / 40) mod 22; // the dashes drift, so it reads as a live link
			draw_set_alpha(0.75 * pages_alpha);
			draw_set_color(global.ui_col.brass);
			for (var d = 36 + _off; d < _len - 36; d += 22) {
				draw_line_width(_a.x + lengthdir_x(d, _dir), _a.y + lengthdir_y(d, _dir), _a.x + lengthdir_x(min(d + 11, _len - 36), _dir), _a.y + lengthdir_y(min(d + 11, _len - 36), _dir), 3);
			}
			draw_set_alpha(1);
		}
	}
}
