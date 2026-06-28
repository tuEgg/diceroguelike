draw_set_alpha(1);
draw_set_color(c_white);

image_blend = get_dice_color(struct.possible_type);

draw_sprite_ext(
    sprite_index,
    image_index,
    x,
    y,
    scale,
    scale,
    image_angle,
    image_blend,
    image_alpha
);

draw_set_font(ftDefault);
draw_set_halign(fa_center);
draw_set_valign(fa_top);
if (struct.rarity != "starter") {
	draw_outline_text(struct.name, c_black, c_white, 2, x, y + sprite_height/2 + 3, scale, image_alpha, 0);
}

// --- Draw effect keyword icons ---
draw_dice_keywords(struct, x, y, 1);

if (debug_mode) {
    draw_set_color(c_black);
	draw_set_font(ftDefault);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_alpha(1.0);
}

if mouse_hovering(x, y, sprite_width, sprite_height, true) {
	queue_tooltip(x - sprite_width/2, y + sprite_height/2, string(struct.name), string(struct.description), undefined, 0, struct);
	
	var dice_output = get_dice_output(struct, -1, -1, false, "player");
	
	var off_x = 0;
	var off_y = 0;
	
	switch (image_index) {
		case 1:
		off_x = -2;
		off_y = 3;
		break;
		case 2:
		off_x = -2;
		off_y = 1;
		break;
		case 3:
		case 4:
		case 5:
		off_x = 0;
		off_y = -1;
		break;
	}
			
	var _min_roll = dice_output.min_roll;			
	var _max_roll = dice_output.max_roll;
	
	draw_set_font(ftSmall);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_outline_text(string(_min_roll) + "-" + string(_max_roll), c_black, c_white, 2, x + off_x, y + off_y, scale, scale, 0, -1);
	
	//if (debug_mode) && (keyboard_check(vk_alt)) {
	//	var xx = 0;
	//	for (var i = 0; i < ds_list_size(struct.statistics.roll_history); i++) {
	//		xx = i * 20;
	//		draw_set_font(ftDefault);
	//		draw_outline_text(string(struct.statistics.roll_history[| i]), c_black, c_white, 2, x + xx, y - 100, 1, 1.0, 0);
	//	}
	//}
}