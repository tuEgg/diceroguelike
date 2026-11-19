draw_set_alpha(1);
draw_set_color(c_white);

image_blend = get_dice_color(struct.possible_type);

// in fights the die is drawn in code (draw_die): its shape by size, real pips, tumbling as it's dealt. Elsewhere the sprite.
var _coded = (room == rmCombat && is_struct(struct));
var _die_r = 36 * scale * (1 + 0.22 * land_pop);
if (_coded) {
	var _face = tumbling ? flick_face : (die_has_faces(struct) ? die_face_total(struct) : -1);
	draw_die(x, y, _die_r, dice_value, _face, image_blend, tumble_angle, image_alpha);
} else {
	draw_sprite_ext(sprite_index, image_index, x, y, scale, scale, image_angle, image_blend, image_alpha);
}

draw_set_font(ftDefault);
draw_set_halign(fa_center);
draw_set_valign(fa_top);
if (struct.rarity != "starter") {
	// in a workbench slot the name sits a little higher, clear of the slot's edge
	var _name_y = y + sprite_height/2 + 3 - ((room == rmWorkbench && in_slot) ? 12 : 0);
	// hidden while hovered: the tooltip's title has the name
	if (!mouse_hovering(x, y, sprite_width, sprite_height, true)) draw_outline_text(struct.name, c_black, c_white, 2, x, _name_y, scale, image_alpha, 0);
}

// --- Draw effect keyword icons ---
// a coded die has pips in the middle, so its keyword icons sit small just above it
if (_coded) draw_dice_keywords(struct, x, y - _die_r - 12, 0.6);
else draw_dice_keywords(struct, x, y, 1);
// Settings > Display > Action icons on dice: a small symbol so types don't rely on colour alone
if (global.action_icons) draw_action_type_icon(struct.action_type, x - sprite_width * 0.32, y + sprite_height * 0.32, scale);

if (debug_mode) {
    draw_set_color(c_black);
	draw_set_font(ftDefault);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_alpha(1.0);
}

if mouse_hovering(x, y, sprite_width, sprite_height, true) {
	var dice_output = get_dice_output(struct, -1, -1, true, "player"); // read only: hovering must never trigger keepsakes
	// the range sits in the tooltip's title ("Inkwell Die (1-4)"), not on the die where it could cover a keyword icon
	// rolled dice: the title says what it rolled, and the body how to reroll it
	var _rolled = (room == rmCombat && die_has_faces(struct) && !tumbling);
	var _title = string(struct.name) + (_rolled ? ": rolled " + string(die_face_total(struct)) : "") + " (" + string(dice_output.min_roll) + "-" + string(dice_output.max_roll) + ")";
	var _reroll_hint = (_rolled && instance_exists(oCombat) && !oCombat.reroll_used) ? "\n\nRight-click to reroll it (once per turn)." : "";
	queue_tooltip(x - sprite_width/2, y + sprite_height/2, _title, die_description(struct) + _reroll_hint, undefined, 0, struct);
	
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
			

	
	//if (debug_mode) && (keyboard_check(vk_alt)) {
	//	var xx = 0;
	//	for (var i = 0; i < ds_list_size(struct.statistics.roll_history); i++) {
	//		xx = i * 20;
	//		draw_set_font(ftDefault);
	//		draw_outline_text(string(struct.statistics.roll_history[| i]), c_black, c_white, 2, x + xx, y - 100, 1, 1.0, 0);
	//	}
	//}
}