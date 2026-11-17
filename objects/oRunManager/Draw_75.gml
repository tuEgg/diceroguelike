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
		draw_sprite_ext(sDice, get_dice_index(dice.dice_value), dice_x, dice_y, row_spacing/80, row_spacing/80, 0, get_dice_color(dice.possible_type), 1.0);
		
		// Draw dice keywords
		draw_dice_keywords(dice, dice_x, dice_y, 1);
		
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
	draw_outline_text("Insight: " + string(num_intel),		c_black, global.color_intel, 2, stat_x + stat_col_spacing, stat_y + stat_row_spacing * 4, 1, 1, 0);
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
	queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Click to open", "Details all the dice you have in your bag");
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
	ui_divider(bag_outer_padding, bag_outer_padding + 420, bag_outer_padding - 10);
	ui_panel(bag_outer_padding, bag_outer_padding, display_get_gui_width() - bag_outer_padding, display_get_gui_height() - bag_outer_padding);
	
	var bag_width =		display_get_gui_width() - (bag_inner_padding * 2);
	var bag_height =	display_get_gui_height() - (bag_inner_padding * 2);

	if ((mouse_check_button_pressed(mb_left) || mouse_check_button_pressed(mb_right)) && !mouse_hovering(bag_outer_padding, bag_outer_padding, display_get_gui_width() - bag_outer_padding*2, display_get_gui_height() - bag_outer_padding*2, false, noone, soClick4, true, UI_LAYER.BAG)) {
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
	
	var col_spacing = (bag_width - (scrollbar_w * 4)) / 5;
	var box_width = col_spacing - 20;
	
	var row_spacing = bag_height / 3;
	var box_height = row_spacing - 20;
	
	var inner_padding_w = box_width/2
	var inner_padding_h = box_height/2;
	
	for (var i = 0; i < ds_list_size(bag_to_show); i++) {
		
		// Increase spacing for next dice
		var dice_x = (bag_inner_padding + inner_padding_w + scrollbar_w*2) +		i mod 5 * col_spacing;
		var dice_y = (scroll_y + bag_inner_padding + inner_padding_h) +			i div 5 * row_spacing;
			
		var top_of_box = dice_y - box_height/2;
		var bottom_of_box = dice_y + box_height/2
		
		if (top_of_box < display_get_gui_height() - bag_inner_padding && bottom_of_box > bag_inner_padding) {
		
			var dice = bag_to_show[| i];
			
			var top_edge_overlap = bag_inner_padding - top_of_box;
			var bottom_edge_overlap = (bottom_of_box - (display_get_gui_height() - bag_inner_padding));
			edge_overlap = max(top_edge_overlap, bottom_edge_overlap);
			var dice_alpha = min(1, 1 - (edge_overlap / (box_height/1.5)));
		
			var info_hover = mouse_hovering(dice_x - box_width/2, dice_y - box_height/2, box_width, box_height, false, noone, soClick4, true, UI_LAYER.BAG);
		
			if (info_hover) {
				dice_hover = dice;
				
				// Give highlighted dice a white border
				draw_set_alpha(dice_alpha);
				draw_set_color(c_white);
				draw_roundrect(dice_x - box_width/2 - 2, dice_y - box_height/2 - 2, dice_x + box_width/2 + 2, dice_y + box_height/2 + 2, false);
			}
			
			// Functionality for selection events
			if (dice_selection != false) {
				if (mouse_check_button_pressed(mb_left) && info_hover) {
					var filter_pass = false;
					
					switch (dice_selection_filter) {
						case "none":
							filter_pass = true; // allow all dice types through
						break;
						case "coin":
							if (dice.dice_value == 2) {
								filter_pass = true;
							} else {
								throw_error("Not a coin", "You must select a coin");
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
			
			// Give each dice its own background, edged in its rarity colour
			draw_set_alpha(dice_alpha);
			var rarity_col = make_color_rgb(44, 40, 62);
			switch(dice.rarity) {
				case "common": rarity_col = global.color_common; break;
				case "uncommon": rarity_col = global.color_uncommon; break;
				case "rare": rarity_col = global.color_rare; break;
			}
			draw_set_color(rarity_col);
			draw_roundrect(dice_x - box_width/2 - 3, dice_y - box_height/2 - 3, dice_x + box_width/2 + 3, dice_y + box_height/2 + 3, false);
			draw_set_color(make_color_rgb(44, 40, 62));
			if (dice.selected) draw_set_color(c_green);
			draw_roundrect(dice_x - box_width/2, dice_y - box_height/2, dice_x + box_width/2, dice_y + box_height/2, false);
		
			// Draw dice sprite (multitype dice blend their colours)
			draw_sprite_ext(sDice, get_dice_index(dice.dice_value), dice_x - box_width/3.75, dice_y - box_height/3.75, 1.0, 1.0, 0, get_dice_color(dice.possible_type), dice_alpha);
		
			// Draw dice keywords
			draw_dice_keywords(dice, dice_x - box_width/3.75, dice_y - box_height/3.75, 1, dice_alpha);
			
			// Draw dice range
			var dice_output = get_dice_output(dice, -1, -1, true, "player"); // read only: viewing the bag must never trigger keepsakes
	
			var off_x = 0;
			var off_y = 0;
	
			// nudge the numbers to suit this die's shape (it used oRunManager's own image_index, so it never changed)
			switch (get_dice_index(dice.dice_value)) {
				case 1:
				off_x = -4;
				off_y = 3;
				break;
				case 2:
				off_x = -2;
				off_y = 1;
				break;
				case 3:
				case 4:
				case 5:
				off_x = -2;
				off_y = -1;
				break;
			}
			
			var _min_roll = dice_output.min_roll;			
			var _max_roll = dice_output.max_roll;
	
			draw_set_font(ftSmall);
			draw_set_halign(fa_center);
			draw_set_valign(fa_middle);
			draw_outline_text(string(_min_roll) + "-" + string(_max_roll), c_black, c_white, 2, dice_x - box_width/3.75 + off_x, dice_y - box_height/3.75 + off_y, 1, 1, 0, -1);
		
			// Draw dice name
			draw_set_font(ftDefault);
			draw_set_valign(fa_middle);
			draw_set_halign(fa_left);
			draw_outline_text(dice.name, c_black, c_white, 2, dice_x - 10, dice_y - box_height/3.5, 1, dice_alpha, 0, box_width/4);
		
			// Draw dice description
			draw_set_font(ftDescriptions);
			draw_set_valign(fa_top);
		    var desc_x = dice_x - box_width/2 + 20;
		    var desc_y = dice_y;
			
			var colored_desc = colorcode_text(die_description(dice));
			draw_outline_text(colored_desc, c_black, c_white, 2, desc_x, desc_y, 1, dice_alpha, 0, col_spacing - 40);
			
			// Draw distribution
			if (dice.distribution != "") {
				var core_index = get_core_index(dice);
				
				draw_sprite_ext(
		            sCores, core_index,
		            dice_x + box_width/2 - 40,
		            dice_y - box_height/3.5 + 5,
		            0.75, 0.75, 0, c_white, 1
		        );
			
				if (info_hover) {
					draw_dice_distribution(dice, dice_x, dice_y - 100, true);
				}
			}
			
			
		}
	}
	
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
	
	// Total pixel height of the bag height, its never less than 3 rows high (hence 15)
	var minimum_size = min(3 * -row_spacing, (ds_list_size(bag_to_show) div 5 + ceil((ds_list_size(bag_to_show) mod 5)/5)) * -row_spacing);
	
	// The adaptive height of the scrollable area
	var scroll_height = minimum_size + bag_height;
	
	// The Y position in the world of the scroll bar
	scroll_y = clamp(scroll_y, scroll_height, 0);
	
	//if (keyboard_check_pressed(vk_enter)) {
	//	show_debug_message("------");
	//	show_debug_message("Bag height: " + string(bag_height));
	//	show_debug_message("Scroll height: " + string(scroll_height));
	//	show_debug_message("Minimum size: " + string(minimum_size));
	//	show_debug_message("Scroll Y: " + string(scroll_y));
	//}
	
	// Draw scrollbar -- If room height is 1000, and scroll height is 2000, the scroll bar should be half the screen
	var scrollbar_size_ratio = bag_height / abs(scroll_height - bag_height);
	var scrollbar_h = scrollbar_size_ratio * bag_height;
	var scrollbar_y = (abs(scroll_y) / abs(scroll_height - (bag_height*1))) * bag_height;
	
	draw_set_color(c_black);
	draw_set_alpha(0.4);
	draw_rectangle(bag_inner_padding, bag_inner_padding, bag_inner_padding + scrollbar_w, bag_inner_padding + bag_height, false);
	
	draw_set_color(c_white);
	draw_set_alpha(0.4);
	draw_rectangle(bag_inner_padding, bag_inner_padding + scrollbar_y, bag_inner_padding + scrollbar_w, bag_inner_padding + scrollbar_y + scrollbar_h, false);
	
	var scroll_bar_hover = mouse_hovering(bag_inner_padding, bag_inner_padding + scrollbar_y, scrollbar_w, scrollbar_h, false, noone, soClick4, true, UI_LAYER.BAG);
	
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
	var _confirm = ui_button(gui_w - 150, gui_h - 200, 200, 70, dice_selection_scale, (dice_selection_up_to && dice_selection_num_selected == 0) ? "Take none" : button_text, global.ui_primary, _can_confirm, "Choose " + string(dice_selection) + ((dice_selection == 1) ? " die" : " dice") + " first.", UI_LAYER.BAG);
	dice_selection_scale = _confirm.scale;

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
