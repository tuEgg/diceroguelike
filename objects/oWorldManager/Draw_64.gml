if (room == rmMap) {	
	var gui_w = display_get_gui_width();
	var gui_h = display_get_gui_height();
	
	// Rock the boat
	time++;
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
	if (!choices_locked) {
		var page_count = ds_list_size(pages_shown);
	
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
					_page_clone.y_offset = _page_clone.y - final_map_y
					_page_clone.x_offset = _page_clone.x - final_map_x;
				
					// Add this locked in page to chosen_pages
					ds_list_add(chosen_pages, _page_clone);
					
					for (var n = 0; n < _page_clone.num_nodes; n++) {
						ds_list_add(all_nodes, _page_clone.nodes[| n]);
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
		draw_sprite_ext(sButtonSmall, 0, display_get_gui_width() * 3/4, gui_h - 100, embark_scale*1.0, embark_scale*0.8, 0, exit_col, 1.0);
		draw_outline_text("Embark", c_black, c_white, 2, display_get_gui_width() * 3/4, gui_h - 100, 1, 1, 0);
	} else {
		ds_list_clear(pages_shown);
	}
	
	for (var p = 0; p < ds_list_size(chosen_pages); p++) {
		var page = chosen_pages[| p];
		page.x = final_map_x + page.x_offset;
		page.y = final_map_y + page.y_offset;
		show_debug_message("Page: "+string(p)+" nodes: "+string(page.nodes));
		draw_page(page, page.x, page.y, -1, false, true);
	}
	
	// Draw the boat
	var boat_hover = mouse_hovering(boat_data.x, boat_data.y - sprite_get_height(sMapShip)/2, sprite_get_width(sMapShip), sprite_get_height(sMapShip), true);
	if (boat_hover) queue_tooltip(mouse_x, mouse_y, "Your ship", "Where to captain?", undefined, 0, undefined);
	
	draw_sprite_ext(sMapShip, 0, boat_data.x, boat_data.y, 1, 1, boat_data.angle, c_white, 1.0);
}

