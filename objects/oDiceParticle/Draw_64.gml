if (room == rmCombat) {
	if (oCombat.show_rewards) {
		draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, 1.0);
		draw_dice_keywords(die_struct, x, y, 1);
	}
} else {
	draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, 1.0);
	draw_dice_keywords(die_struct, x, y, 1);
}