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
draw_outline_text("Choose a boss to encounter later in the run. Accept a special bounty condition for the fight and receive greater rewards.",
	c_black, c_white, 2, 50, 370, 1, 1, 0, 400);
	

draw_set_font(ftBigger);

// Offer the player a potion
draw_outline_text("Grab a drink", c_black, c_white, 2, 125, 635, 1, 1, 0);

var pot_x = 75;
var pot_y = 650;

var pot = potion;

var potion_w = potion_scale * sprite_get_width(pot.sprite);
var potion_h =  potion_scale * sprite_get_height(pot.sprite);
	
var hover_con = mouse_hovering(pot_x, pot_y, potion_w, potion_h, true);
potion_scale = lerp(potion_scale, !pot.taken && hover_con ? 1.2 : 1.0, 0.2);
	
var alpha = pot.taken ? 0 : 1.0;
	
draw_set_alpha(0.4 * alpha);
draw_set_color(c_black);
draw_ellipse(pot_x - sprite_get_width(pot.sprite)/2, pot_y + sprite_get_height(pot.sprite)/2 - 7, pot_x + sprite_get_width(pot.sprite)/2, pot_y + sprite_get_height(pot.sprite)/2 + 7, false);
draw_sprite_ext(pot.sprite, pot.index, pot_x, pot_y, potion_scale, potion_scale, 0, c_white, alpha);
draw_set_alpha(1.0);

if (hover_con && alpha > 0) {
	var die = undefined;
	if (string_pos("Core", pot.name) > 0) {
		die = clone_die(global.dice_d6_atk, "");
		die.distribution = pot.distribution;
	}
	queue_tooltip(mouse_x, mouse_y, pot.name, pot.description, undefined, 0, die);
		
	if (mouse_check_button_pressed(mb_left) && !pot.taken && oRunManager.credits >= pot.price && oRunManager.has_space_for_item) {
		oRunManager.credits -= pot.price;
		gain_item(pot);
	}
}
	
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
			draw_sprite_ext(sprite, index, reward_x, reward_y, _bounty.rewards_scale[r], _bounty.rewards_scale[r], angle, col, 1.0);
			
			var reward_hover = mouse_hovering( reward_x, reward_y, sprite_get_width(sFrameSmall), sprite_get_height(sFrameSmall), true);
			
			_bounty.rewards_scale[r] = lerp(_bounty.rewards_scale[r], reward_hover ? 1.2 : 1.0, 0.2);
			
			if (reward_hover) {
				var die = undefined;
				if (variable_struct_exists(_bounty.rewards[r], "distribution")) {
					if (string_pos("Core", _bounty.rewards[r].name) > 0) {
						die = clone_die(global.dice_d6_atk, "");
						die.distribution = _bounty.rewards[r].distribution;
					}
				}
				var _desc = "";
				if (variable_struct_exists(_bounty.rewards[r], "description")) {
					_desc = _bounty.rewards[r].description;
				} else if (variable_struct_exists(_bounty.rewards[r], "desc")) {
					_desc = _bounty.rewards[r].desc;
				}
				
				queue_tooltip(mouse_x, mouse_y, _bounty.rewards[r].name, _desc, undefined, 0, die);
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
	queue_tooltip(mouse_x, mouse_y, "Re-roll options", "Spend " + string(price) + " gold to reroll options");
	
	if (mouse_check_button_pressed(mb_left)) {
		if (oRunManager.credits >= price) {
			oRunManager.credits -= price;
			bounty_selected = -1;
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
draw_sprite_ext(sButtonSmall, 0, gui_w/2 + 230, gui_h - 250, reroll_scale * 1.3, reroll_scale * 0.9, 0, reroll_col, 1.0);
var string_w = string_width("Re-roll");
var coin_w = sprite_get_width(sCoin) * 0.75;

var coin_offset = string_w/2 + coin_w/2 + 10; // 10 is padding
var total_offset = coin_offset / 4;

draw_sprite_ext(sCoin, 0, gui_w/2 + 230 - coin_offset + total_offset, gui_h - 249, 0.75, 0.75, 0, c_white, 1.0);
draw_outline_text("Re-roll", c_black, c_white, 2, gui_w/2 + 230 + total_offset, gui_h - 250, 1, 1, 0);

// Draw exit button
var exit_col = c_red;
var button_text = "Exit";
var button_scale = 0.75;
if (oRunManager.active_bounty != undefined) {
	exit_col = c_lime;
	button_text = "Confirm";
	button_scale = 1.0;
}

var hover_exit = mouse_hovering(gui_w - 150, gui_h - 200, exit_scale*sprite_get_width(sButtonSmall) * button_scale, exit_scale*sprite_get_height(sButtonSmall) * 0.75, true);

if (hover_exit) {
	if (mouse_check_button_pressed(mb_left)) {
		room_goto(rmMap);
	}
	exit_scale = lerp(exit_scale, 1.2, 0.2);
} else {
	exit_scale = lerp(exit_scale, 1.0, 0.2);
}

draw_set_font(ftBigger);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_sprite_ext(sButtonSmall, 0, gui_w - 150, gui_h - 200, exit_scale * button_scale, exit_scale * 0.75, 0, exit_col, 1.0);
draw_outline_text(button_text, c_black, c_white, 2, gui_w - 150, gui_h - 200, 1, 1, 0);