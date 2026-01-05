gui_w = display_get_gui_width();
gui_h = display_get_gui_height();

var bar_height = sprite_get_height(sTopBar) - 3;
var bar_half = bar_height/2;

// Draw top bar
draw_sprite(sTopBar, 1, -3, -4);

// Draw voyage act
draw_set_font(ftBig);
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
var act = "I";
switch (voyage) {
	case 1:
	act = "II";
	break;
	case 2:
	act = "III";
	break;
	case 3:
	act = "IV";
	break;
}
draw_outline_text("Voyage " + act, c_black, c_white, 2, 20, bar_half, 1, 1, 0);
var voyage_hover = mouse_hovering(20, 15, string_width("Voyage III"), string_height("Voyage III"), false);
if (voyage_hover) queue_tooltip(mouse_x, mouse_y, "Voyages Sailed", "You are on voyage " + string(act) + "/III", undefined, 0, undefined);

// Draw pages turned
draw_set_halign(fa_center);
draw_set_valign(fa_top);
var pages_x = 190;
draw_sprite_ext(sPaper, 0, pages_x, bar_half, 0.8, 0.8, 0, c_white, 1.0);
draw_outline_text(string(oWorldManager.nodes_cleared), c_black, c_white, 2, pages_x + 20, bar_half, 1, 1, 0);
var pages_hover = mouse_hovering(pages_x, bar_half, sprite_get_width(sPaper), sprite_get_height(sPaper), true);
if (pages_hover) queue_tooltip(mouse_x, mouse_y, "Events Explored", "You have explored " + string(oWorldManager.nodes_cleared) + " events from the Captain's logbook", undefined, 0, undefined);

// Draw money
var nodes_x = pages_x + 80;
draw_sprite_ext(sCoin, 1, nodes_x, bar_half, credits_scale * 0.8, credits_scale * 0.8, 0, c_white, 1.0);
draw_outline_text(string(credits), c_black, c_white, 2, nodes_x + 20, bar_half, 1, 1, 0);
var credits_hover = mouse_hovering(nodes_x, bar_half, sprite_get_width(sPaper), sprite_get_height(sPaper), true);
if (credits_hover) queue_tooltip(mouse_x, mouse_y, "Gold Doubloons", "You have " + string(credits) + " gold doubloons", undefined, 0, undefined);
credits_scale = lerp(credits_scale, 1.0, 0.05);

// Draw health
var health_x = nodes_x + 100;
draw_sprite(sHeart, 0, health_x, bar_half);
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_set_font(ftBig);
draw_outline_text(string(global.player_hp) + "/" +string(global.player_max_hp), c_black, c_white, 2, health_x + 30, bar_half, 1, 1, 0);
health_scale = lerp(health_scale, 1.0, 0.2);

// Draw cores and consumables
var core_x = health_x + 185;
var core_y = bar_half;

for (var i = 0; i < array_length(items); i++) {
	var i_x = i * 80;
	var sprite_x;
	var sprite_y;
	
	if (items[i] != undefined) {
		if (items[i].dragging) {
			sprite_x = mouse_x;
			sprite_y = mouse_y;
		} else {
			sprite_x = core_x;
			sprite_y = core_y;
		}
	}
	
	draw_sprite_ext(sTopBarSlot, 0, core_x + i_x, core_y, 0.8, 0.8, 0, c_white, 1.0);
	
	if (items[i] != undefined) {
		var default_scale = 0.8;
		var default_angle = 0;
		
		if (items[i].type == "consumable") {
			default_scale = 0.9;
			default_angle = -30;
		}
		
		draw_sprite_ext(items[i].sprite, items[i].index, sprite_x, sprite_y, items_hover_scale[i], items_hover_scale[i], default_angle, c_white, 1.0);
		
		//draw_outline_text(items[i].quantity, c_black, c_white, 2, core_x + 70 + 5 + i_x, 25, 1, 1, 0);
		
		items_hover[i] = mouse_hovering(core_x + i_x, core_y, sprite_get_width(sTopBarSlot), sprite_get_height(sTopBarSlot), true);
		
		items_hover_scale[i] = lerp(items_hover_scale[i], items_hover[i] ? default_scale * 1.2 : default_scale, 0.2);
		
		if (items_hover[i]) {
			var die = undefined;
			if (string_pos("Core", items[i].name) > 0) {
				die = clone_die(global.dice_d6_atk, "");
				die.distribution = items[i].distribution;
			}
			queue_tooltip(mouse_x, mouse_y, items[i].name, items[i].description, undefined, 0, die);
		}
		
		if (!global.main_input_disabled) {
			// Add core dragging functionality
			if (room == rmWorkbench) {
				if (items[i].type == "core") {
					// drag the core
					if (items_hover[i] && mouse_check_button(mb_left)) {
						items[i].dragging = true;
					}
					// release the core
					if (items[i].dragging and mouse_check_button_released(mb_left)) {
						items[i].dragging = false;
					}
				}
			}
		
			// Add potion dragging functionality
			if (items[i].type == "consumable") {

				if (items_hover[i] && mouse_check_button(mb_left) && !holding_item) {
					items[i].dragging = true;
					holding_item = true;
				}

				if (items[i].dragging and mouse_check_button_released(mb_left)) {
					items[i].dragging = false;
					holding_item = false;
				}
			
				if (items[i].dragging && mouse_check_button_pressed(mb_left)) {
					if (items[i].effects.trigger == "on_clicked" && items[i].effects.flags() ) {
						var ctx = {
							use_potion: true,
						};
						trigger_item_effects(items[i], "on_clicked", ctx);
						combat_trigger_effects("on_consumable_used", ctx);
						if (ctx.use_potion) {
							items[i] = undefined;
							holding_item = false;
						}
					}
				}

				if (items_hover[i] && mouse_check_button(mb_right)) {
					// delete item - need to add confirmation window to this
					items[i] = undefined;
					holding_item = false;
				}
			}
		}
	}
}

// Draw tools
draw_set_font(ftBig);
var tools_x = gui_w - 860;
draw_outline_text("Tools: " + string(ds_list_size(tool_list)) + "/5", c_black, c_white, 2, tools_x, bar_half, 1, 1.0, 0);

// Draw alignment
var alignment_color = make_color_rgb(250, 166, 20);
var alignment_x = gui_w - 450;

var alignment_hover = mouse_hovering(alignment_x, bar_half, sprite_get_width(sAlignmentBar), sprite_get_height(sAlignmentBar), true);
draw_sprite_ext(sMapIcon, 8, gui_w - 620, bar_half, 1, 1, 0, c_white, 1.0);
draw_sprite_ext(sAlignmentBar, 0, alignment_x, bar_half, alignment_scale, alignment_scale, 0, c_white, 1.0);
alignment_scale = lerp(alignment_scale, 1.0, 0.2);

var alignment_pos_x = alignment_x - 70 + ((global.player_alignment) * 1.4);
draw_sprite_ext(sCircleSmall, 0, alignment_pos_x, bar_half + 2, 1, 1, 0, c_white, 1.0);

if (alignment_hover) {
	queue_tooltip(mouse_x, mouse_y, "Alignment", "Actions have consequences, you currently have neutral alignment.");
}

// Draw bounty information
draw_sprite_ext(sMapIcon, 5, gui_w - 250, 45, 1, 1, 0, c_white, 1.0);

draw_set_font(ftBig);
var bounty_name = "-";
var bounty_description = "You aren't hunting any bounties";
var bounty_col = c_dkgray;
if (active_bounty != undefined) {
	bounty_name = active_bounty.enemy_name;
	bounty_description =  "Defeat " + string(active_bounty.enemy_name) + " " +active_bounty.condition.description;
	bounty_col = c_white;
	if (active_bounty.condition.failed) {
		bounty_description = "Bounty failed.";
		bounty_col = c_red;
	}
	if (active_bounty.complete) {
		bounty_name = active_bounty.enemy_name;
		bounty_description =  "Bounty completed.";
		bounty_col = c_lime;
	}
}
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_outline_text(bounty_name, c_black, bounty_col, 2, gui_w - 250 + 30, 44, 1, 1, 0);

var bounty_hover = mouse_hovering(gui_w - 280, 20, 300, 50, false); 
if (bounty_hover) {
	queue_tooltip(mouse_x, mouse_y, "Active Bounty: " + bounty_name, bounty_description);
}

// Keep scale list synced with keepsake size
if (ds_list_size(keepsake_scale) < ds_list_size(keepsakes)) {
    repeat(ds_list_size(keepsakes) - ds_list_size(keepsake_scale)) ds_list_add(keepsake_scale, 4.0);
} else if (ds_list_size(keepsake_scale) > ds_list_size(keepsakes)) {
    repeat(ds_list_size(keepsake_scale) - ds_list_size(keepsakes)) ds_list_delete(keepsake_scale, ds_list_size(keepsake_scale) - 1);
}

// Draw keepsakes
var ks_x = 15;

for (var k = 0; k < ds_list_size(keepsakes); k++) {
	var xx = (k mod 31) * 60;
	var ks_y = bar_height + 10 + ((k div 31) * 60);
	var _keepsake = keepsakes[| k];
	var btn_size = 64;
	var btn = draw_gui_button(ks_x + xx, ks_y, btn_size, btn_size, keepsake_scale[| k], "", c_white, ftSmall, 1, false);
	keepsake_scale[| k] = btn.scale;
	draw_sprite_ext(sKeepsake, _keepsake.sub_image, ks_x + xx + btn_size/2, ks_y + btn_size/2, keepsake_scale[| k] * 0.8, keepsake_scale[| k] * 0.8, 0, c_white, 1);
	
	if (btn.hover) {
		queue_tooltip(mouse_x, mouse_y, keepsakes[| k].name, keepsakes[| k].desc, undefined, 0, undefined);
	}
}

var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);

// Draw bag preview
var bag_x = GUI_LAYOUT.BAG_X;
var bag_y = gui_h - GUI_LAYOUT.BAG_Y - GUI_LAYOUT.BAG_H;
var bag_w = GUI_LAYOUT.BAG_W;
var bag_h = GUI_LAYOUT.BAG_H;
bag_hover = (mx > bag_x && mx < bag_x + bag_w && my > bag_y && my < bag_y + bag_h);

// Draw draw bag (discard bag in oCombat)
if (bag_hover || bag_hover_locked) {
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
	show_dice_bag = true;
	
	if (mouse_check_button_pressed(mb_left)) {
		bag_hover_locked = 1 - bag_hover_locked;
	}
	
    //var bag_bg_offset = 200;
	//var bag_bg_w = 420;
	//var bag_bg_h = 180;
    //draw_set_color(c_black);
    //draw_set_alpha(0.3);
	//draw_roundrect(bag_bg_offset, gui_h - bag_bg_offset, bag_bg_offset + bag_bg_w, gui_h - bag_bg_offset - bag_bg_h, false);

    //// === Draw dice from bag ===
    //var dice_per_row = 5;
	//var dice_scale = 1;
    //var dice_spacing = 80 * dice_scale;
	//var padding = 50 * dice_scale;
    //var start_x = bag_bg_offset + padding;
    //var start_y = gui_h - bag_bg_offset - bag_bg_h + padding;

    //for (var i = 0; i < ds_list_size(global.dice_bag); i++) {
    //    var die_struct = global.dice_bag[| i];

    //    // Position in grid
    //    var col = i mod dice_per_row;
    //    var row = i div dice_per_row;

    //    var xx = start_x + (col * dice_spacing);
    //    var yy = start_y + (row * dice_spacing);

    //    // Choose color based on action type
    //    var colr = get_dice_color(die_struct.action_type);

    //    // Choose image index based on dice type
    //    var frame = get_dice_index(die_struct.dice_value);

    //    // Draw dice sprite
    //    draw_set_alpha(1);
    //    draw_set_color(colr);
    //    draw_sprite_ext(sDice, frame, xx, yy, dice_scale, dice_scale, 0, colr, 1);
	//	draw_dice_keywords(die_struct, xx, yy, 1);

    //    // Optional: outline or count number
    //    //draw_set_color(c_black);
    //    //draw_set_alpha(0.5);
    //    //draw_rectangle(xx - 32, yy - 32, xx + 32, yy + 32, false);
    //}
} else {
	show_dice_bag = false;
}

if (bag_hover_locked) {
	
	// When this is true we need to set a global interact to false that disables any other hovers or interaction
	
	var bag_inner_padding = 200; // offset from the edges to start drawing dice
	var bag_outer_padding = 170;
	
	// Draw darkened background
	draw_set_alpha(0.65);
	draw_set_color(make_color_rgb(24, 20, 32));
	draw_roundrect(0, 0, display_get_gui_width(), display_get_gui_height(), false);
	
	draw_set_alpha(0.85);
	draw_roundrect(bag_outer_padding, bag_outer_padding, display_get_gui_width() - bag_outer_padding, display_get_gui_height() - bag_outer_padding, false);
	
	var bag_width =		display_get_gui_width() - (bag_inner_padding * 2);
	var bag_height =	display_get_gui_height() - (bag_inner_padding * 2);

	if (mouse_check_button_pressed(mb_left) && !mouse_hovering(bag_outer_padding, bag_outer_padding, display_get_gui_width() - bag_outer_padding*2, display_get_gui_height() - bag_outer_padding*2, false)) {
		if (bag_hover_locked && !bag_hover) {
			bag_hover_locked = false;
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
	
	for (var i = 0; i < ds_list_size(global.dice_bag); i++) {
		
		// Increase spacing for next dice
		var dice_x = (bag_inner_padding + inner_padding_w + scrollbar_w*2) +		i mod 5 * col_spacing;
		var dice_y = (scroll_y + bag_inner_padding + inner_padding_h) +			i div 5 * row_spacing;
			
		var top_of_box = dice_y - box_height/2;
		var bottom_of_box = dice_y + box_height/2
		
		if (top_of_box < display_get_gui_height() - bag_inner_padding && bottom_of_box > bag_inner_padding) {
		
			var dice = global.dice_bag[| i];
			
			var top_edge_overlap = bag_inner_padding - top_of_box;
			var bottom_edge_overlap = (bottom_of_box - (display_get_gui_height() - bag_inner_padding));
			edge_overlap = max(top_edge_overlap, bottom_edge_overlap);
			var dice_alpha = min(1, 1 - (edge_overlap / (box_height/1.5)));
		
			var info_hover = mouse_hovering(dice_x - box_width/2, dice_y - box_height/2, box_width, box_height, false);
		
			if (info_hover) {
				dice_hover = dice;
			}
			
			// Functionality for selection events
			if (dice_selection != false) {
				if (mouse_check_button_pressed(mb_left) && info_hover) {
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
	
			// Give highlighted dice a white border
			if (info_hover || dice_hover == dice) {
				draw_set_alpha(dice_alpha);
				draw_set_color(c_white);
				draw_roundrect(dice_x - box_width/2 - 2, dice_y - box_height/2 - 2, dice_x + box_width/2 + 2, dice_y + box_height/2 + 2, false);
			}
			
			// Give each dice its own background
			draw_set_alpha(dice_alpha);
			draw_set_color(make_color_rgb(44, 40, 62));
			if (dice.selected) draw_set_color(c_green);
			draw_roundrect(dice_x - box_width/2, dice_y - box_height/2, dice_x + box_width/2, dice_y + box_height/2, false);
		
			// Draw dice sprite - need to add blended draws here for multitype die
			draw_sprite_ext(sDice, get_dice_index(dice.dice_value), dice_x, dice_y - 30, 1.0, 1.0, 0, get_dice_color(dice.action_type), dice_alpha);
		
			// Draw dice keywords
			draw_dice_keywords(dice, dice_x, dice_y, 1);
		
			// Draw dice name
			draw_set_font(ftDefault);
			draw_set_valign(fa_middle);
			draw_set_halign(fa_center);
			draw_outline_text(dice.name, c_black, c_white, 2, dice_x, dice_y + 25, 1, dice_alpha, 0);
		
			// Draw dice description
			draw_set_font(ftSmall);
		    var parsed = parse_text_with_keywords(dice.description);
		    var desc_x = dice_x;
		    var desc_y = dice_y + 60;

		    for (var p = 0; p < array_length(parsed); p++) {
		        draw_outline_text(parsed[p].text, c_black, parsed[p].colour, 2, desc_x, desc_y, 1, dice_alpha, 0, col_spacing - 40);
		        desc_x += string_width(parsed[p].text);
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
	var minimum_size = min(3 * -row_spacing, ds_list_size(global.dice_bag) div 5 * -row_spacing);
	
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
	
	var scroll_bar_hover = mouse_hovering(bag_inner_padding, bag_inner_padding + scrollbar_y, scrollbar_w, scrollbar_h, false);
	
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
	
if (dice_selection != false) {
	bag_hover_locked = true;
		
	// Draw the message
	draw_set_font(ftBigger);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_outline_text(dice_selection_message, c_black, c_white, 2, gui_w/2, 120, 1, 1, 0, 800);
		
	// Draw a button
	var dice_selection_col = c_lime;
	var button_text = "Confirm";
	var button_scale = 1.0;

	var hover_dice_selection = mouse_hovering(gui_w - 150, gui_h - 200, dice_selection_scale * sprite_get_width(sButtonSmall) * button_scale, dice_selection_scale * sprite_get_height(sButtonSmall), true);

	if (hover_dice_selection) {
		if (mouse_check_button_pressed(mb_left) && dice_selection_num_selected == dice_selection) {
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
			ds_list_clear(dice_selection_list);
			show_debug_message("list clear");
			dice_hover = undefined;
			
			for (var i = ds_list_size(global.dice_bag) - 1; i >= 0; i--) {
				// Perform the function
				global.dice_bag[| i].selected = false;
			}
		}
		dice_selection_scale = lerp(dice_selection_scale, 1.2, 0.2);
	} else {
		dice_selection_scale = lerp(dice_selection_scale, 1.0, 0.2);
	}

	draw_set_font(ftBigger);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_sprite_ext(sButtonSmall, 0, gui_w - 150, gui_h - 200, dice_selection_scale * button_scale, dice_selection_scale, 0, dice_selection_col, 1.0);
	draw_outline_text(button_text, c_black, c_white, 2, gui_w - 150, gui_h - 200, 1, 1, 0);
}

// Draw all tooltips
draw_all_tooltips();