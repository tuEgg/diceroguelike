if (room == rmBounty) {
	var gui_w = display_get_gui_width();
	var gui_h = display_get_gui_height();

	if mouse_check_button_pressed(mb_right) {
		oRunManager.active_bounty = undefined;
		bounty_selected = -1;
	}

	// Draw title and text on the left side
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_font(ftHuge);
	draw_outline_text("Bounty\nHuntin'", c_black, c_white, 4, 50, 200, 1, 1, 0);
	draw_set_font(ftBig);
	draw_outline_text("Pick a boss to hunt. Meet its condition for a bigger reward.",
		c_black, c_white, 2, 50, 370, 1, 1, 0, 400);
	

	// "On the house" (F129): the free potion as a card of its own, so it's clearly yours to take: the potion bobbing on a
	// plate, its name and what it does, and a Take it button (it says why when your item slots are full); a stamp once taken
	var pot = potion;
	var _cx1 = 50, _cy1 = 600, _cx2 = 450, _cy2 = 860;
	ui_panel(_cx1, _cy1, _cx2, _cy2);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_font(ftBig);
	draw_outline_text("On the house", c_black, make_color_rgb(242, 210, 74), 2, _cx1 + 26, _cy1 + 22, 1, 1, 0);
	// the potion on a plate
	var pot_x = _cx1 + 80, pot_y = _cy1 + 130 + sin(current_time / 400) * 4 * !pot.taken;
	draw_set_alpha(0.35);
	draw_set_color(c_black);
	draw_ellipse(pot_x - 44, _cy1 + 160, pot_x + 44, _cy1 + 178, false);
	draw_set_alpha(1);
	draw_set_color(make_color_rgb(200, 190, 170));
	draw_ellipse(pot_x - 40, _cy1 + 156, pot_x + 40, _cy1 + 172, false);
	var hover_con = !pot.taken && mouse_hovering(pot_x, pot_y, sprite_get_width(pot.sprite), sprite_get_height(pot.sprite), true);
	potion_scale = lerp(potion_scale, hover_con ? 1.15 : 1.0, 0.2);
	draw_sprite_ext(pot.sprite, pot.index, pot_x, pot_y, potion_scale, potion_scale, 0, c_white, pot.taken ? 0.35 : 1);
	if (hover_con) {
		var die = undefined;
		if (string_pos("Core", pot.name) > 0) { die = core_preview_die(); die.distribution = pot.distribution; }
		queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), pot.name, pot.description, undefined, 0, die);
	}
	// its name and what it does
	var _tx = _cx1 + 150;
	draw_set_font(ftDefault);
	draw_outline_text(pot.name, c_black, c_white, 2, _tx, _cy1 + 78, 1, 1, 0, _cx2 - _tx - 20);
	draw_set_font(ftDescriptions);
	draw_outline_text(colorcode_text(pot.description), c_black, make_color_rgb(225, 225, 235), 1, _tx, _cy1 + 108, 1, 1, 0, _cx2 - _tx - 20);
	// take it (free), or a stamp once it's yours
	if (!pot.taken) {
		var _room = oRunManager.has_space_for_item;
		var _take = ui_button(_cx2 - 110, _cy2 - 52, 170, 56, potion_btn_scale, "Take it", global.ui_primary, _room, "Your item slots are full. Use or drop an item first.", UI_LAYER.BASE, 1, ftDefault);
		potion_btn_scale = _take.scale;
		if (_take.click && _room) gain_item(pot); // free
		if (!_room) {
			draw_set_font(ftDescriptions);
			draw_set_halign(fa_left);
			draw_outline_text("Item slots full", c_black, make_color_rgb(230, 120, 110), 1, _cx1 + 26, _cy2 - 62, 1, 1, 0);
		}
	} else {
		draw_set_font(ftBig);
		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		draw_outline_text("Taken", c_black, make_color_rgb(120, 200, 120), 3, _cx2 - 110, _cy2 - 52, 1, 1, 12);
	}
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	
	// Draw the bounties
	for (var b = 0; b < array_length(bounty); b++) {
		var _bounty = bounty[b];
		var bounty_x = 900 + (b * (sprite_get_width(sBountyContract) + 30));
		var bounty_y = gui_h/2 - 100 - bounty_offset[b];
	
		// Draw bounty contract paper sprite
		var blend = c_white;
		if (bounty_selected != -1 && bounty_selected != b) {
			//blend = c_dkgray;
		} else if (b == bounty_selected) {
			blend = make_colour_rgb(200, 180, 40)
		}
		draw_sprite_ext(sBountyContract, 0, bounty_x, bounty_y, bounty_scale[b], bounty_scale[b], 0, blend, 1.0);
	
	
		// Draw bounty contract details
		var details_x = bounty_x - sprite_get_width(sBountyContract)/2 + 120;
		var details_y = bounty_y - sprite_get_height(sBountyContract)/2 + 50;
	
			// Enemy name
			draw_set_halign(fa_left);
			draw_set_valign(fa_top);
			draw_set_font(ftBiggest);
			draw_outline_text(_bounty.enemy_name, c_black, c_white, 2, details_x, details_y - 8, 1, 1, 0, 200);

			// Coin reward
			draw_sprite_ext(sCoin, 1, details_x + 280, details_y + 35, 1, 1, 0, c_white, 1.0);
			draw_outline_text(string(_bounty.condition.gold_reward), c_black, c_white, 2, details_x + 285, details_y + 35, 1, 1, 0);
		
			// Draw condition information
			var condition_row_y = 150;
			var condition_icon_x = details_x + sprite_get_width(_bounty.condition.icon)/2*_bounty.condition.scale;
			var condition_icon_y = details_y + condition_row_y;
			draw_sprite_ext(_bounty.condition.icon, _bounty.condition.index, condition_icon_x, condition_icon_y, _bounty.condition.scale, _bounty.condition.scale, 0, _bounty.condition.color, 1.0);
			draw_sprite_ext(sCrossMark, 0, condition_icon_x, condition_icon_y - 5, 1.3, 1.3, 0, c_white, 1.0);
			draw_set_halign(fa_center);
			draw_set_valign(fa_middle);
			draw_set_font(ftBigger);
			draw_outline_text(_bounty.condition.text, c_black, c_white, 2, condition_icon_x, condition_icon_y, 1, 1, 0);
		
			// Draw condition description
			draw_set_font(ftDefault);
			draw_set_color(c_black);
			draw_set_halign(fa_left);
			draw_set_valign(fa_top);
			draw_text_ext(details_x + 100, condition_icon_y - sprite_get_height(_bounty.condition.icon)/2*_bounty.condition.scale + 10, "Defeat " + string(_bounty.enemy_name) + " " +_bounty.condition.description, font_get_size( draw_get_font() ) * 1.2, 235);
		
			// Draw reward info
			draw_text_ext(details_x, condition_icon_y + 72, "Then get offered these rewards:", font_get_size( draw_get_font() ) * 1.2, 400);
		
			// Draw rewards
			for (var r = 0; r < array_length(_bounty.rewards); r++) {
				var reward_x = details_x + sprite_get_width(sFrameSmall)/2 + (r * 112);
				var reward_y = condition_icon_y + 167;
			
				var is_item = false;
				var is_keepsake = false;
				var is_dice = false;
			
				if (variable_struct_exists(_bounty.rewards[r], "type")) {
					is_item = true;
				}
			
				if (variable_struct_exists(_bounty.rewards[r], "dice_amount")) {
					is_dice = true;
				}
			
				if (variable_struct_exists(_bounty.rewards[r], "desc")) {
					is_keepsake = true;
				}
			
				var angle = 0;
				var col = c_white;
				var index = 0;
				var sprite = undefined;
			
				if (is_item) {
					angle = _bounty.rewards[r].type == "consumable" ? -45 : 0;
					index = _bounty.rewards[r].index;
					sprite = _bounty.rewards[r].sprite;
				}
			
				if (is_keepsake) {
					index = _bounty.rewards[r].sub_image;
					sprite = sKeepsake;
				}
			
				if (is_dice) {
					index = get_dice_index(_bounty.rewards[r].dice_value);
					sprite = sDice;
					col = get_dice_color(_bounty.rewards[r].possible_type);
				}
			
				var frame_col = make_colour_rgb(52, 55, 73);
			
				if (is_dice || is_item) {
					switch (_bounty.rewards[r].rarity) {
						case "uncommon":
						frame_col = make_colour_rgb(42, 90, 85);
						break;
					
						case "rare":
						frame_col = make_colour_rgb(85, 42, 90);
						break;
					}
				}
				
				draw_sprite_ext(sFrameSmall, 0, reward_x, reward_y, _bounty.rewards_scale[r], _bounty.rewards_scale[r], 0, frame_col, 1.0);
				if (is_dice) draw_die(reward_x, reward_y, 30 * _bounty.rewards_scale[r], _bounty.rewards[r].dice_value, -1, die_colours(_bounty.rewards[r].possible_type), 0, 1); // drawn in code: split if multitype
				else draw_sprite_ext(sprite, index, reward_x, reward_y, _bounty.rewards_scale[r], _bounty.rewards_scale[r], angle, col, 1.0);
			
				var reward_hover = mouse_hovering( reward_x, reward_y, sprite_get_width(sFrameSmall), sprite_get_height(sFrameSmall), true);
			
				_bounty.rewards_scale[r] = lerp(_bounty.rewards_scale[r], reward_hover ? 1.2 : 1.0, 0.2);
			
				if (reward_hover) {
					var die = undefined;
					if (variable_struct_exists(_bounty.rewards[r], "distribution")) {
						if (string_pos("Core", _bounty.rewards[r].name) > 0) {
							die = core_preview_die();
							die.distribution = _bounty.rewards[r].distribution;
						}
					}
					var _desc = "";
					if (variable_struct_exists(_bounty.rewards[r], "description")) {
						_desc = _bounty.rewards[r].description;
					} else if (variable_struct_exists(_bounty.rewards[r], "desc")) {
						_desc = _bounty.rewards[r].desc;
					}
				
					queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), _bounty.rewards[r].name, _desc, undefined, 0, die);
				}
			}
		
		// Check for hovering
		var bounty_hover = mouse_hovering(bounty_x, bounty_y, sprite_get_width(sBountyContract) - 40, sprite_get_height(sBountyContract) + bounty_offset[b]*2, true);
	
		// Change scale based on hovering
		bounty_scale[b] = lerp(bounty_scale[b], bounty_hover ? 1.0 : 1.0, 0.2);
		bounty_offset[b] = lerp(bounty_offset[b], bounty_hover ? 50 : 0, 0.2);
	
		// Set active bounty
		if (bounty_hover) {
			if (mouse_check_button_pressed(mb_left)) {
				oRunManager.active_bounty = _bounty;
				show_debug_message("Active bounty set to: " + string(oRunManager.active_bounty));
				bounty_selected = b;
			}
		}
	}

	// Draw reroll button
	var price = 10;

	var hover_reroll = mouse_hovering(gui_w/2 + 230, gui_h - 250, reroll_scale*sprite_get_width(sButtonSmall) * 0.75, reroll_scale*sprite_get_height(sButtonSmall) * 0.75, true);

	if (hover_reroll && reroll_col == global.color_block) {
		queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Re-roll options", "Spend " + string(price) + " gold to reroll options");
	
		if (mouse_check_button_pressed(mb_left)) {
			if (oRunManager.credits >= price) {
				oRunManager.credits -= price;
				bounty_selected = -1;
				oRunManager.active_bounty = undefined; // the contract you had picked is no longer on the board
				generate_bounties(2);
				reroll_col = c_dkgray;
			} else {
				throw_error("Not enough money", "10 gold is needed to reroll");
			}
		}
		reroll_scale = lerp(reroll_scale, 1.2, 0.2);
	} else {
		reroll_scale = lerp(reroll_scale, 1.0, 0.2);
	}

	draw_set_font(ftBigger);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_sprite_ext(sButtonSmall, 0, gui_w/2 + 230, gui_h - 250, reroll_scale * 1.3, reroll_scale * 0.9, 0, (reroll_col == global.color_block) ? global.ui_neutral : reroll_col, 1.0); // blue is for block: an available re-roll is drawn neutral
	var string_w = string_width("Re-roll");
	var coin_w = sprite_get_width(sCoin) * 0.75;

	var coin_offset = string_w/2 + coin_w/2 + 10; // 10 is padding
	var total_offset = coin_offset / 4;

	draw_sprite_ext(sCoin, 0, gui_w/2 + 230 - coin_offset * reroll_scale + total_offset, gui_h - 249, 0.75 * reroll_scale, 0.75 * reroll_scale, 0, c_white, 1.0);
	draw_outline_text("Re-roll", c_black, c_white, 2, gui_w/2 + 230 + total_offset, gui_h - 250, reroll_scale, 1, 0); // grows with the button

	// Draw exit button
	var exit_col = c_red;
	var button_text = "Exit";
	var button_scale = 0.75;
	if (oRunManager.active_bounty != undefined) {
		exit_col = c_lime;
		button_text = "Confirm";
		button_scale = 1.0;
	}

	var exit_btn = ui_button(gui_w - 150, gui_h - 200, 200, 70, exit_scale, button_text, ui_button_col(exit_col), true);
	exit_scale = exit_btn.scale;
	if (exit_btn.click) room_goto(rmMap);

}