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
	queue_tooltip(mouse_x, mouse_y, string(struct.name), string(struct.description), undefined, 0, struct);
	
	if (debug_mode) && (keyboard_check(vk_alt)) {
		var xx = 0;
		for (var i = 0; i < ds_list_size(struct.statistics.roll_history); i++) {
			xx = i * 20;
			draw_set_font(ftDefault);
			draw_outline_text(string(struct.statistics.roll_history[| i]), c_black, c_white, 2, x + xx, y - 100, 1, 1.0, 0);
		}
	}
}