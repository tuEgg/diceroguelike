var consumable_pos = { x: 150, y: 665 };
var dice_pos = { x: 735, y: 595 };
var keepsake_pos = { x: 460, y: 935 };

var cx = consumable_pos.x;
var cy = consumable_pos.y;

var dx = dice_pos.x;
var dy = dice_pos.y;

var kx = keepsake_pos.x;
var ky = keepsake_pos.y;

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
			die = clone_die(global.dice_d6_atk, "");
			die.distribution = consumable.distribution;
		}
		queue_tooltip(mouse_x, mouse_y, consumable.name, consumable.description, undefined, 0, die);
		
		if (mouse_check_button_pressed(mb_left) && !consumable.taken && oRunManager.credits >= consumable.price && oRunManager.has_space_for_item) {
			oRunManager.credits -= consumable.price;
			gain_item(consumable);
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
		draw_sprite_ext(sDice, get_dice_index(dice.dice_value), dx, dy, shop_dice_scale[| d], shop_dice_scale[| d], 0, get_dice_color(dice.action_type), 1.0);
		draw_dice_keywords(dice, dx, dy, shop_dice_scale[| d], 1.0);
	
		// Draw cost
		draw_sprite_ext(sCoin, 0, dx + coin_offset_x, dy + coin_offset_y, shop_dice_scale[| d] * coin_scale, shop_dice_scale[| d] * coin_scale, 0, c_white, 1.0);
		draw_set_halign(fa_left);
		draw_set_valign(fa_middle);
		draw_set_font(ftBig);
		var cost_col = dice.price > oRunManager.credits ? c_red : c_white;
		draw_outline_text(dice.price, c_black, cost_col, 2, dx, dy + coin_offset_y, shop_dice_scale[| d], 1.0, 0);
	
		if (hover_die) {
			queue_tooltip(mouse_x, mouse_y, dice.name, dice.description, undefined, 0, dice);
		
			if (mouse_check_button_pressed(mb_left) && oRunManager.credits >= dice.price) {
				oRunManager.credits -= dice.price;
				
				var p = instance_create_layer(dx, dy, "Instances", oDiceParticle);
				p.target_x = GUI_LAYOUT.PLAY_W;
				p.target_y = display_get_gui_height() - GUI_LAYOUT.PLAY_H / 2;
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
			queue_tooltip(mouse_x, mouse_y, keepsake.name, keepsake.desc);
		
			if (mouse_check_button_pressed(mb_left) && oRunManager.credits >= keepsake.price) {
				oRunManager.credits -= keepsake.price;
				
				gain_keepsake(keepsake);
				
				shop_keepsake_options[| k] = undefined;
			}
		}
	}
	
	kx += 130;
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
