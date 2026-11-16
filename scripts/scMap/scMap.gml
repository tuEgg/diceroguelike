/// @func generate_pages
function generate_pages() {
	var num_combat = 0; // generate no more than 5 across all 3 pages
	var num_event = 0; // generate no more than 3 across all 3 pages
	var num_shop = 0; // generate no more than 2 across all 3 pages
	var num_bounty = 0; // generate no more than 1 bounty across all 3 pages
	var num_elite = 0; // each page has an elite at the same time???
	var num_alignment = 0; // generate no more than 1 across all 3 pages
	
	// Generate 3 pages
	repeat (3) {
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
		
		// count the nodes per page
		var page_num_combat = 0;
		var page_num_event = 0;
		var page_num_shop = 0; // generate no more than 1 per page
		var page_num_bounty = 0;
		var page_num_elite = 0;
	
		// add the nodes
		do {
			var chosen_node = node_combat;
			var page_num = ds_list_size(pages_shown); // 0, 1 or 2
			
			var rand = irandom_range(1,100);
			
			// after 4, 12, 20 pages etc.
			if ((oWorldManager.pages_cleared + 4) mod 8 == 0) && (ds_list_size(_page.nodes) == 0) {
				chosen_node = node_treasure; // add a treasure node
			} else {
				if (rand <= combat_chance) {
					if (num_combat < 5) {
						num_combat++;
						page_num_combat++;
						chosen_node = node_combat;
						combat_chance -= 5;
					
						var rand_inc = (irandom(1));
					
						switch (rand_inc) {
							case 0: event_chance += 5; break;
							case 1: shop_chance += 5; break;
						}
					
					} else {
						continue;
					}
				} else if (rand <= combat_chance + event_chance) {
					if (num_event < 3) {
						num_event++;
						page_num_event++;
						chosen_node = node_event;
						event_chance -= 5;
					
						var rand_inc = (irandom(1));
					
						switch (rand_inc) {
							case 0: combat_chance += 5; break;
							case 1: shop_chance += 5; break;
						}
					} else {
						continue;
					}
				} else if (rand <= combat_chance + event_chance + shop_chance) {
					if (num_shop < 1) {
						num_shop++;
						page_num_shop++;
						chosen_node = node_shop;
						shop_chance -= 5;
					
						if (nodes_cleared < 5) {
							combat_chance += 5;
						} else if (oRunManager.active_bounty == undefined && bounty_nodes_this_voyage == 0) {
							bounty_chance += 5;
						} else {
							combat_chance += 5;
						}
					} else {
						continue;
					}
				} else if (rand <= combat_chance + event_chance + shop_chance + bounty_chance) {
					if (num_bounty < 1 && page_num_bounty == 0) {
						num_bounty++;
						page_num_bounty++;
						chosen_node = node_bounty;
						var gap = bounty_chance;
						bounty_chance = 0;
						combat_chance += ceil(gap * (2/5));
						event_chance += floor(gap * (2/5));
						shop_chance += floor(gap * (1/5));
					
					} else {
						continue;
					}
				} else if (rand <= combat_chance + event_chance + shop_chance + bounty_chance + elite_chance) {
					if (num_elite < 2 && page_num_elite == 0) {
						num_elite++;
						page_num_elite++;
						chosen_node = node_elite;
						
						var amount = round(elite_chance/2);
						elite_chance -= amount;
						combat_chance += ceil(amount * 2/5);
						event_chance += floor(amount * 3/5);
					} else {
						continue;
					}
				} else if (rand <= combat_chance + event_chance + shop_chance + bounty_chance + elite_chance + alignment_chance) {
					if (num_alignment < 1 && page_num_elite == 0) { // don't draft alignment and elites on the same page
						num_alignment++;
						chosen_node = node_alignment;
					} else {
						continue;
					}
				}
			
				// First node of each run is always combat
				if (oWorldManager.nodes_cleared == 0) && (ds_list_size(_page.nodes) == 0) {
					chosen_node = node_combat;
				}
			}
			
			ds_list_add(_page.nodes, clone_node_static(chosen_node));
		} until (ds_list_size(_page.nodes) == _page.num_nodes);
	
		ds_list_add(pages_shown, _page);
	}
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
	
	// an event node picks its event now (the event room shows it), so it can be saved with the node
	if (_node.type == NODE_TYPE.EVENT) {
		var _has_event = variable_struct_exists(_memory_node, "event_name") && is_string(_memory_node.event_name) && _memory_node.event_name != "";
		if (!_has_event) {
			if (ds_list_size(global.master_event_list) == 0) define_events();
			_memory_node.event_name = global.master_event_list[| irandom(ds_list_size(global.master_event_list) - 1)].name;
		}
	}
	
	// saved before the node is marked cleared, so Continue comes back to the map with this node still to play
	save_game(1);
	
	room_goto(_node.linked_room);
}

/// @param _node			the node being entered (an event may have turned into a combat clone)
/// @param _memory_node	the node on the map, which remembers the encounter it rolled
function get_combat_enemies(_node, _memory_node = _node) {
	
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
	    // highest priority
	    _blend = make_color_rgb(100, 186, 186); 
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
		
	var pages_hover = mouse_hovering(page_x, page_y, page_width, page_height, true, soPaperHover, soClick4, !_locked * !page.chosen);
	_scale = lerp(_scale, pages_hover ? 1.2 : 1.0, 0.2);
		
	if (_shadow) draw_sprite_ext(_sprite, page.index, page_x + 20, page_y + 20, _scale * 0.98,  _scale * 0.98, 0, c_black, 0.5 * pages_alpha);
	
	var draw_scale = _scale;
	if (!_shadow) draw_scale = 1;
	draw_sprite_ext(_sprite, page.index, page_x, page_y, draw_scale,  draw_scale, 0, _blend, _alpha * pages_alpha);
	
	
	
	// Draw islands - they draw to their own surface so we can mask them out
	var surf_w = global.resolution_options[global.resolution_index].w;
	var surf_h = global.resolution_options[global.resolution_index].h;
	
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
		draw_sprite_ext(_sprite, page.index, page_x, page_y, draw_scale * 1.0,  draw_scale * 1.0, 0, _blend, _alpha);
		surface_reset_target();

		surface_set_target(island_surf);
		draw_clear_alpha(c_black, 0);

		// content — correct alpha accumulation
		gpu_set_blendmode_ext_sepalpha(bm_src_alpha, bm_inv_src_alpha, bm_one, bm_inv_src_alpha);
	}
	
	// draw sprites
	var island_alpha = !_locked ? pages_alpha : 1;
	
	shader_set(shWhiteFill)
	for (var i = 0; i < 3; i++) {
		draw_sprite_ext(sIslands, page.island_index, page_x, page_y, 1 + i / 3, 1 + i / 3, 0, c_white, 0.2);
	}
	shader_reset();
	
	draw_sprite_ext(sIslands, page.island_index, page_x, page_y, 1, 1, 0, c_white, island_alpha);

	if (_alpha == 1) {
		// apply mask across the whole surface
		shader_set(shErode);
		shader_set_uniform_f(u_erode_texel, 1 / surf_w, 1 / surf_h);
		shader_set_uniform_f(u_erode_radius, 5);
		gpu_set_blendmode_ext(bm_zero, bm_src_alpha);
		draw_surface(island_mask_surf, 0, 0);
		shader_reset();
		gpu_set_blendmode(bm_normal);
		surface_reset_target();
	
		// draw out premultiplied
		gpu_set_blendmode_ext(bm_one, bm_inv_src_alpha);
		draw_surface(island_surf, 0, 0);
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
					if (node_hover) queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), node.name, node.text, sMapIcon, node.subimg, undefined);
					
					// draw the node
					draw_sprite_ext(sMapIcon, node.subimg, node.x, node.y, node.scale, node.scale, 0, _icon_blend, _alph);
				} else if _locked {
					// if this page is locked, don't animate scale or show tooltip
					draw_sprite_ext(sMapIcon, node.subimg, node.x, node.y, 1, 1, 0, _icon_blend, _alph);
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
				draw_sprite_ext(sMapIcon, node.subimg, node.x, node.y, node.scale, node.scale, 0, _icon_blend, _alph);
			
				// if we are hovering this node
				if (node_hover) {
					// show tooltip
					queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), node.name, node.text, sMapIcon, node.subimg, undefined);
					 
					// on click, if we haven't picked a node to move to and we are on the base layer of the UI, set this node as the next node ot move to.
					if (mouse_check_button_pressed(mb_left) && node_to_move_to == undefined && global.ui_layer == UI_LAYER.BASE) {
						if (node == next_node) {
							node_to_move_to = node;
							node_to_move_to.y += 10;
						} else {
							throw_error("You can't reach that yet!", "Complete the next room before continuing.");
						}
					}
				}
			}
		
			// show completed nodes as green
			if (node.cleared) draw_sprite_ext(sMapIcon, node.subimg, node.x, node.y, node.scale*1.2, node.scale*1.2, 0, make_color_rgb(126, 183, 131), _alph);
		}
	}
	
	// if this page is locked draw a chain over it
	if (page.locked) draw_sprite_ext(sRewardChain, 0, page_x, page_y, 1.4, 1.4, 0, c_white, pages_alpha);
	
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
        });
    }
    return {
        index: _page.index,
        island_index: _page.island_index,
        is_boss: page_is_boss(_page),
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
        ds_list_add(_page.nodes, _node);
    }
    
    return _page;
}

function start_drafting() {
	world_state = WORLD_STATE.DRAFTING;
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

#macro CHAPTER_SPREADS 7				// drafted spreads before the boss spread
#macro CHAPTER_ENEMY_HP_GROWTH 0.5		// each chapter after the first adds this fraction of an enemy's health
#macro CHAPTER_ENEMY_BONUS_GROWTH 3		// each chapter after the first adds this to every enemy attack and block

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
		if (ds_exists(_nodes, ds_type_list)) ds_list_destroy(_nodes);
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
		world_state = WORLD_STATE.TURNING;
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
	
	// left-hand page: the turned page sweeps from the spine outwards, hiding whatever it has passed over
	var _cover_edge = (_turn < 0) ? _cover_x - abs(_turn) * _page_w : -infinity;
	
	// island, with the same white glow draw_page gives it
	var _island_x = _on_right ? _pivot_x + (_page.x - _pivot_x) * _xscale : _page.x;
	var _island_alpha = _on_right ? 1 : page_turn_cover_alpha(_island_x, _cover_edge, 150);
	
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
		var _node_alpha = _on_right ? 1 : page_turn_cover_alpha(_node_x, _cover_edge, 30);
		if (_node_alpha <= 0) continue;
		
		draw_sprite_ext(sMapIcon, _node.subimg, _node_x, _node.y, _xscale, 1, 0, c_white, _node_alpha);
		if (_node.cleared) draw_sprite_ext(sMapIcon, _node.subimg, _node_x, _node.y, 1.2 * _xscale, 1.2, 0, make_color_rgb(126, 183, 131), _node_alpha);
	}
}

/// @desc How visible something on the left-hand page is while the turned page covers it.
///       Fades out over _fade_w pixels as the page edge passes over it.
function page_turn_cover_alpha(_x, _cover_edge, _fade_w) {
	return clamp((_cover_edge - _x) / _fade_w + 0.5, 0, 1);
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
function draw_chapter_tab(_x0, _y0, _x1, _y1, _slant, _label, _visible_w, _alpha) {
	var _col = make_color_rgb(70, 190, 170);	// teal, like a divider tab
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
	draw_outline_text(_label, c_black, c_white, 2, _visible_mid_x, (_y0 + _y1) / 2, 1, _alpha, -90);
	
	draw_set_alpha(1.0);
}

/// @desc Filled tab outline: square at the inner end, cut corners at the outer end.
function draw_tab_shape(_x0, _y0, _x1, _y1, _slant) {
	draw_rectangle(_x0, _y0, _x1 - _slant, _y1, false);
	draw_rectangle(_x1 - _slant, _y0 + _slant, _x1, _y1 - _slant, false);
	draw_triangle(_x1 - _slant, _y0, _x1, _y0 + _slant, _x1 - _slant, _y0 + _slant, false);
	draw_triangle(_x1 - _slant, _y1, _x1, _y1 - _slant, _x1 - _slant, _y1 - _slant, false);
}
