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
		draw_sprite_ext(sDice, get_dice_index(dice.dice_value), dice_x, dice_y, row_spacing/80, row_spacing/80, 0, get_dice_color(dice.action_type), 1.0);
		
		// Draw dice keywords
		draw_dice_keywords(dice, dice_x, dice_y, 1);
		
		// Draw dice name
		draw_set_font(ftDefault);
		draw_set_valign(fa_middle);
		draw_set_halign(fa_left);
		draw_outline_text(dice.name, c_black, c_white, 2, dice_x + col_spacing, dice_y - 10, 1, 1, 0);
		
		// Draw dice description
		draw_set_font(ftSmall);
	    var parsed = parse_text_with_keywords(dice.description);
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
		
		if (string_has_keyword(dice.description, "stowaway")) num_stowaway++;
		if (string_has_keyword(dice.description, "favourite")) num_favourite++;
		if (string_has_keyword(dice.description, "coin")) num_coin++;
		if (string_has_keyword(dice.description, "multitype")) num_multitype++;
		if (string_has_keyword(dice.description, "followthrough")) num_followthrough++;
		if (string_has_keyword(dice.description, "exclusive")) num_exclusive++;
		if (string_has_keyword(dice.description, "loose")) num_loose++;
		if (string_has_keyword(dice.description, "sticky")) num_sticky++;
		
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
	draw_outline_text("Intel: " + string(num_intel),		c_black, global.color_intel, 2, stat_x + stat_col_spacing, stat_y + stat_row_spacing * 4, 1, 1, 0);
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
			m_grab_y = mouse_y;
			s_grab_y = scroll_y;
		}
		
		if (mouse_check_button_released(mb_left)) {
			m_grab_y = 0;
			s_grab_y = 0;
		}
	}
	
		
	if (mouse_check_button(mb_left) && m_grab_y != 0) {
		scroll_y = lerp(scroll_y, s_grab_y + (m_grab_y - mouse_y), 0.5);
		scroll_y = clamp(scroll_y, scroll_height, 0);
	}
	
}

if (show_dice_bag || bag_hover_locked) {
	
	// Fill the background of the screen
	draw_set_alpha(1.0);
	draw_set_color(make_color_rgb(44, 40, 62));
	
	var bag_padding = 130;
	
	draw_rectangle(bag_padding, bag_padding, display_get_gui_width() - bag_padding, display_get_gui_height() - bag_padding, false);

	if (mouse_check_button_pressed(mb_left) && !mouse_hovering(bag_padding, bag_padding,  display_get_gui_width() - bag_padding*2, display_get_gui_height() - bag_padding*2, false)) {
		if (bag_hover_locked && !bag_hover) {
			bag_hover_locked = false;
		}
	}
	
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
	var inner_padding = 60;
	var dice_x = bag_padding + inner_padding + 30;
	var dice_y = scroll_y + bag_padding + inner_padding/2;
		
	// Set relative draw positions
	var col_spacing = 60;
	var row_spacing = 60;
	
	for (var i = 0; i < ds_list_size(global.dice_bag); i++) {
		
		if (dice_y < display_get_gui_height() - bag_padding && dice_y > bag_padding) {
		
			var dice = global.dice_bag[| i];
			var gap = min(abs(dice_y - (display_get_gui_height() - bag_padding)), abs(bag_padding - dice_y));
			var dice_alpha = 1.0 * gap/col_spacing;
		
			var info_hover = mouse_hovering(dice_x - col_spacing, dice_y - row_spacing/2, col_spacing * 12, row_spacing, false);
		
			if (info_hover) {
				dice_hover = dice;
			}
			
			// Draw alternating rows
			if (i mod 2 == 0) {
				draw_set_alpha(0.5 * dice_alpha);
				draw_set_color(c_black);
				draw_rectangle(dice_x - col_spacing, dice_y - row_spacing/2, dice_x + col_spacing * 12, dice_y + row_spacing/2, false);
			}
		
			if (info_hover || dice_hover == dice) {
				draw_set_alpha(0.5 * dice_alpha);
				draw_set_color(c_aqua);
				draw_rectangle(dice_x - col_spacing, dice_y - row_spacing/2, dice_x + col_spacing * 12, dice_y + row_spacing/2, false);
			}
		
			// Draw dice sprite
			draw_sprite_ext(sDice, get_dice_index(dice.dice_value), dice_x, dice_y, row_spacing/80, row_spacing/80, 0, get_dice_color(dice.action_type), dice_alpha);
		
			// Draw dice keywords
			draw_dice_keywords(dice, dice_x, dice_y, 1);
		
			// Draw dice name
			draw_set_font(ftDefault);
			draw_set_valign(fa_middle);
			draw_set_halign(fa_left);
			draw_outline_text(dice.name, c_black, c_white, 2, dice_x + col_spacing, dice_y - 10, 1, dice_alpha, 0);
		
			// Draw dice description
			draw_set_font(ftSmall);
		    var parsed = parse_text_with_keywords(dice.description);
		    var cursor_x = dice_x + col_spacing;
		    var cursor_y = dice_y + 10;

		    for (var p = 0; p < array_length(parsed); p++) {
		        draw_outline_text(parsed[p].text, c_black, parsed[p].colour, 2, cursor_x, cursor_y, 1, dice_alpha, 0);
		        cursor_x += string_width(parsed[p].text);
		    }
		}
		
		// Increase spacing for next dice
		dice_y += row_spacing;
	
	}
	
	if (show_bag_dice_info && dice_hover != undefined) {
		//var info_x = bag_padding + inner_padding + 30 + col_spacing * 12 + 20;
		//var info_y = bag_padding + inner_padding/2;
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
	
	// Total pixel height of the bag height
	var bag_height = display_get_gui_height() - (bag_padding * 2);
	
	// The adaptive height of the scrollable area
	var minimum_size = max(13.666667, ds_list_size(global.dice_bag)) * -row_spacing;
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
	var scrollbar_w = 30;
	var scrollbar_size_ratio = bag_height / abs(scroll_height - bag_height);
	var scrollbar_h = scrollbar_size_ratio * bag_height;
	var scrollbar_y = (abs(scroll_y) / abs(scroll_height - (bag_height*1))) * bag_height;
	
	draw_set_color(c_white);
	draw_set_alpha(0.4);
	draw_rectangle(bag_padding, bag_padding + scrollbar_y, bag_padding + scrollbar_w, bag_padding + scrollbar_y + scrollbar_h, false);
	
	var scroll_bar_hover = mouse_hovering(bag_padding, bag_padding + scrollbar_y, scrollbar_w, scrollbar_h, false);
	
	if (scroll_bar_hover) {
		
		if (mouse_check_button_pressed(mb_left)) {
			m_grab_y = mouse_y;
			s_grab_y = scroll_y;
		}
		
		if (mouse_check_button_released(mb_left)) {
			m_grab_y = 0;
			s_grab_y = 0;
		}
	}
		
	if (mouse_check_button(mb_left) && m_grab_y != 0) {
		scroll_y = lerp(scroll_y, s_grab_y + (m_grab_y - mouse_y), 0.5);
		scroll_y = clamp(scroll_y, scroll_height, 0);
	}
} else {
	dice_hover = undefined;
}