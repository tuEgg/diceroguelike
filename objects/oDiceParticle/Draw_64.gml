if (room == rmCombat) {
	if (oCombat.show_rewards) {
		depth = -10;
		draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, 1.0);
		draw_dice_keywords(die_struct, x, y, 1);
	}
}

if (room == rmWorkbench) {
	depth = -13;
	draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, 1.0);
	draw_dice_keywords(die_struct, x, y, 1);
}