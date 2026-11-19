time++; // used for the boat wobble

var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

if (room == rmMap) {	
	
	// Rock the boat
	boat_data.y += sin(time * 0.05) * 0.4;
	boat_data.angle += cos(time * 0.05) * 0.2;
	
	var page_w = sprite_get_width(sWorldBookWater);
	var page_xscale = 0.9;
	var page_yscale = 0.9;
	var page_y = gui_h * 0.52;
	var page_pos_offset = -(page_w*page_xscale)/16;
	var cover_offset = 40;
	book_left_x = gui_w/2 - page_pos_offset - page_w * page_xscale; // the water pages' outer edges
	book_right_x = gui_w/2 + page_pos_offset + page_w * page_xscale;
			
	draw_sprite_ext(sWorldBook, 0, gui_w/2 - page_pos_offset - cover_offset, page_y, -page_xscale * book_open_scale, page_yscale, 0, c_white, 1.0);
	draw_sprite_ext(sWorldBook, 1, gui_w/2 + page_pos_offset + cover_offset, page_y, page_xscale * book_open_scale, page_yscale, 0, c_white, 1.0);
	
	// The book only has art for a fixed number of spreads, so hold on the last one rather than read past it
	var book_spread = min(spreads_cleared, array_length(page_image_indices) - 2); // never past the boss spread
	var pages_left = spreads_cleared;
	var pages_right = 7 - book_spread;
	// Pages are stacked by their depth from the open spread, so the open spread stays still: the turned pages
	// build up on the left and the pages still to read get thinner on the right as the voyage goes on
	var page_offset = 6; // gap between one page edge and the next
		
	// show turning page
	if (world_state == WORLD_STATE.TURNING) {
		// turn the page 
		current_page_turn = lerp(current_page_turn, -1.0, 0.06);
	}
	
	// draw left pages
	for (var i = 0; i <= book_spread; i++) {
		// for animating current page
		var x_scale = page_xscale * -1 * book_open_scale;
					
		// if we're looking at the top page
		if (i == book_spread) {
			// and we are turning
			if (world_state == WORLD_STATE.TURNING) {
				// if the current page scale has gone from 1 -> 0 and is now below 0
				if (current_page_turn < 0) {
					// multiply our x scale by the amount under 0 it is
					x_scale *= abs(current_page_turn);
				}
				// don't show if it is above 0
				else {
					x_scale = 0;
				}
			}
		}
		
		// draw the paper pages
		draw_sprite_ext(sWorldBook, page_image_indices[i], gui_w/2 + (page_pos_offset * -1) - (page_offset * (book_spread - i)), page_y, x_scale, page_yscale, 0, c_white, 1.0);
		
		// draw the water page on top and below
		if (i == book_spread || i == book_spread - 1) {
			draw_sprite_ext(sWorldBookWater, page_image_indices[i] - 2, gui_w/2 + (page_pos_offset * -1) - (page_offset * (book_spread - i)), page_y, x_scale, page_yscale, 0, c_white, 1.0);
		}
	}
	
	// Chapters still to come: the book carries a short stack of pages for each one behind this chapter's
	// pages, and a folder-style divider tab on the first page of each, sticking out of the right-hand side.
	// Each tab is drawn just before its page, so the pages in front cover its base, and the pages of the
	// chapter in between show as edges between one tab and the next.
	// Placeholder shapes until there is art: nudge these numbers to move or resize them.
	var future_pages_per_chapter = 5;	// pages drawn for each chapter still to come
	var tab_edge_inset = 50;	// how far in from the sprite's right edge the paper actually ends
	var tab_out = 90;			// how far each tab sticks out past the paper
	var tab_h = 230;			// length of a tab along the edge of the book
	var tab_gap = 16;			// space between one tab and the next
	var tab_y_offset = -150;	// first tab's centre, relative to the middle of the page
	var tab_slant = 22;			// how much the outer corners are cut, like a folder tab

	var chapter_pages = array_length(page_image_indices);
	var future_chapters = max(0, CHAPTER_COUNT - chapter);
	var last_page = chapter_pages - 1 + future_chapters * future_pages_per_chapter;
	var page_w_on_screen = sprite_get_width(sWorldBook) * page_xscale * book_open_scale;
	var tab_first_y0 = page_y + tab_y_offset - tab_h/2;

	// draw right pages, back to front (the chapters still to come are at the back)
	for (var i = last_page; i >= book_spread; i--) {
		// for animating current page
		var x_scale = page_xscale * book_open_scale;

		if (i == book_spread) {
			if (world_state == WORLD_STATE.TURNING) {
				if (current_page_turn > 0) {
					x_scale *= abs(current_page_turn);
				} else {
					x_scale = 0;
				}
			} else {
				x_scale = 0;
			}
		}

		// a later chapter's first page carries its tab, drawn first so this page covers its base
		var future_index = i - chapter_pages;
		if (future_index >= 0 && future_index mod future_pages_per_chapter == 0 && book_open_scale > 0.5) {
			var c = chapter + 1 + (future_index div future_pages_per_chapter);
			var tab_x0 = gui_w/2 + page_pos_offset + (page_offset * max(0, i - book_spread - 1)) + page_w_on_screen - tab_edge_inset - 30;
			var tab_y0 = tab_first_y0 + (c - chapter - 1) * (tab_h + tab_gap);
			draw_chapter_tab(tab_x0, tab_y0, tab_x0 + 30 + tab_out, tab_y0 + tab_h, tab_slant, "Chapter " + string(c), chapter_tab_colour(c), tab_out, book_open_scale);
		}

	// draw the paper pages
		draw_sprite_ext(sWorldBook, page_image_indices[i mod chapter_pages], gui_w/2 + (page_pos_offset) + (page_offset * max(0, i - book_spread - 1)), page_y, x_scale, page_yscale, 0, c_white, 1.0);
		
		// draw the water page on top
		if (i == book_spread || i == book_spread + 1) {
			draw_sprite_ext(sWorldBookWater, page_image_indices[i] - 2, gui_w/2 + (page_pos_offset) + (page_offset * max(0, i - book_spread - 1)), page_y, x_scale, page_yscale, 0, c_white, 1.0);
		}
	}
	
	// hovering the part of a tab that sticks out explains it
	for (var c = chapter + 1; c <= CHAPTER_COUNT && book_open_scale > 0.5; c++) {
		var tab_page_index = chapter_pages + (c - chapter - 1) * future_pages_per_chapter;
		var tab_x1 = gui_w/2 + page_pos_offset + (page_offset * max(0, tab_page_index - book_spread - 1)) + page_w_on_screen - tab_edge_inset + tab_out;
		var tab_y0 = tab_first_y0 + (c - chapter - 1) * (tab_h + tab_gap);
		if (!mouse_hovering(tab_x1 - tab_out, tab_y0, tab_out, tab_h, false)) continue;

		var tab_text;
		if (c == chapter + 1) {
			var spreads_to_boss = max(0, CHAPTER_SPREADS - spreads_cleared);
			tab_text = "The boss is on this spread.";
			if (spreads_to_boss == 1) tab_text = "1 more spread until the boss.";
			if (spreads_to_boss > 1) tab_text = string(spreads_to_boss) + " more spreads until the boss.";
			tab_text += " Chapter " + string(c) + " begins after it.";
		} else {
			tab_text = "Chapter " + string(c) + " of " + string(CHAPTER_COUNT) + ", after the chapter before it.";
		}
		queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Chapter " + string(c) + ": " + chapter_title(c), tab_text);
	}
	
	// where we are in the whole voyage, under the book
	draw_voyage_progress(gui_w/2, gui_h - 45, book_open_scale);

	draw_set_alpha(1.0);

	// Draw the pages
	if (choices_locked) {
		pages_alpha = lerp(pages_alpha, 0, 0.2);
		if (pages_alpha < 0.05)	{
			if (world_state != WORLD_STATE.EXPLORING) {
				// the ship sails onto the new spread from the book's left edge (to the start of its course)
				boat_data.x = book_left_x - 90;
				boat_data.y = gui_h / 2;
				boat_data.entering = true;
			}
			world_state = WORLD_STATE.EXPLORING;
			pages_alpha = 0;
		}
	}
	
	// Draw chosen pages
	// the boss spread is a single page, so don't show the previous spread's island beside it
	var _pages_on_spread = 2;
	if (ds_list_size(chosen_pages) > 0 && page_is_boss(chosen_pages[| ds_list_size(chosen_pages) - 1])) _pages_on_spread = 1;
	
	// where the turning page is hinged, matching the page drawing above
	var turn_pivot_x = gui_w/2 + page_pos_offset;
	var turn_cover_x = gui_w/2 - page_pos_offset;
	var turn_page_w = sprite_get_width(sWorldBook) * page_xscale * book_open_scale;
	
	for (var p = 0; p < ds_list_size(chosen_pages); p++) {
		var page = chosen_pages[| p];
		
		switch (world_state) {
			// while drafting, only show the pages we've locked in so far
			case WORLD_STATE.DRAFTING:
				if (p >= ds_list_size(chosen_pages) - pages_drafted) {
					draw_page(page, page.x, page.y, -1, false, true);
				}
			break;
			
			// the finished spread turns over with the page
			case WORLD_STATE.TURNING:
				if (p >= ds_list_size(chosen_pages) - 2) {
					draw_page_turning(page, current_page_turn, turn_pivot_x, turn_cover_x, turn_page_w);
				}
			break;
			
			// otherwise show the current spread
			default:
				if (p >= ds_list_size(chosen_pages) - _pages_on_spread) {
					draw_page(page, page.x, page.y, -1, false, true);
				}
			break;
		}
	}
	
	// Draw the drafting panel background
	if (world_state != WORLD_STATE.EXPLORING) {
		var bg_w = gui_w;
		var bg_h = gui_h;
		var bg_x = 0;
		var bg_y = ui_top_bar_h(); // the top bar stays in full colour
		
		draw_set_color(c_black);
		draw_set_alpha(0.55 * (max(pages_alpha, resting_alpha)));
		draw_roundrect(bg_x, bg_y, bg_x + bg_w, bg_y + bg_h, false);
		draw_set_alpha(1.0);
		
		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		draw_set_font(ftBigger);
		// one heading for one action (it used to have "What happened next?" over it as well)
		draw_outline_text("Choose a page to draft", c_black, c_white, 3, bg_w/2, gui_h * 0.25, 1, pages_alpha, 0);
		draw_set_font(ftDefault);
		if (pages_alpha > 0.05) ui_divider(gui_w/2 - 200, gui_w/2 + 200, gui_h * 0.29, pages_alpha); // under the heading
	
		if (world_state == WORLD_STATE.OPENING) {		
			book_open_scale = lerp(book_open_scale, 1.0, 0.08);
			
			if (book_open_scale > 0.99) {
				world_state = WORLD_STATE.DRAFTING;
			}
			
		}
	
		// If we are healing or workbench
		if (world_state == WORLD_STATE.TURNING) {
			
			// the ship sails off the right edge of the book while the page turns (it sails in again after Embark)
			boat_data.x = lerp(boat_data.x, book_right_x + 140, 0.04);
			boat_data.y = lerp(boat_data.y, page_y, 0.05);
			
			// the choice was made at sea (strait_draw): once the page has turned, choose the next pages
			if (current_page_turn < -0.9) start_drafting();
		}
		
		// If we are drafting
		if (world_state == WORLD_STATE.DRAFTING) {
			if (resting_alpha < 0.05) {
				if (ds_list_size(pages_shown) == 0) {
					// after the last drafted spread comes the boss, which isn't drafted
					if (spreads_cleared >= CHAPTER_SPREADS) {
						if (!boss_page_placed) place_boss_page();
					} else {
						generate_pages();
					}
					
					// save the new draft, so quitting can't reroll it
					save_game(1);
				}
				
				if (!choices_locked) {
					pages_alpha = lerp(pages_alpha, 1, 0.2);
				}
				
				resting_alpha = 0;
			}
		}
	
		// If there are drafting pages to draw, draw them
		if (pages_alpha > 0) {
		
			var page_count = ds_list_size(pages_shown);
	
			// Draw each page onto the map
			for (var p = 0; p < page_count; p++) {
				var page = pages_shown[| p];
		
				// check if we're hovering
				var page_hover = draw_page(page, page_pos[p].x, page_pos[p].y, p, true, false);

				// if we're hovering a draftable page but haven't selected it yet,
				if (page_hover && !page.chosen) {
					var page_offset_x = sprite_get_width(sMapParchment)/2 + 30;
					var page_offset_y = sprite_get_height(sMapParchment)/2 - page.map_connection_in.x - 20 - page.margin.top + page.margin.bottom;
			
					var left_or_right_page = ds_list_size(chosen_pages) mod 2;
					
					var drawn_page_x = gui_w * (0.333 + (0.333 * left_or_right_page)) - 70; // a little left: room for the sea stop past each island (spread_sea_spots)
					var drawn_page_y = gui_h * 0.5;
			
			
					//draw_page(page, drawn_page_x, drawn_page_y, p, false, false);
			
					if (mouse_check_button_pressed(mb_left) && can_draft && global.ui_layer == UI_LAYER.BASE) {
					
						// Set this page as selected
						var _page_clone = clone_page(page);
						_page_clone.x = drawn_page_x;
						_page_clone.y = drawn_page_y;
				
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
								case NODE_TYPE.SHOP:			shop_nodes_this_voyage++;			break;
								case NODE_TYPE.BOUNTY:			bounty_nodes_this_voyage++;			break;
								case NODE_TYPE.ELITE:			elite_nodes_this_voyage++;			break;
								case NODE_TYPE.ALIGNMENT:		alignment_nodes_this_voyage++;		break;
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
							
							// When we add a treasure to the node list, we need to remove treasures from the remaining drafted pages
							if (node.type == NODE_TYPE.TREASURE) {
								// loop through all pages
								for (var pp = 0; pp < page_count; pp++) {
									// for any that aren't this page
									if (pages_shown[| pp] != page) {
										// loop through their nodes
										for (var nn = 0; nn < pages_shown[| pp].num_nodes; nn++) {
											if (pages_shown[| pp].nodes[| nn].type == NODE_TYPE.TREASURE) {
												pages_shown[| pp].nodes[| nn] = clone_node_static(node_event);
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
							
							// add the first pages number of nodes to nodes_til_page_cleared
							nodes_til_page_cleared = page.num_nodes;
							
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
						
						// save each pick, so quitting mid-draft keeps it (and the page it locked)
						save_game(1);
					}
				}

			}
		
			// Draw embark button
			var exit_col = c_dkgray;
			if (pages_drafted == 2) exit_col = c_red;

			// Embark: a kit button that glows and breathes once both pages are chosen, fading in with the pages
			var embark_ready = (exit_col == c_red);
			var embark_pulse = embark_ready ? (0.5 + 0.5 * sin(current_time / 220)) : 0;
			var embark_x = display_get_gui_width() * 3/4, embark_y = gui_h - 100;
			var embark_w = 240, embark_h = 84;
			if (embark_ready) {
				var glow_w = embark_w / 2 * embark_scale + 16 + 8 * embark_pulse;
				var glow_h = embark_h / 2 * embark_scale + 12 + 6 * embark_pulse;
				draw_set_color(global.color_intel);
				draw_set_alpha(pages_alpha * (0.25 + 0.3 * embark_pulse));
				draw_roundrect_ext(embark_x - glow_w, embark_y - glow_h, embark_x + glow_w, embark_y + glow_h, 30, 30, false);
				draw_set_alpha(1);
			}
			var embark_btn = ui_button(embark_x, embark_y, embark_w * (1 + 0.05 * embark_pulse), embark_h * (1 + 0.05 * embark_pulse), embark_scale, "Embark", embark_ready ? global.ui_primary : global.ui_neutral, embark_ready, "Choose two pages first.", UI_LAYER.BASE, pages_alpha, ftBigger);
			embark_scale = embark_btn.scale;
			if (embark_btn.click) {
				choices_locked = true;
				save_game(1);
			}
		} else {
			ds_list_clear(pages_shown);
		}
	}
	
	// the spread as a chart (F125): dotted courses between its stops, the Shipwright's buoy between the pages and the
	// strait's stops past the right page, on the map the whole spread (sailable when you get there), under the ship
	var _spots = spread_sea_spots();
	// the boss spread (one page): just the course in from the book's edge
	if (_spots.left == undefined && world_state == WORLD_STATE.EXPLORING && ds_list_size(chosen_pages) > 0 && page_is_boss(chosen_pages[| ds_list_size(chosen_pages) - 1])) {
		var _bp = chosen_pages[| ds_list_size(chosen_pages) - 1];
		if (ds_list_size(_bp.nodes) > 0) { var _bn = _bp.nodes[| 0]; route_draw(book_left_x, gui_h / 2, _bn.x, _bn.y, _bn.cleared ? 0.85 : 0.38); }
	}
	if (_spots.left != undefined && (world_state == WORLD_STATE.EXPLORING || world_state == WORLD_STATE.STRAIT)) {
		spread_routes_draw(_spots);
		sea_buoy_draw(_spots.buoy.x, _spots.buoy.y);
		strait_draw(_spots.strait.x, _spots.strait.y);
	}

	// sailing in from the book's edge to the start of the course (after Embark); clicking an island takes over
	if (boat_data.entering) {
		if (node_to_move_to != undefined || world_state != WORLD_STATE.EXPLORING) boat_data.entering = false;
		else {
			boat_data.x = lerp(boat_data.x, book_left_x + 40, 0.05);
			boat_data.y = lerp(boat_data.y, gui_h / 2, 0.05);
			if (abs(boat_data.x - (book_left_x + 40)) < 2) boat_data.entering = false;
		}
	}

	// Draw the boat (clicking it to visit the workbench was tried and taken out: see KANBAN F02)
	var boat_hover = mouse_hovering(boat_data.x, boat_data.y - sprite_get_height(sMapShip)/2, sprite_get_width(sMapShip), sprite_get_height(sMapShip), true);
	if (boat_hover) queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Your ship", "Where to captain?", undefined, 0, undefined);
	
	var _boat_a = 1 - clamp((boat_data.x - book_right_x) / 90, 0, 1) - clamp((book_left_x - boat_data.x) / 90, 0, 1); // off the book: gone
	if (_boat_a > 0) draw_sprite_ext(sMapShip, 0, boat_data.x, boat_data.y, 1, 1, boat_data.angle, c_white, _boat_a);
	
	// Chapter complete: shown once the boss is beaten, until the player turns to the next chapter
	if (world_state == WORLD_STATE.CHAPTER_END) {
		chapter_end_alpha = lerp(chapter_end_alpha, 1, 0.1);
		
		draw_set_color(c_black);
		draw_set_alpha(0.7 * chapter_end_alpha);
		draw_rectangle(0, ui_top_bar_h(), gui_w, gui_h, false); // the top bar stays in full colour
		draw_set_alpha(1.0);

		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		draw_set_font(ftBigger);
		var voyage_over= (chapter >= CHAPTER_COUNT);

		draw_outline_text(voyage_over ? "Voyage complete" : "Chapter " + string(chapter) + " complete", c_black, c_white, 3, gui_w/2, gui_h * 0.34, 1, chapter_end_alpha, 0);
		draw_set_font(ftBig);
		draw_outline_text(chapter_title(chapter), c_black, c_white, 2, gui_w/2, gui_h * 0.41, 1, chapter_end_alpha, 0);
		draw_set_font(ftDefault);
		var next_text = voyage_over
			? "You have sailed all " + string(CHAPTER_COUNT) + " chapters of the logbook."
			: "Next: Chapter " + string(chapter + 1) + ", " + chapter_title(chapter + 1) + ". The seas grow more dangerous.";
		draw_outline_text(next_text, c_black, c_white, 2, gui_w/2, gui_h * 0.50, 1, chapter_end_alpha, 0);

		var chapter_btn = draw_gui_button(
			gui_w/2 - gui_w/10,
			gui_h * 0.58,
			gui_w/5,
			gui_h/12,
			chapter_btn_scale,
			voyage_over ? "Finish the voyage" : "Turn the page",
			global.ui_primary,
			ftBig,
			chapter_end_alpha > 0.9,
			true
		);

		chapter_btn_scale = lerp(chapter_btn_scale, chapter_btn.hover ? 1.2 : 1.0, 0.2);

		if (chapter_btn.click) {
			if (voyage_over) {
				// the run is won: the summary deletes the save and leads back to the menu
				run_end(true, "All " + string(CHAPTER_COUNT) + " chapters of the logbook sailed");
			} else {
				start_new_chapter();
			}
		}
	}

}

