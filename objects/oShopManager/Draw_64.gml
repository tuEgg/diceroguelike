var consumable_pos = { x: 80, y: 715 };
var dice_pos = { x: 735, y: 595 };
var keepsake_pos = { x: 460, y: 935 };
var tool_pos = { x: 1300, y: 1000 };

var cx = consumable_pos.x;
var cy = consumable_pos.y;

var dx = dice_pos.x;
var dy = dice_pos.y;

var kx = keepsake_pos.x;
var ky = keepsake_pos.y;

var tx = tool_pos.x;
var ty = tool_pos.y;

var coin_offset_x = -20;
var coin_offset_y = -60;
var coin_scale = 0.5;

for (var c = 0; c < ds_list_size(shop_consumable_options); c++) {
	var consumable = shop_consumable_options[| c];
	var width = shop_consumable_scale[| c] * sprite_get_width(consumable.sprite);
	var height =  shop_consumable_scale[| c] * sprite_get_height(consumable.sprite);
	
	var hover_con = mouse_hovering(cx, cy, width, height, true);
	shop_consumable_scale[| c] = lerp(shop_consumable_scale[| c], !consumable.taken && hover_con ? 1.2 : 1.0, 0.2);
	
	var alpha = consumable.taken ? 0 : 1.0;
	
	draw_set_alpha(0.4 * alpha);
	draw_set_color(c_black);
	draw_ellipse(cx - sprite_get_width(consumable.sprite)/2, cy + sprite_get_height(consumable.sprite)/2 - 7, cx + sprite_get_width(consumable.sprite)/2, cy + sprite_get_height(consumable.sprite)/2 + 7, false);
	draw_sprite_ext(consumable.sprite, consumable.index, cx, cy, shop_consumable_scale[| c], shop_consumable_scale[| c], 0, c_white, alpha);
	draw_set_alpha(1.0);
	
	// Draw cost
	if (!consumable.taken) {
		draw_sprite_ext(sCoin, 0, cx + coin_offset_x, cy + coin_offset_y, shop_consumable_scale[| c] * coin_scale, shop_consumable_scale[| c] * coin_scale, 0, c_white, 1.0);
		draw_set_halign(fa_left);
		draw_set_valign(fa_middle);
		draw_set_font(ftBig);
		var cost_col = consumable.price > oRunManager.credits ? c_red : c_white;
		draw_outline_text(consumable.price, c_black, cost_col, 2, cx, cy + coin_offset_y, shop_consumable_scale[| c], 1.0, 0);
	}
	
	if (hover_con && alpha > 0) {
		var die = undefined;
		if (string_pos("Core", consumable.name) > 0) {
			die = core_preview_die();
			die.distribution = consumable.distribution;
		}
		queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), consumable.name, consumable.description, undefined, 0, die, consumable.taken ? 0 : consumable.price, "gold");
		
		if (mouse_check_button_pressed(mb_left) && !consumable.taken) {
			// say why a purchase can't happen, rather than doing nothing
			if (get_first_free_item_slot() == -1) {
				throw_error("Item slots full", "Use an item, or right click one to drop it.");
			} else if (oRunManager.credits < consumable.price) {
				throw_error("Not enough gold", "You need " + string(consumable.price - oRunManager.credits) + " more gold.");
			} else {
				oRunManager.credits -= consumable.price;
				gain_item(consumable);
			}
		}
	}
	
	cx += 75;
	cy -= 55;
}

for (var d = 0; d < ds_list_size(shop_dice_options); d++) {
	var dice = shop_dice_options[| d];
	var width = shop_dice_scale[| d] * sprite_get_width(sDice);
	var height =  shop_dice_scale[| d] * sprite_get_height(sDice);
	
	if (dice != undefined) {
		var hover_die = mouse_hovering(dx, dy, width, height, true);
		shop_dice_scale[| d] = lerp(shop_dice_scale[| d], hover_die ? 1.2 : 1.0, 0.2);
	
		draw_set_alpha(0.4);
		draw_set_color(c_black);
		draw_ellipse(dx - sprite_get_width(sDice)/2, dy + sprite_get_height(sDice)/2 - 15, dx + sprite_get_width(sDice)/2, dy + sprite_get_height(sDice)/2 - 3, false);
		draw_die(dx, dy, 36 * shop_dice_scale[| d], dice.dice_value, -1, die_colours(dice.possible_type), 0, 1, dice); // drawn in code: split if multitype

		// Draw cost
		draw_sprite_ext(sCoin, 0, dx + coin_offset_x, dy + coin_offset_y, shop_dice_scale[| d] * coin_scale, shop_dice_scale[| d] * coin_scale, 0, c_white, 1.0);
		draw_set_halign(fa_left);
		draw_set_valign(fa_middle);
		draw_set_font(ftBig);
		var cost_col = dice.price > oRunManager.credits ? c_red : c_white;
		draw_outline_text(dice.price, c_black, cost_col, 2, dx, dy + coin_offset_y, shop_dice_scale[| d], 1.0, 0);
	
		if (hover_die) {
			queue_die_tip(dice, dx, dy - 40 * shop_dice_scale[| d], undefined, "", dice.price, "gold");
		
			if (mouse_check_button_pressed(mb_left) && oRunManager.credits < dice.price) throw_error("Not enough gold", "You need " + string(dice.price - oRunManager.credits) + " more gold.");
			if (mouse_check_button_pressed(mb_left) && oRunManager.credits >= dice.price) {
				oRunManager.credits -= dice.price;
				
				var p = instance_create_layer(dx, dy, "Instances", oDiceParticle);
				p.target_x = global.gui.play_w;
				p.target_y = display_get_gui_height() - global.gui.play_h / 2;
				p.color_main = dice.color;
				p.die_struct = clone_die(dice, "");
				
				shop_dice_options[| d] = undefined;
			}
		}
	}
	
	dx += 140 + (d == 1 ? 260 : 0);
	dy += 5;
}

for (var k = 0; k < ds_list_size(shop_keepsake_options); k++) {
	var keepsake = shop_keepsake_options[| k];
	var width = shop_keepsake_scale[| k] * sprite_get_width(sKeepsake);
	var height =  shop_keepsake_scale[| k] * sprite_get_height(sKeepsake);
	
	if (keepsake != undefined) {
		var hover_die = mouse_hovering(kx, ky, width, height, true);
		shop_keepsake_scale[| k] = lerp(shop_keepsake_scale[| k], hover_die ? 1.2 : 1.0, 0.2);
	
		draw_set_alpha(0.4);
		draw_set_color(c_black);
		draw_ellipse(kx - sprite_get_width(sKeepsake)/2, ky + sprite_get_height(sKeepsake)/2 - 15, kx + sprite_get_width(sKeepsake)/2, ky + sprite_get_height(sKeepsake)/2 - 3, false);
		draw_sprite_ext(sKeepsake, keepsake.sub_image, kx, ky, shop_keepsake_scale[| k], shop_keepsake_scale[| k], 0, c_white, 1.0);
	
		// Draw cost
		draw_sprite_ext(sCoin, 0, kx + coin_offset_x, ky + coin_offset_y, shop_keepsake_scale[| k] * coin_scale, shop_keepsake_scale[| k] * coin_scale, 0, c_white, 1.0);
		draw_set_halign(fa_left);
		draw_set_valign(fa_middle);
		draw_set_font(ftBig);
		var cost_col = keepsake.price > oRunManager.credits ? c_red : c_white;
		draw_outline_text(keepsake.price, c_black, cost_col, 2, kx, ky + coin_offset_y, shop_keepsake_scale[| k], 1.0, 0);
	
		if (hover_die) {
			queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), keepsake.name, keepsake.desc, undefined, 0, undefined, keepsake.price, "gold");
		
			if (mouse_check_button_pressed(mb_left) && oRunManager.credits < keepsake.price) throw_error("Not enough gold", "You need " + string(keepsake.price - oRunManager.credits) + " more gold.");
			if (mouse_check_button_pressed(mb_left) && oRunManager.credits >= keepsake.price) {
				oRunManager.credits -= keepsake.price;
				
				gain_keepsake(keepsake, global.shop_keepsake_list);
				
				shop_keepsake_options[| k] = undefined;
			}
		}
	}
	
	kx += 130;
}

if (ds_list_size(oRunManager.tools) < 4) {
	var _tn = ds_list_size(shop_tool_options);
	for (var t = 0; t < _tn; t++) {
		var tool = shop_tool_options[| t];
		// side by side (2026-11-24: every tool you don't own is on sale), smaller than before
		tx = tool_pos.x - (_tn - 1) * 75 + t * 150;
		ty = tool_pos.y - 60;
		var width = shop_tool_scale[| t] * 110;
		var height =  shop_tool_scale[| t] * 190;
		var _price = tool_price();
	
		if (tool != undefined) {
			var hover_tool = mouse_hovering(tx, ty + 20, width, height, true);
			shop_tool_scale[| t] = lerp(shop_tool_scale[| t], hover_tool ? 1.2 : 1.0, 0.2);

			// the tool stands on its shadow (2026-11-24: it floated well above it): drawn from the sprite's own origin so its
			// foot lands on the shadow, whichever way each sprite is anchored
			var _sc = shop_tool_scale[| t] * 0.28, _shadow_y = ty + 92;
			draw_set_alpha(0.4);
			draw_set_color(c_black);
			draw_ellipse(tx - 55, ty + 85, tx + 55, ty + 100, false);
			draw_set_alpha(1);
			if (tool.sprite >= 0) {
				var _spr_w = sprite_get_width(tool.sprite), _spr_h = sprite_get_height(tool.sprite);
				draw_sprite_ext(tool.sprite, 0, tx - (_spr_w / 2 - sprite_get_xoffset(tool.sprite)) * _sc, _shadow_y - (_spr_h - sprite_get_yoffset(tool.sprite)) * _sc, _sc, _sc, 0, c_white, 1.0);
			} else {
				var _bs = shop_tool_scale[| t] * 0.8;
				draw_bin_icon(tx, _shadow_y - 46 * _bs, _bs, 1); // the Bin, drawn in code; its foot is 46 below its centre
			}

			// the price under the shadow: the coin and its number side by side, centred
			draw_set_font(ftBig);
			var _ps = string(_price);
			var _cs = 0.6 * shop_tool_scale[| t];
			var _coin_w = sprite_get_width(sCoin) * _cs;
			var _row_w = _coin_w + 8 + string_width(_ps) * shop_tool_scale[| t];
			var _row_x = tx - _row_w / 2, _row_y = _shadow_y + 44;
			draw_sprite_ext(sCoin, 0, _row_x + _coin_w / 2, _row_y, _cs, _cs, 0, c_white, 1.0);
			draw_set_halign(fa_left);
			draw_set_valign(fa_middle);
			var cost_col = _price > oRunManager.credits ? c_red : c_white;
			draw_outline_text(_ps, c_black, cost_col, 2, _row_x + _coin_w + 8, _row_y, shop_tool_scale[| t], 1.0, 0);
	
			if (hover_tool) {
				queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), tool.name, tool.desc, undefined, 0, undefined, _price, "gold");
		
				if (mouse_check_button_pressed(mb_left) && oRunManager.credits < _price) throw_error("Not enough gold", "You need " + string(_price - oRunManager.credits) + " more gold.");
				if (mouse_check_button_pressed(mb_left) && oRunManager.credits >= _price) {
					oRunManager.credits -= _price;
					oRunManager.tools_bought++; // the next one costs 50 more (tool_price)
				
					ds_list_add(oRunManager.tools, tool);
					ds_list_add(oRunManager.tools_scale, 0.5);
				
					shop_tool_options[| t] = undefined;
				
					oRunManager.show_tools = true;
						
					var tool_index = ds_list_find_index(global.master_tool_list, tool);
					show_debug_message("tool index: " + string(tool_index));
				
					ds_list_delete(global.master_tool_list, tool_index);
					show_debug_message(ds_list_size(global.master_tool_list));
				}
			}
		}
	
		kx += 130;
	}
}

// Draw exit 1761 622
var hover_exit = mouse_hovering( 1766, 622, sprite_get_width(sShopExit), sprite_get_height(sShopExit), true);
draw_sprite_ext(sShopExit, 0, 1766, 622, exit_scale, exit_scale, 0, c_white, 1.0);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_font(ftBig);
draw_outline_text("Back\nto sea", c_black, c_white, 2, 1766, 700, exit_scale, 1.0, 0);

exit_scale = lerp(exit_scale, hover_exit ? 1.2 : 1.0, 0.2);

if (hover_exit) {
	if (mouse_check_button_pressed(mb_left) && !instance_exists(oDiceParticle)) {
		room_goto(rmMap);
	}
}
