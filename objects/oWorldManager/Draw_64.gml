time++;

var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

if (room == rmMap) {	
	
	// Rock the boat
	boat_data.y += sin(time * 0.05) * 0.4;
	//map_position.y += sin(time * 0.05) * 0.4;
	boat_data.angle += cos(time * 0.05) * 0.2;

	var final_map_x = boat_data.x + map_position.x;
	var final_map_y = boat_data.y + map_position.y;
	
	// Draw the trail
	if (time mod 8 == 0) && ds_list_size(circle_list) < 200 {
		var map_x = boat_data.x - map_position.x;
		var map_y = boat_data.y - map_position.y;
		ds_list_add(circle_list, {x: map_x, y: map_y});
	}
	
	for (var i = ds_list_size(circle_list) - 1; i >= 0; i--) {
	    var circle = circle_list[| i];

	    // Drift backwards only when idle
	    if (node_to_move_to == undefined) {
	        circle.x -= 1.5;
	    }

	    // Convert map-local space to GUI
	    var gui_x = circle.x + map_position.x;
	    var gui_y = circle.y + map_position.y;

	    draw_set_alpha(0.8);
	    draw_set_color(c_white);
	    draw_circle(gui_x, gui_y, 4, false);

	    // Cull offscreen (in map space, not GUI)
	    if (circle.x < -100) {
	        ds_list_delete(circle_list, i);
	    }
	}
	
	draw_set_alpha(1.0);

	// Draw the pages
	if (choices_locked) {
		pages_alpha = lerp(pages_alpha, 0, 0.4);
	}
	
	// If there are drafting pages to draw, draw them
	if (pages_alpha > 0 && ds_list_size(pages_shown) > 0) {
		
		var bg_w = 900;
		var bg_h = 850;
		var bg_x = display_get_gui_width() * 3/4 - bg_w/2;
		var bg_y = display_get_gui_height() / 2 - bg_h/2 + 25;
		
		draw_set_color(c_black);
		draw_set_alpha(0.7 * pages_alpha);
		draw_roundrect(bg_x, bg_y, bg_x + bg_w, bg_y + bg_h, false);
		draw_set_alpha(1.0);
		
		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		draw_set_font(ftBigger);
		draw_outline_text("What happened next?", c_black, c_white, 3, display_get_gui_width() * 3/4, 140, 1, pages_alpha, 0);
		
		var page_count = ds_list_size(pages_shown);
	
		// Draw every page
		for (var p = 0; p < page_count; p++) {
			var page = pages_shown[| p];
		
			var page_hover = draw_page(page, page_pos[p].x, page_pos[p].y, p, true, false);
	
			if (page_hover && !page.chosen) {
				var page_offset_x = sprite_get_width(sMapParchment)/2 + 30;
				var page_offset_y = sprite_get_height(sMapParchment)/2 - page.map_connection_in.x - 20 - page.margin.top + page.margin.bottom;
			
				var drawn_page_x =	final_map_x + page_offset_x;
				var drawn_page_y = final_map_y + page_offset_y;
			
				var chosen_page_list_size = ds_list_size(chosen_pages)
			
				if (chosen_page_list_size > 0) {
					drawn_page_x = chosen_pages[| chosen_page_list_size - 1].map_connection_out.x;
					drawn_page_y = chosen_pages[| chosen_page_list_size - 1].map_connection_out.y;
				}
			
				draw_page(page, drawn_page_x, drawn_page_y, p, false, false);
			
				if (mouse_check_button_pressed(mb_left)) {
					// Set this page as selected
					var _page_clone = clone_page(page);
					_page_clone.x = drawn_page_x;
					_page_clone.y = drawn_page_y;
					_page_clone.y_offset = _page_clone.y - final_map_y;
					_page_clone.x_offset = _page_clone.x - final_map_x;
				
					// Add this locked in page to chosen_pages
					ds_list_add(chosen_pages, _page_clone);
					
					// Add all nodes to a master node list
					for (var n = 0; n < _page_clone.num_nodes; n++) {
						var node = _page_clone.nodes[| n];
						ds_list_add(all_nodes, node);
						
						// update node count types - used for generating further nodes
						switch(node.type) {
							case NODE_TYPE.COMBAT:			combat_nodes_this_voyage++;			break;
							case NODE_TYPE.EVENT:			event_nodes_this_voyage++;			break;
							case NODE_TYPE.WORKBENCH:		workbench_nodes_this_voyage++;		break;
							case NODE_TYPE.SHOP:			shop_nodes_this_voyage++;			break;
							case NODE_TYPE.BOUNTY:			bounty_nodes_this_voyage++;			break;
							case NODE_TYPE.ELITE:			elite_nodes_this_voyage++;			break;
						}
						
						// When we add an elite to the node list, we need to remove elites from the remaining drafted pages
						if (node.type == NODE_TYPE.ELITE) {
							// loop through all pages
							for (var pp = 0; pp < page_count; pp++) {
								// for any that aren't this page
								if (pages_shown[| pp] != page) {
									// loop through their nodes
									for (var nn = 0; nn < pages_shown[| pp].num_nodes; nn++) {
										if (pages_shown[| pp].nodes[| nn].type == NODE_TYPE.ELITE) {
											pages_shown[| pp].nodes[| nn] = clone_node_static(node_combat);
										}
									}
								}	
							}
						}
					}
					
					page.chosen = true;
					nodes_til_drafting += page.num_nodes;
					pages_drafted += 1;
								
					// Randomly remove one of the other options
					if (pages_drafted == 1) {
						var temp_list = ds_list_create();
					
						for (var i = 0; i < ds_list_size(pages_shown); i++) {
							if (!pages_shown[| i].chosen) {
								ds_list_add(temp_list, pages_shown[| i]);
							}
						}
					
						var removed_option = temp_list[| choose(0,1)];
					
						removed_option.chosen = true;
						removed_option.locked = true;
						ds_list_destroy(temp_list);
					}
				}
			}

		}
		
		// Draw embark button
		var exit_col = c_dkgray;
		if (pages_drafted == 2) exit_col = c_red;

		var hover_exit = mouse_hovering(display_get_gui_width() * 3/4, gui_h - 100, embark_scale * sprite_get_width(sButtonSmall) * 1.0, embark_scale * sprite_get_height(sButtonSmall) * 0.8, true);

		if (hover_exit && exit_col == c_red) {
			if (mouse_check_button_pressed(mb_left)) {
				choices_locked = true;
			}
			embark_scale = lerp(embark_scale, 1.2, 0.2);
		} else {
			embark_scale = lerp(embark_scale, 1.0, 0.2);
		}

		draw_set_font(ftBigger);
		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		draw_sprite_ext(sButtonSmall, 0, display_get_gui_width() * 3/4, gui_h - 100, embark_scale*1.0, embark_scale*0.8, 0, exit_col, pages_alpha);
		draw_outline_text("Embark", c_black, c_white, 2, display_get_gui_width() * 3/4, gui_h - 100, 1, pages_alpha, 0);
	} else {
		ds_list_clear(pages_shown);
		pages_alpha = 1;
	}
	
	// Draw chosen pages
	for (var p = 0; p < ds_list_size(chosen_pages); p++) {
		var page = chosen_pages[| p];
		page.x = final_map_x + page.x_offset;
		page.y = final_map_y + page.y_offset;
		draw_page(page, page.x, page.y, -1, false, true);
	}
	
	// Draw the boat
	var boat_hover = mouse_hovering(boat_data.x, boat_data.y - sprite_get_height(sMapShip)/2, sprite_get_width(sMapShip), sprite_get_height(sMapShip), true);
	if (boat_hover) queue_tooltip(mouse_x, mouse_y, "Your ship", "Where to captain?", undefined, 0, undefined);
	
	draw_sprite_ext(sMapShip, 0, boat_data.x, boat_data.y, 1, 1, boat_data.angle, c_white, 1.0);
}

if (debug_mode) {
	var world_debug = [];
	array_push(world_debug, combat_chance);
	array_push(world_debug, event_chance);
	array_push(world_debug, workbench_chance);
	array_push(world_debug, shop_chance);
	array_push(world_debug, bounty_chance);
	array_push(world_debug, elite_chance);
	
	array_push(world_debug, combat_nodes_this_voyage);
	array_push(world_debug, event_nodes_this_voyage);
	array_push(world_debug, workbench_nodes_this_voyage);
	array_push(world_debug, shop_nodes_this_voyage);
	array_push(world_debug, bounty_nodes_this_voyage);
	array_push(world_debug, elite_nodes_this_voyage);
	
	draw_set_alpha(0.8);
	draw_set_color(c_black);
	draw_rectangle(gui_w, 100, gui_w - 225, 700, false);
	draw_set_alpha(1.0);
	
	draw_set_font(ftSmall);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_color(c_white);
	for (var i = 0; i < array_length(world_debug); i++) {
		var lookup = ["combat", "event", "workbench", "shop", "bounty", "elite", "combat nodes", "event nodes", "workbench nodes", "shop nodes", "bounty nodes", "elite nodes"];
		
		draw_text(gui_w - 200, 125 + (i * 30), lookup[i] + ": ");
		draw_text(gui_w - 75, 125 + (i * 30), string(world_debug[i]));
	}
}