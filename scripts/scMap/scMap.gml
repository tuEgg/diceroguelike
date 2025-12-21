/// @func generate_pages
function generate_pages() {
	var num_combat = 0; // generate no more than 5 across all 3 pages
	var num_event = 0; // generate no more than 3 across all 3 pages
	var num_workbench = 0; // generate no more than 2 across all 3 pages
	var num_shop = 0; // generate no more than 2 across all 3 pages
	var num_bounty = 0; // generate no more than 1 bounty across all 3 pages
	var num_elite = 0; // each page has an elite at the same time???
	
	repeat (3) {
		var _index = irandom(5);
		var _num_nodes = choose(1,2,2);
		var _left = 0;
		var _right = 0;
		var _top = 0;
		var _bottom = 0;
		
		// offset the position of the nodes and lines depending on the page sprite index
		switch(_index) {
			case 0:
				_left = 60;
				_right = 55;
				_top = 20;
			break;
			case 1:
				_left = 40;
				_right = 30;
			break;
			case 2:
				_left = 40;
				_right = 50;
				_bottom = 20;
			break;
			case 3:
				_left = 40;
				_right = 60;
				_bottom = 20;
			break;
			case 4:
				_left = 60;
				_right = 30;
			break;
			case 5:
				_left = 40;
				_right = 30;
			break;
		}
		
		// create the page data
		var _page = {
			index: _index,
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
		var page_num_workbench = 0; // generate no more than 1 per page
		var page_num_shop = 0; // generate no more than 1 per page
		var page_num_bounty = 0;
		var page_num_elite = 0;
	
		// add the nodes
		do {
			var chosen_node = node_combat;
			var page_num = ds_list_size(pages_shown); // 0, 1 or 2
			
			//combat_chance = 60; node_combat, node_event, node_shop, node_workbench
			//event_chance = 30;
			//workbench_chance = 5;
			//shop_chance = 5;
			
			var rand = irandom_range(1,100);
			
			if (rand <= combat_chance) {
				if (num_combat < 5) {
					num_combat++;
					page_num_combat++;
					chosen_node = node_combat;
					combat_chance -= 5;
					
					if (nodes_cleared < 5) {
						var rand_inc = (irandom(2));
					
						switch (rand_inc) {
							case 0: event_chance += 5; break;
							case 1: workbench_chance += 5; break;
							case 2: shop_chance += 5; break;
						}
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
					
					if (nodes_cleared < 5) {
						var rand_inc = (irandom(2));
					
						switch (rand_inc) {
							case 0: combat_chance += 5; break;
							case 1: workbench_chance += 5; break;
							case 2: shop_chance += 5; break;
						}
					}
				} else {
					continue;
				}
			} else if (rand <= combat_chance + event_chance + workbench_chance) {
				if (num_workbench < 1) {
					num_workbench++;
					page_num_workbench++;
					chosen_node = node_workbench;
					workbench_chance -= 5;
					
					if (nodes_cleared < 5) {
						shop_chance += 5;
					} else if (oRunManager.active_bounty == undefined && num_bounty == 0 && bounty_nodes_this_voyage == 0) {
						bounty_chance += 5;
					} else {
						shop_chance += 5;
					}
				} else {
					continue;
				}
			} else if (rand <= combat_chance + event_chance + workbench_chance + shop_chance) {
				if (num_shop < 1) {
					num_shop++;
					page_num_shop++;
					chosen_node = node_shop;
					shop_chance -= 5;
					
					if (nodes_cleared < 5) {
						workbench_chance += 5;
					} else if (oRunManager.active_bounty == undefined && bounty_nodes_this_voyage == 0) {
						bounty_chance += 5;
					} else {
						workbench_chance += 5;
					}
				} else {
					continue;
				}
			} else if (rand <= combat_chance + event_chance + workbench_chance + shop_chance + bounty_chance) {
				if (num_bounty < 1 && page_num_bounty == 0) {
					num_bounty++;
					page_num_bounty++;
					chosen_node = node_bounty;
					var gap = bounty_chance;
					bounty_chance = 0;
					combat_chance += floor(gap * (2/5));
					event_chance += floor(gap * (1/5));
					workbench_chance += floor(gap * (1/5));
					shop_chance += floor(gap * (1/5));
					
				} else {
					continue;
				}
			} else if (rand <= combat_chance + event_chance + workbench_chance + shop_chance + bounty_chance + elite_chance) {
				if (num_elite < 2 && page_num_elite == 0) {
					num_elite++;
					page_num_elite++;
					chosen_node = node_elite;
					elite_chance /= 2;
				} else {
					continue;
				}
			}
			
			if (oWorldManager.nodes_cleared == 0) && (ds_list_size(_page.nodes) == 0) {
				chosen_node = node_combat;
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
	
	if (last_node != undefined) last_node.disappeared = true;
	
	if (_node.type == NODE_TYPE.EVENT) {
		var rand = irandom_range(1, 100);
		if (rand <= 10) {
			_node = clone_node_static(node_combat);
		} else if (rand <= 18) {
			_node = clone_node_static(node_shop);
		} else if (rand <= 26) {
			_node = clone_node_static(node_workbench);
		}
	}
	
	get_combat_enemies(_node);
	current_node_type = _node.type;
	
	room_goto(_node.linked_room);
}

function get_combat_enemies(_node) {
	
	if (_node.type == NODE_TYPE.COMBAT) {
		
		// Find a random encounter in the list of possible encounters
		var rand_encounter = irandom(ds_list_size(possible_encounters) - 1);
		
		// Add the relevant enemies
		switch (possible_encounters[| rand_encounter]) {
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
		
			case "Encounter 8":
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Elizabeak"));
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Bill"))
			break;
		}
		
		// Remove it from the list of possible encounters
		ds_list_delete(possible_encounters, rand_encounter);
		
	} else if (_node.type == NODE_TYPE.ELITE) {
		
		// Find a random encounter in the list of possible encounters
		var rand_encounter = irandom(ds_list_size(possible_elites) - 1);
		
		switch (possible_elites[| rand_encounter]) {
			case "Elite 1":
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Pirate Captain"));
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Deckhand"));
			break;
			
			case "Elite 2":
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Pirate Captain"));
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Deckhand"));
			break;
			
			case "Elite 3":
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Pirate Captain"));
				ds_list_add(oWorldManager.room_enemies, enemy_find_by_name("Deckhand"));
			break;
		}
		
		// Remove it from the list of possible encounters
		ds_list_delete(possible_elites, rand_encounter);
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
		
	var _sprite = _locked ? sMapParchmentEmpty : sMapParchment;
	
	var _alpha;

	if (all_nodes_cleared) {
	    _alpha = 0.0;
	} else if (_sprite == sMapParchmentEmpty && ds_list_size(pages_shown) == 0) {
		_alpha = 0.0;
	} else if (choices_locked) {
	    _alpha = pages_alpha;
	} else  {
		_alpha = 1.0;
	}

	
	var _blend;
	var _icon_blend = c_white;

	if (page.chosen && !page.locked) {
	    // highest priority
	    _blend = make_color_rgb(80, 180, 90); 
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
		
	var pages_hover = (!_locked * !page.chosen * mouse_hovering(page_x, page_y, page_width, page_height, true));
	_scale = lerp(_scale, pages_hover ? 1.2 : 1.0, 0.2);
		
	if (_shadow) draw_sprite_ext(_sprite, page.index, page_x + 20, page_y + 20, _scale * 0.98,  _scale * 0.98, 0, c_black, 0.5 * pages_alpha);
	
	var draw_scale = _scale;
	if (!_shadow) draw_scale = 1;
	draw_sprite_ext(_sprite, page.index, page_x, page_y, draw_scale,  draw_scale, 0, _blend, _alpha);
		
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
			
			page.map_connection_out.x = node_x[num_nodes + 1] + page_width/2 + 20;
			page.map_connection_out.y = node_y[num_nodes + 1];
		}
			
		if (!choices_locked) {
			draw_dotted_path(page, n, num_nodes, node_x, node_y);
		}
	}
		
	// Draw icons on top
	for (var n = 0; n < ds_list_size(page.nodes); n++) {
		var node = page.nodes[| n];
		
		node.x = node_x[n+1] + (node_drift * node.cleared);
		node.y = node_y[n+1];
		
		if (node.x < -30) node.disappeared = true;
	
		if (!node.disappeared) {
			var _alph;

			if (!choices_locked || node == next_node) {
			    _alph = 1.0;
			}
			else if (node.cleared) {
			    _alph = 1.0;
			}
			else if (choices_locked && page.chosen) {
			    _alph = pages_alpha;
			}
			else {
			    _alph = 0.75;
			}

			if (!choices_locked) {
				if (!_locked) {
					draw_sprite_ext(sMapIcon, node.subimg, node.x, node.y, _scale, _scale, 0, _icon_blend, _alph);
				} else if _locked {
					draw_sprite_ext(sMapIcon, node.subimg, node.x, node.y, 1, 1, 0, _icon_blend, _alph);
				}
			} else {
				var node_hover = node == next_node ? mouse_hovering( node.x, node.y, sprite_get_width(sMapIcon) * node.scale, sprite_get_height(sMapIcon) * node.scale, true) : false;
			
				draw_set_color(c_black);
				draw_set_halign(fa_left);
				draw_set_font(ftDefault);
			
				node.scale = lerp(node.scale, node_hover ? 1.5 : 1.0, 0.2);
				draw_sprite_ext(sMapIcon, node.subimg, node.x, node.y, node.scale, node.scale, 0, _icon_blend, _alph);
			
				if (node_hover) {
					queue_tooltip(mouse_x, mouse_y, node.name, node.text, sMapIcon, node.subimg, undefined);
					 
					if (mouse_check_button_pressed(mb_left) && node_to_move_to == undefined) {
						node_to_move_to = node;
						node_to_move_to.y += 10;
						map_offset.x += boat_data.x - node_to_move_to.x;
						map_offset.y += boat_data.y - node_to_move_to.y;
					}
				}
			}
		
			if (node.cleared) draw_sprite_ext(sMapIcon, node.subimg, node.x, node.y, node.scale*1.2, node.scale*1.2, 0, c_green, _alph);
		}
	}
	
	if (page.locked) draw_sprite_ext(sRewardChain, 0, page_x, page_y, 1.4, 1.4, 0, c_white, pages_alpha);
	
	if (_index != -1) {
	    page_scale[| _index] = _scale;
	}
	
	return pages_hover;
}


/// @func clone_page(_page_struct)
function clone_page(_src) {
    var c = {
        index: _src.index,
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
