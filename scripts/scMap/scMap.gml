/// @func generate_pages
function generate_pages() {
	repeat (3) {
		var _index = irandom(5);
		var _num_nodes = choose(1,2,2);
		var _left = 0;
		var _right = 0;
		var _top = 0;
		var _bottom = 0;
		
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
		
		var _page = {
			index: _index,
			num_nodes: _num_nodes,
			nodes: ds_list_create(),
			layout: _num_nodes == 1 ? "single" : choose("vertical", "diagonal-down"),
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
			locked: false
		}
		
		switch (_page.layout) {
			case "vertical":
				_page.map_connection_in.x = sprite_get_height(sMapParchment)/2;
			break;
			case "diagonal-down":
				_page.map_connection_in.x = sprite_get_height(sMapParchment)/4;
			break;
			default: _page.map_connection_in.x = sprite_get_height(sMapParchment)/2;
		}
	
		// Need to add weighting here
		repeat(_page.num_nodes) ds_list_add(_page.nodes, clone_node(choose(node_combat, node_event, node_shop, node_workbench)));
	
		ds_list_add(pages_shown, _page);
	}
}

/// @function create_node(_id, _type, _pos_x, _pos_y, _room, _enemy)
function create_node(_id, _type, _pos_x, _pos_y, _room, _enemy) {
    return {
        node_id: _id,                    // unique identifier (e.g. "dan_01")
        node_type: _type,                // "combat", "shop", "event", etc.
        pos_x: _pos_x,                   // map position for drawing
        pos_y: _pos_y,
        connections: ds_list_create(),   // connected node IDs
        visited: false,                  // player visited?
        cleared: false,                  // encounter completed?
		scale: 1.0,						 // used for HUD scale
        data: undefined,                  // optional encounter-specific data (enemy set, rewards, etc.)
		room_link: _room,
		enemy: _enemy,
    };
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

function enter_node(_page) {
	if (_page.type = NODE_TYPE.COMBAT) {
		_page.enemy = enemy_find_by_name("Deckhand"); // Should be Deckhand 
		if (_page.type == NODE_TYPE.COMBAT) { 
			if (pages_turned >= 1 && pages_turned <= 2) {
				_page.enemy = enemy_find_by_name(choose("Thug", "Deckhand"));
			}
			if (pages_turned >= 3 && pages_turned <= 4) {
				_page.enemy = enemy_find_by_name(choose("Thug", "Corsair Gunner", "Deckhand"));
			}
			if (pages_turned >= 5) {
				_page.enemy = enemy_find_by_name(choose("Thug", "Corsair Gunner"));
			}
		} else if (_page.type == NODE_TYPE.BOSS) {
			_page.enemy = enemy_find_by_name("Barnacle Titan");
		}
		room_enemy = _page.enemy;
	}
	room_goto(_page.linked_room);
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

	/// Dot spacing
	var spacing = 11;
	var radius  = 3;
	var color   = choices_locked ? c_white : c_black;


	/// March along actual distance
	for (var d = 0; d <= len; d += spacing) {
	    var t = d / len;
    
	    var xx = path_get_x(_path, t);
	    var yy = path_get_y(_path, t);
    
	    draw_set_color(color);
	    draw_circle(xx, yy, radius, false);
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
		
	var _sprite = _locked ? sMapParchmentEmpty : sMapParchment;
	var _alpha = choices_locked ? 0.0 : 1.0;
	var _blend = page.chosen ? c_black : c_white;
	
	var page_width = sprite_get_width(_sprite);
	var page_height = sprite_get_height(_sprite);
		
	var pages_hover = !_locked * !page.chosen * mouse_hovering(page_x, page_y, page_width, page_height, true);
	_scale = lerp(_scale, pages_hover ? 1.1 : 1.0, 0.2);
		
	if (_shadow) draw_sprite_ext(_sprite, page.index, page_x + 20, page_y + 20, _scale * 0.98,  _scale * 0.98, 0, c_black, 0.5);
	draw_sprite_ext(_sprite, page.index, page_x, page_y, _scale,  _scale, 0, _blend, _alpha);
		
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
			case "vertical":
				node_x[n+1] = page_x;
				node_y[n+1] = node_y[n] + paper_h/(num_nodes*1.5);
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
			
		draw_dotted_path(page, n, num_nodes, node_x, node_y);
			
	}
		
	// Draw icons on top
	for (var n = 0; n < ds_list_size(page.nodes); n++) {
		var node = page.nodes[| n];
		//draw_set_color(make_colour_rgb(248, 226, 199));
		//draw_set_alpha(1.0);
		//draw_circle(node_x[n+1], node_y[n+1], sprite_get_width(sMapIcon) * 0.6, false);
		if (!choices_locked) {
			if (!_locked) {
				draw_sprite_ext(sMapIcon, node.subimg, node_x[n+1], node_y[n+1], _scale, _scale, 0, _blend, 1.0);
			} else if _locked {
				draw_sprite_ext(sMapIcon, node.subimg, node_x[n+1], node_y[n+1], 1, 1, 0, _blend, 1.0);
			}
		} else {
			var _alph = node.cleared ? 0.2 : 1.0;
			var node_hover = !node.cleared * mouse_hovering( node_x[n+1], node_y[n+1], sprite_get_width(sMapIcon) * node.scale, sprite_get_height(sMapIcon) * node.scale, true);
			node.scale = lerp(node.scale, node_hover ? 1.5 : 1.0, 0.2);
			draw_sprite_ext(sMapIcon, node.subimg, node_x[n+1], node_y[n+1], node.scale, node.scale, 0, _blend, _alph);
			
			if (node_hover) {
				if (mouse_check_button_pressed(mb_left)) {
					enter_node(node);
					node.cleared = true;
				}
			}
		}
	}
	
	if (page.locked) draw_sprite_ext(sRewardChain, 0, page_x, page_y, 1.4, 1.4, 0, c_white, 1.0);
	
	return pages_hover;
}


/// @func clone_page(_page_struct)
function clone_page(_src) {
    var c = variable_clone(_src); // shallow clone of base-level fields

    return c;
}

/// @func clone_node(_node_struct)
function clone_node(_src) {
    var c = variable_clone(_src); // shallow clone of base-level fields

    return c;
}