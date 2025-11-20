/// @description Insert description here
// You can write your code in this editor
if (!oCombat.show_rewards) {
	draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, image_blend, 1.0);
	draw_dice_keywords(die_struct, x, y, 1);
}