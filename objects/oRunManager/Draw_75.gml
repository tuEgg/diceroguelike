// frames the dice picker has been open (its opening click must not pick a die): counted every frame, so it resets while closed
dice_selection_age = (dice_selection != false) ? dice_selection_age + 1 : 0;

// the screen shake ends here: windows, tooltips and the cursor stay still
matrix_set(matrix_world, matrix_build_identity());
// the log's ink look (F118): this frame was drawn into ink_scene (Draw GUI Begin); back to the screen first. If the
// log closed during this frame, show the frame as it was; otherwise combat_insight_view_draw draws it through shInk.
if (ink_capturing) {
	surface_reset_target();
	if (!(instance_exists(oCombat) && oCombat.insight_view) && surface_exists(ink_scene)) {
		gpu_set_blendenable(false);
		draw_surface(ink_scene, 0, 0);
		gpu_set_blendenable(true);
	}
}

if (show_dice_list) {
	
	// Fill the background of the screen
	draw_set_alpha(1.0);
	draw_set_color(make_color_rgb(44, 40, 62));
	draw_rectangle(0, 0, room_width, room_height, false);
	
	// Set dice stat counters
	var num_d2 = 0;
	var num_d4 = 0;
	var num_d6 = 0;
	var num_d8 = 0;
	var num_atk = 0;
	var num_blk = 0;
	var num_heal = 0;
	var num_intel = 0;
	var num_neutral = 0;
	var num_stowaway = 0;
	var num_favourite = 0;
	var num_coin = 0;
	var num_multitype = 0;
	var num_followthrough = 0;
	var num_exclusive = 0;
	var num_loose = 0;
	var num_sticky = 0;
	
	// Set starting draw positions
	var dice_x = 100;
	var dice_y = scroll_y + 50;
		
	// Set relative draw positions
	var col_spacing = 60;
	var row_spacing = 60;
	
	for (var i = 0; i < ds_list_size(filtered_list); i++) {
		var dice = filtered_list[| i];
		
		// Draw alternating rows
		if (i mod 2 == 0) {
			draw_set_alpha(0.5);
			draw_set_color(c_black);
			draw_rectangle(dice_x - col_spacing, dice_y - row_spacing/2, dice_x + col_spacing * 12, dice_y + row_spacing/2, false);
		}
		
		// Draw dice sprite
		draw_die(dice_x, dice_y, row_spacing * 0.4, dice.dice_value, -1, die_colours(dice.possible_type), 0, 1, dice);
		

		// Draw dice name
		draw_set_font(ftDefault);
		draw_set_valign(fa_middle);
		draw_set_halign(fa_left);
		draw_outline_text(dice.name, c_black, c_white, 2, dice_x + col_spacing, dice_y - 10, 1, 1, 0);
		
		// Draw dice description
		draw_set_font(ftSmall);
	    var parsed = parse_text_with_keywords(die_description(dice));
	    var cursor_x = dice_x + col_spacing;
	    var cursor_y = dice_y + 10;

	    for (var p = 0; p < array_length(parsed); p++) {
	        draw_outline_text(parsed[p].text, c_black, parsed[p].colour, 2, cursor_x, cursor_y, 1, 1, 0);
	        cursor_x += string_width(parsed[p].text);
	    }
		
		// Update stat counters
		switch (dice.dice_value) {
			case 2: num_d2++; break;
			case 4: num_d4++; break;
			case 6: num_d6++; break;
			case 8: num_d8++; break;
			default: break;
		}
		
		switch (dice.action_type) {
			case "ATK": num_atk++; break;
			case "BLK": num_blk++; break;
			case "HEAL": num_heal++; break;
			case "INTEL": num_intel++; break;
			case "None": num_neutral++; break;
			default: break;
		}
		
		if (die_has_keyword(dice, "stowaway")) num_stowaway++;
		if (die_has_keyword(dice, "favourite")) num_favourite++;
		if (die_has_keyword(dice, "coin")) num_coin++;
		if (die_has_keyword(dice, "multitype")) num_multitype++;
		if (die_has_keyword(dice, "followthrough")) num_followthrough++;
		if (die_has_keyword(dice, "exclusive")) num_exclusive++;
		if (die_has_keyword(dice, "loose")) num_loose++;
		if (die_has_keyword(dice, "sticky")) num_sticky++;
		
		// Increase spacing for next dice
		dice_y += row_spacing;
	}
	
	// Define stat area coordinates
	var stat_x = room_width - 750;
	var stat_y = 100;
	
	var stat_col_spacing = 200;
	var stat_row_spacing = 30;
	var stat_section_spacing = 220;
	
	// Draw a background rectangle
	draw_set_alpha(1.0);
	draw_set_color(make_color_rgb(35, 30, 52));
	draw_rectangle(stat_x - 50, stat_y - 50, room_width - 50, room_height - 50, false);
	
	// Set font and alignment
	draw_set_valign(fa_middle);
	draw_set_halign(fa_left);
	
	// Draw section titles
	draw_set_font(ftBig);
	draw_outline_text("Faces", c_black, c_white, 2, stat_x, stat_y, 1, 1, 0);
	draw_outline_text("Action Types", c_black, c_white, 2, stat_x + stat_col_spacing, stat_y, 1, 1, 0);
	draw_outline_text("Keywords", c_black, c_white, 2, stat_x, stat_y + stat_section_spacing, 1, 1, 0);
	
	// Change font for detail
	draw_set_font(ftDefault);
	
	// Draw the number of dice by faces
	draw_outline_text("d2: " + string(num_d2), c_black, c_white, 2, stat_x, stat_y + stat_row_spacing * 1, 1, 1, 0);
	draw_outline_text("d4: " + string(num_d4), c_black, c_white, 2, stat_x, stat_y + stat_row_spacing * 2, 1, 1, 0);
	draw_outline_text("d6: " + string(num_d6), c_black, c_white, 2, stat_x, stat_y + stat_row_spacing * 3, 1, 1, 0);
	draw_outline_text("d8: " + string(num_d8), c_black, c_white, 2, stat_x, stat_y + stat_row_spacing * 4, 1, 1, 0);
	
	// Draw the number of dice by action type
	draw_outline_text("Attack: " + string(num_atk),			c_black, global.color_attack, 2, stat_x + stat_col_spacing, stat_y + stat_row_spacing * 1, 1, 1, 0);
	draw_outline_text("Block: " + string(num_blk),			c_black, global.color_block, 2, stat_x + stat_col_spacing, stat_y + stat_row_spacing * 2, 1, 1, 0);
	draw_outline_text("Heal: " + string(num_heal),			c_black, global.color_heal, 2, stat_x + stat_col_spacing, stat_y + stat_row_spacing * 3, 1, 1, 0);
	draw_outline_text("Ink: " + string(num_intel),		c_black, global.text_intel, 2, stat_x + stat_col_spacing, stat_y + stat_row_spacing * 4, 1, 1, 0);
	draw_outline_text("Neutral: " + string(num_neutral),	c_black, c_white, 2, stat_x + stat_col_spacing, stat_y + stat_row_spacing * 5, 1, 1, 0);
	
	// Draw the number of keywords
	draw_outline_text("Stowaway: " + string(num_stowaway),				c_black, c_white, 2, stat_x, stat_y + stat_section_spacing + stat_row_spacing * 1, 1, 1, 0);
	draw_outline_text("Favourite: " + string(num_favourite),			c_black, c_white, 2, stat_x, stat_y + stat_section_spacing + stat_row_spacing * 2, 1, 1, 0);
	draw_outline_text("Coin: " + string(num_coin),						c_black, c_white, 2, stat_x, stat_y + stat_section_spacing + stat_row_spacing * 3, 1, 1, 0);
	draw_outline_text("Multitype: " + string(num_multitype),			c_black, c_white, 2, stat_x, stat_y + stat_section_spacing + stat_row_spacing * 4, 1, 1, 0);
	draw_outline_text("Followthrough: " + string(num_followthrough),	c_black, c_white, 2, stat_x, stat_y + stat_section_spacing + stat_row_spacing * 5, 1, 1, 0);
	draw_outline_text("Exclusive: " + string(num_exclusive),			c_black, c_white, 2, stat_x, stat_y + stat_section_spacing + stat_row_spacing * 6, 1, 1, 0);
	draw_outline_text("Loose: " + string(num_loose),					c_black, c_white, 2, stat_x, stat_y + stat_section_spacing + stat_row_spacing * 7, 1, 1, 0);
	draw_outline_text("Sticky: " + string(num_sticky),					c_black, c_white, 2, stat_x, stat_y + stat_section_spacing + stat_row_spacing * 8, 1, 1, 0);

	if (mouse_wheel_down()) scroll_y -= 100;
	if (mouse_wheel_up()) scroll_y += 100;
	
	var scroll_height = (ds_list_size(filtered_list) * -row_spacing) + room_height - 20;
	
	scroll_y = clamp(scroll_y, scroll_height, 0);
	
	// Draw scrollbar -- If room height is 1000, and scroll height is 2000, the scroll bar should be half the screen
	var scrollbar_w = 30;
	var scrollbar_size_ratio = room_height / abs(scroll_height - room_height);
	var scrollbar_h = scrollbar_size_ratio * room_height;
	var scrollbar_y = (abs(scroll_y) / abs(scroll_height - (room_height*1) + 40)) * room_height;
	
	draw_set_color(c_white);
	draw_set_alpha(0.4);
	draw_rectangle(0, scrollbar_y, scrollbar_w, scrollbar_y + scrollbar_h, false);
	
	var scroll_bar_hover = mouse_hovering(0, scrollbar_y, scrollbar_w, scrollbar_h, false);
	
	if (scroll_bar_hover) {
		
		if (mouse_check_button_pressed(mb_left)) {
			scroll_dragging = true;
			m_grab_y = device_mouse_y_to_gui(0); // GUI space, like everything else drawn here
			s_grab_y = scroll_y;
		}
	}
	
	// letting go anywhere ends the drag, not just over the bar
	if (!mouse_check_button(mb_left)) scroll_dragging = false;
	
		
	if (scroll_dragging) {
		scroll_y = lerp(scroll_y, s_grab_y + (m_grab_y - device_mouse_y_to_gui(0)), 0.5);
		scroll_y = clamp(scroll_y, scroll_height, 0);
	}

}

// the bag view and the dice picker (moved from Draw GUI so event, shop and workbench windows can't cover them)
var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();
var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);

// the toolbag's tools, dropped down under the top bar (moved from Draw GUI: random events and shops drew over them)
var tools_x = gui_w - 940; // under the toolbag icon (oRunManager Draw GUI)
if (show_tools) {
	for (var i = 0; i < ds_list_size(tools); i++) {
		var tool = tools[| i];
		var tile_width = sprite_get_width(sToolButton) + 10;
		var starting_offset = (ds_list_size(tools)-1)/2 * tile_width; // 1 tool, offset by 0, 2 tools, offset by 0.5, 3 tools offset by 1,
		var tool_x = tools_x - starting_offset + (tile_width*i);
		
		var tool_hover = mouse_hovering(tool_x, 130, tile_width - 10, tile_width - 10, true);
		
		tools_scale[| i] = lerp(tools_scale[| i], tool_hover ? 1.2 : 1.0, 0.2);
		
		draw_sprite_ext(sToolButton, 0, tool_x, 130, tools_scale[| i], tools_scale[| i], 0, c_gray, 1.0);
		draw_sprite_ext(sToolSilhouettes, tool.index, tool_x, 130, tools_scale[| i], tools_scale[| i], 0, c_gray, 1.0);
		
		if (tool_hover) {
			queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), tool.name, tool.desc);

			if (mouse_check_button_pressed(mb_left) && global.ui_layer == UI_LAYER.BASE) {
				if (room == rmWorkbench) {
					if (instance_exists(oWorkbenchManager) && array_contains(oWorkbenchManager.tools_used, tool.object)) {
						throw_error("Used this visit", "Each tool works once per visit.");
					} else if (!instance_exists(tool.object)) {
						var pos_x;
						var pos_y;
				
						switch(i) {
							case 0:
							pos_x = gui_w - 150;
							pos_y = gui_h/2 + 50;
							break;
					
							case 1:
							pos_x = 150;
							pos_y = gui_h/2 + 50;
							break;
					
							case 2:
							pos_x = gui_w - 300;
							pos_y = gui_h - 200;
							break;
						}
						instance_create_layer(pos_x, pos_y, "Instances", tool.object);
					} else {
						throw_error("Already out", "This tool is already on the workbench.");
					}
				} else {
					throw_error("Workbench only", "Tools work only at the workbench.");
				}
			}
		}
	}
} else {
	if (tools_scale[| 0] > 0.5) {
		for (var i = 0; i < ds_list_size(tools); i++) {
			tools_scale[| i] = 0.5;
		}
	}
}



// insight view (the eye in a fight): darkens everything but what insight can buy, drawn over the whole Draw GUI
combat_insight_view_draw();

// the bag icon (bottom left), above the map and every room window
// Draw bag preview
var bag_x = global.gui.bag_x;
var bag_y = global.gui.bag_y;
var bag_w = global.gui.bag_w;
var bag_h = global.gui.bag_h;
bag_hover = mouse_hovering(bag_x, bag_y, bag_w, bag_h, false);

// Draw draw bag (discard bag in oCombat)
if (bag_hover || show_bag_contents) {
	draw_sprite_ext(sDiceBag, 0, 56, gui_h - 36, 1.07, 1.07, 0, c_black, 1);
}
draw_sprite(sDiceBag, 0, 60, gui_h - 40);
draw_set_font(ftBigger);
draw_set_valign(fa_bottom)
draw_set_halign(fa_left);
draw_outline_text(room = rmCombat ? "DRAW" : "BAG", c_black, c_white, 2, 110, gui_h - 33, 1, 1, 0);

// Draw bag count
draw_set_color(c_black);
draw_circle(70, gui_h - 55, 20, false);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(c_white);
draw_set_font(ftBig);
draw_text(70, gui_h - 55, string(ds_list_size(global.dice_bag)));

if (bag_hover) {
	if (mouse_check_button_pressed(mb_left) && !global.all_input_disabled && instance_exists(oWorkbenchManager) && oWorkbenchManager.pick_pending) {
		workbench_open_picker(); // at the workbench, opening the bag is how you choose your dice
	} else if (mouse_check_button_pressed(mb_left) && !global.all_input_disabled) {
		show_bag_contents = 1 - show_bag_contents;
		bag_to_show = global.dice_bag;
		
		if (global.ui_layer != UI_LAYER.BAG) {
			pre_bag_open_ui_layer = global.ui_layer;
			global.ui_layer = UI_LAYER.BAG;
			show_debug_message("pre_bag_open_ui_layer: " + string(pre_bag_open_ui_layer));
		} else {
			global.ui_layer = pre_bag_open_ui_layer;
		}
	}
	queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Dice bag", "See the dice inside.");
}

// show bag contents
if (show_bag_contents) {
	var bag_inner_padding = 200; // offset from the edges to start drawing dice
	var bag_outer_padding = 170;
	
	// darken everything below the top bar (the bar stays in full colour)
	draw_set_alpha(0.65);
	draw_set_color(make_color_rgb(18, 22, 32));
	draw_rectangle(0, ui_top_bar_h(), display_get_gui_width(), display_get_gui_height(), false);
	draw_set_alpha(1);
	
	// Draw bag title
	draw_set_font(ftBigger);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	
	if (dice_selection_message == "") {
		switch (bag_to_show) {
			case global.dice_bag: bag_title = "Dice bag" break;
			case global.discard_pile: bag_title = "Discard pile" break;
		}
	}
	
	draw_outline_text(bag_title, c_black, c_white, 2, bag_outer_padding, bag_outer_padding - 56, 1, 1, 0);
	bag_controls_draw(bag_to_show, bag_outer_padding);
	ui_divider(bag_outer_padding, bag_outer_padding + 420, bag_outer_padding - 10);
	ui_panel(bag_outer_padding, bag_outer_padding, display_get_gui_width() - bag_outer_padding, display_get_gui_height() - bag_outer_padding);
	
	var bag_width =		display_get_gui_width() - (bag_inner_padding * 2);
	var bag_height =	display_get_gui_height() - (bag_inner_padding * 2);

	if ((mouse_check_button_pressed(mb_left) || mouse_check_button_pressed(mb_right)) && !mouse_hovering(bag_outer_padding, bag_outer_padding - 64, display_get_gui_width() - bag_outer_padding*2, display_get_gui_height() - bag_outer_padding*2 + 64, false, noone, soClick4, true, UI_LAYER.BAG) /* the title row with the sort and filter buttons counts as inside */) {
		if (show_bag_contents && !bag_hover) {
			if (room == rmCombat) {
				if (!oCombat.disc_bag_hover) {
					show_bag_contents = false;
					global.ui_layer = UI_LAYER.BASE;
				}
			} else {
				show_bag_contents = false;
				global.ui_layer = UI_LAYER.BASE;
			}
		}
	}
		
	// Set draw sizes
	var scrollbar_w = 30;
	
	// five cards a row (compact, Molly); every row as tall as the tallest card in view needs (bag_card_layout)
	var bag_cols = 5;
	var col_spacing = (bag_width - (scrollbar_w * 4)) / bag_cols;
	var box_width = col_spacing - 24;

	var _view = bag_view_list(bag_to_show);
	var box_height = 150;
	for (var _c = 0; _c < array_length(_view); _c++) box_height = max(box_height, bag_card_layout(_view[_c], box_width).h);
	var row_spacing = box_height + 24;
	
	var inner_padding_w = box_width/2
	var inner_padding_h = box_height/2;
	
	// the cards are drawn into a surface the size of the panel's inside and cut off at its edges, so a row half out of
	// view is drawn half, and you can see there's more (F157; they used to fade). The surface is at window resolution
	// (_bk) so text stays crisp; drawn with premultiplied alpha so soft edges don't darken.
	var _clip_x1 = bag_outer_padding + 4, _clip_y1 = bag_outer_padding + 4;
	var _clip_x2 = display_get_gui_width() - bag_outer_padding - 4, _clip_y2 = display_get_gui_height() - bag_outer_padding - 4;
	var _bk = max(0.5, window_get_width() / display_get_gui_width());
	var _bsw = max(1, ceil((_clip_x2 - _clip_x1) * _bk)), _bsh = max(1, ceil((_clip_y2 - _clip_y1) * _bk));
	if (surface_exists(bag_clip_surf) && (surface_get_width(bag_clip_surf) != _bsw || surface_get_height(bag_clip_surf) != _bsh)) surface_free(bag_clip_surf);
	if (!surface_exists(bag_clip_surf)) bag_clip_surf = surface_create(_bsw, _bsh);
	var _bmx = device_mouse_x_to_gui(0), _bmy = device_mouse_y_to_gui(0);
	var _mouse_in_clip = point_in_rectangle(_bmx, _bmy, _clip_x1, _clip_y1, _clip_x2, _clip_y2);
	var _bag_old_world = matrix_get(matrix_world);
	surface_set_target(bag_clip_surf);
	draw_clear_alpha(c_black, 0);
	matrix_set(matrix_world, matrix_build(-_clip_x1 * _bk, -_clip_y1 * _bk, 0, 0, 0, 0, _bk, _bk, 1));
	gpu_set_blendmode_ext_sepalpha(bm_src_alpha, bm_inv_src_alpha, bm_one, bm_inv_src_alpha);

	// what's shown: the bag filtered by type and sorted (bag_view_list, the controls above the panel)
	for (var i = 0; i < array_length(_view); i++) {
		
		// Increase spacing for next dice
		var dice_x = (bag_inner_padding + inner_padding_w + scrollbar_w*2) +		i mod bag_cols * col_spacing;
		var dice_y = (scroll_y + bag_inner_padding + inner_padding_h) +			i div bag_cols * row_spacing;
			
		var top_of_box = dice_y - box_height/2;
		var bottom_of_box = dice_y + box_height/2
		
		if (top_of_box - 12 < _clip_y2 && bottom_of_box + 12 > _clip_y1) {

			var dice = _view[i];
			var dice_alpha = 1; // cut off at the panel's edge by the surface, never faded

			// only the part you can see can be hovered or clicked
			var info_hover = _mouse_in_clip && mouse_hovering(dice_x - box_width/2, dice_y - box_height/2, box_width, box_height, false, noone, soClick4, true, UI_LAYER.BAG);
		
			if (info_hover) dice_hover = dice;
			
			// Functionality for selection events (not on the frames it opened: the click that opened it would pick a die)
			if (dice_selection != false) {
				if (mouse_check_button_pressed(mb_left) && info_hover && dice_selection_age > 2) {
					var filter_pass = false;
					
					switch (dice_selection_filter) {
						case "none":
							filter_pass = true; // allow all dice types through
						break;
						case "coin":
							if (dice.dice_value == 2) {
								filter_pass = true;
							} else {
								throw_error("Not a coin", "Choose a coin.");
							}
						break;
					}
					
					if (filter_pass) {
						if (dice.selected) {
							dice.selected = false;
							dice_selection_num_selected -= 1;
							var _ind = ds_list_find_index(dice_selection_list, dice);
							ds_list_delete(dice_selection_list, _ind);
							show_debug_message("dice_selection_list size: " + string(ds_list_size(dice_selection_list)));
						} else {
							// already full: the oldest pick makes way, so a new click always picks (Molly: picking 1 replaces it)
							if (dice_selection_num_selected >= dice_selection && ds_list_size(dice_selection_list) > 0) {
								dice_selection_list[| 0].selected = false;
								ds_list_delete(dice_selection_list, 0);
								dice_selection_num_selected -= 1;
							}
							if (dice_selection_num_selected < dice_selection) {
								dice.selected = true;
								dice_selection_num_selected += 1;
								ds_list_add(dice_selection_list, dice);
								show_debug_message("dice_selection_list size: " + string(ds_list_size(dice_selection_list)));
							}
						}
					}
				}
			}
			
			// the card (draw_bag_card): header with its name, the die and its range and types, the description
			draw_bag_card(dice, dice_x, dice_y, box_width, box_height, dice_alpha, info_hover, dice.selected);


			
		}
	}
	
	// the cards, cut to the panel
	gpu_set_blendmode(bm_normal);
	matrix_set(matrix_world, _bag_old_world);
	surface_reset_target();
	gpu_set_blendmode_ext(bm_one, bm_inv_src_alpha);
	draw_surface_ext(bag_clip_surf, _clip_x1, _clip_y1, 1 / _bk, 1 / _bk, 0, c_white, 1);
	gpu_set_blendmode(bm_normal);

	if (show_bag_dice_info && dice_hover != undefined) {
		//var info_x = bag_inner_padding + inner_padding + 30 + col_spacing * 12 + 20;
		//var info_y = bag_inner_padding + inner_padding/2;
		//draw_set_font(ftBig);
		//draw_set_halign(fa_left);
		//draw_set_valign(fa_top);
		//draw_text(info_x, info_y, "Distribution");
		//draw_dice_distribution(dice_hover, info_x + 10, info_y + 70, false);
		
		//info_y += 120;
		
		//draw_set_font(ftBig);
		//draw_set_halign(fa_left);
		//draw_set_valign(fa_top);
		//draw_text(info_x, info_y, "Roll history");
		//draw_dice_history(dice_hover, info_x + 10, info_y + 70, false);
		//draw_set_font(ftDefault);
		//for (var r = 0; r < array_length(dice_hover.statistics.roll_history); r++) {
		//	draw_text(info_x, info_y + 70 + ((r + 1) * 30), "Roll " + string(array_length(dice_hover.statistics.roll_history) - r) + ":" + string(dice_hover.statistics.roll_history[r]));
		//}
	}

	if (mouse_wheel_down()) scroll_y -= 100;
	if (mouse_wheel_up()) scroll_y += 100;
	
	// how far it can scroll: the rows' height past what the panel shows (none when everything fits)
	var _content_h = ceil(array_length(_view) / bag_cols) * row_spacing;
	var _max_scroll = max(0, _content_h - bag_height);
	var scroll_height = -_max_scroll;
	scroll_y = clamp(scroll_y, scroll_height, 0);
	
	//if (keyboard_check_pressed(vk_enter)) {
	//	show_debug_message("------");
	//	show_debug_message("Bag height: " + string(bag_height));
	//	show_debug_message("Scroll height: " + string(scroll_height));
	//	show_debug_message("Minimum size: " + string(minimum_size));
	//	show_debug_message("Scroll Y: " + string(scroll_y));
	//}
	
	// the scrollbar: its thumb is the share of the rows you can see, at where you are; no bar when everything fits
	var scrollbar_h = (_max_scroll > 0) ? bag_height * bag_height / _content_h : 0;
	var scrollbar_y = (_max_scroll > 0) ? (-scroll_y / _max_scroll) * (bag_height - scrollbar_h) : 0;
	if (_max_scroll > 0) {
	
	// the logbook look (F158): a slate groove with an inked edge, and a brass thumb with an ink outline and grip lines,
	// a little wider and brighter under the mouse or while dragged. Clicking the groove jumps there and keeps dragging.
	var scroll_bar_hover = mouse_hovering(bag_inner_padding, bag_inner_padding + scrollbar_y, scrollbar_w, scrollbar_h, false, noone, soClick4, true, UI_LAYER.BAG);
	var _sb_cx = bag_inner_padding + scrollbar_w / 2;
	var _sb_y1 = bag_inner_padding, _sb_y2 = bag_inner_padding + bag_height;
	draw_set_alpha(1);
	draw_set_color(global.ui_col.ink);
	draw_roundrect_ext(_sb_cx - 8, _sb_y1 - 2, _sb_cx + 8, _sb_y2 + 2, 14, 14, false);
	draw_set_color(global.ui_col.slate);
	draw_roundrect_ext(_sb_cx - 6, _sb_y1, _sb_cx + 6, _sb_y2, 12, 12, false);
	var _sb_lit = scroll_bar_hover || scroll_dragging;
	var _sb_hw = _sb_lit ? 12 : 10;
	var _sb_t1 = _sb_y1 + scrollbar_y, _sb_t2 = _sb_t1 + scrollbar_h;
	draw_set_color(global.ui_col.ink);
	draw_roundrect_ext(_sb_cx - _sb_hw - 2, _sb_t1 - 2, _sb_cx + _sb_hw + 2, _sb_t2 + 2, 16, 16, false);
	draw_set_color(_sb_lit ? merge_colour(global.ui_col.brass, global.ui_col.paper_hi, 0.35) : global.ui_col.brass);
	draw_roundrect_ext(_sb_cx - _sb_hw, _sb_t1, _sb_cx + _sb_hw, _sb_t2, 14, 14, false);
	// a paper glint down its left side, and three grip lines in the middle
	draw_set_alpha(0.45);
	draw_set_color(global.ui_col.paper_hi);
	draw_line_width(_sb_cx - _sb_hw + 4, _sb_t1 + 8, _sb_cx - _sb_hw + 4, _sb_t2 - 8, 2);
	draw_set_alpha(1);
	if (scrollbar_h > 44) {
		var _sb_mid = (_sb_t1 + _sb_t2) / 2;
		draw_set_color(global.ui_col.ink);
		for (var _g = -1; _g <= 1; _g++) draw_line_width(_sb_cx - 5, _sb_mid + _g * 7, _sb_cx + 5, _sb_mid + _g * 7, 2);
	}
	var _groove_hover = mouse_hovering(bag_inner_padding, _sb_y1, scrollbar_w, bag_height, false, noone, noone, true, UI_LAYER.BAG);
	if (_groove_hover && !scroll_bar_hover && mouse_check_button_pressed(mb_left)) {
		var _sb_frac = clamp((device_mouse_y_to_gui(0) - _sb_y1 - scrollbar_h / 2) / max(1, bag_height - scrollbar_h), 0, 1);
		scroll_y = -_sb_frac * _max_scroll;
		scroll_dragging = true;
		m_grab_y = device_mouse_y_to_gui(0);
		s_grab_y = scroll_y;
	}
	
	if (scroll_bar_hover) {
		
		if (mouse_check_button_pressed(mb_left)) {
			scroll_dragging = true;
			m_grab_y = device_mouse_y_to_gui(0); // GUI space, like everything else drawn here
			s_grab_y = scroll_y;
		}
	}
	
	// letting go anywhere ends the drag, not just over the bar
	if (!mouse_check_button(mb_left)) scroll_dragging = false;
		
	if (scroll_dragging) {
		// dragging the thumb down moves the rows up, in step with the thumb
		scroll_y = s_grab_y - (device_mouse_y_to_gui(0) - m_grab_y) * (_max_scroll / max(1, bag_height - scrollbar_h));
		scroll_y = clamp(scroll_y, scroll_height, 0);
	}
	} else scroll_dragging = false;
} else {
	dice_hover = undefined;
}
	
if (dice_selection != false) {
	show_bag_contents = true;
	// the picker is a window: raise the layer so buttons underneath (the workbench's Exit sits right under Confirm)
	// can't be clicked through it
	if (global.ui_layer < UI_LAYER.BAG) global.ui_layer = UI_LAYER.BAG;
	
	bag_title = dice_selection_message;
		
	// Draw a button
	var dice_selection_col = c_lime;
	var button_text = "Confirm";
	var button_scale = 1.0;

	var _can_confirm = (dice_selection_num_selected == dice_selection || (dice_selection_up_to && dice_selection_num_selected <= dice_selection));
	// the same commit button, in the same spot, as the rooms' Continue under it (ui_primary), so it sits exactly over it
	var _confirm = ui_primary(gui_w - 44 - 140, gui_h - 40 - 48, 280, 96, (dice_selection_up_to && dice_selection_num_selected == 0) ? "Take none" : button_text, _can_confirm, "Choose " + string(dice_selection) + ((dice_selection == 1) ? " die" : " dice") + " first.", UI_LAYER.BAG);

	if (_confirm.hover || !_can_confirm) {
		if (_confirm.click) {
			// Loop through selected dice
			for (var i = ds_list_size(dice_selection_list) - 1; i >= 0; i--) {
				// Perform the function
				dice_selection_event(dice_selection_list[| i]);
				show_debug_message("performing event on dice " + string(dice_selection_list[| i]));
			}
				
			// Then reset the dice selection data
			dice_selection_event = undefined;
			dice_selection = false;
			dice_selection_message = "";
			dice_selection_num_selected = 0;
			dice_selection_filter = "none";
			dice_selection_up_to = false;
			ds_list_clear(dice_selection_list);
			show_debug_message("list clear");
			dice_hover = undefined;
			
			for (var i = ds_list_size(global.dice_bag) - 1; i >= 0; i--) {
				// Perform the function
				global.dice_bag[| i].selected = false;
			}
			
			show_bag_contents = false;
			global.ui_layer = UI_LAYER.BASE;
		}
	}
}

// floating numbers and words ("X replaced with Y"), above the bag view and the picker (B140)
global.damage_text_late = true;
with (oDamageText) event_perform(ev_draw, ev_gui);
global.damage_text_late = false;

// tooltips are drawn in Draw GUI End (Draw_75), after every window, so nothing covers them

// the first voyage's map notes and the one-time tips, above every window
tips_draw();

// the insight panel while hovered, over the tutorial notes and tips
insight_panel_draw();

// a core or potion being carried, above the workbench and every window
dragged_item_draw();

// the pause menu and the end-of-voyage summary, above everything but tooltips
pause_draw();
run_summary_draw();

// tooltips last, after every window and panel (Draw GUI End), so nothing draws over them
draw_all_tooltips();

// a room's opening ink wash (F65), over everything but the cursor
room_wipe_draw();

// the game's own mouse pointer, last of all during a run (above the bag, its darkening and every window).
// Outside a run (main menu) oSettingsMenu draws it instead.
cursor_draw();
