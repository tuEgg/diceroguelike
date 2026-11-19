draw_set_alpha(1);
draw_set_color(c_white);

image_blend = get_dice_color(struct.possible_type);

// the die is drawn in code (draw_die): its shape by size, real pips in fights (tumbling as it's dealt), its size
// ("d6") elsewhere, a multitype die split in its colours. The sprite only if it somehow has no struct.
var _coded = is_struct(struct);
var _die_r = 36 * scale * (1 + 0.22 * land_pop);
if (_coded) {
	var _face = tumbling ? flick_face : (die_has_faces(struct) ? die_face_total(struct) : -1);
	var _wobble = over_discard ? sin(current_time / 70) * 9 : 0;
	var _cols = die_colours(struct.possible_type); // a multitype die is split diagonally in its colours
	draw_die(x, y, _die_r, dice_value, _face, over_discard ? colours_merge(_cols, c_black, 0.25) : _cols, tumble_angle + _wobble, image_alpha);
	// over the discard pile: letting go discards it (redraws are bought in the insight phase)
	if (over_discard && instance_exists(oCombat)) {
		var _can = true;
		draw_set_font(ftDefault);
		draw_set_halign(fa_center);
		draw_set_valign(fa_bottom); // wraps upwards from just above the keyword icons
		// short, wrapped to 220px, and kept on screen (the discard pile is at the right edge)
		var _msg = "Discard";
		var _mx = clamp(x, 120, display_get_gui_width() - 120);
		draw_outline_text(_msg, c_black, c_white, 2, _mx, y - _die_r - 24, 1, 1, 0, 220);
		draw_set_valign(fa_middle);
	}
} else {
	draw_sprite_ext(sprite_index, image_index, x, y, scale, scale, image_angle, image_blend, image_alpha);
}

draw_set_font(ftDefault);
draw_set_halign(fa_center);
draw_set_valign(fa_top);
// the name under a die: not in fights (seven names cluttered the hand; the tooltip's title has it)
if (struct.rarity != "starter" && room != rmCombat) {
	// in a workbench slot the name sits a little higher, clear of the slot's edge
	var _name_y = y + sprite_height/2 + 3 - ((room == rmWorkbench && in_slot) ? 12 : 0);
	// hidden while hovered: the tooltip's title has the name
	if (!mouse_hovering(x, y, sprite_width, sprite_height, true)) draw_outline_text(struct.name, c_black, c_white, 2, x, _name_y, scale, image_alpha, 0);
}

// --- Draw effect keyword icons ---
// a coded die has pips in the middle, so its keyword icons sit small just above it
// keyword icons only on dice you're about to play (a fight); elsewhere the tooltip's words say it
var _kw_icons = [];
if (_coded && room == rmCombat) _kw_icons = draw_dice_keywords(struct, x, y + die_bottom_edge(dice_value, _die_r), 1.15 * scale, 1, "hand"); // big, centred on its bottom edge
// hovering a keyword's icon explains the keyword (the die's own tip leaves it out)
var _kw_hover = false;
if (global.ui_layer == UI_LAYER.BASE && !is_dragging) {
	var _kmx = device_mouse_x_to_gui(0), _kmy = device_mouse_y_to_gui(0);
	for (var k = 0; k < array_length(_kw_icons); k++) {
		var _ic = _kw_icons[k];
		if (point_distance(_kmx, _kmy, _ic.x, _ic.y) <= _ic.r + 2) {
			_kw_hover = true;
			queue_tooltip(_kmx, _kmy, _ic.key, global.keywords[$ _ic.key].desc);
		}
	}
}
// Mocked: its attack can't roll above 1 while Mock lasts (B133); a red tag on its top edge, explained on hover
if (_coded && die_is_mocked(struct) && !tumbling) {
	var _mk = draw_mock_mark(x, y - _die_r - 6, scale);
	var _mmx = device_mouse_x_to_gui(0), _mmy = device_mouse_y_to_gui(0);
	if (global.ui_layer <= UI_LAYER.POPUP && !is_dragging && point_in_rectangle(_mmx, _mmy, _mk.x1, _mk.y1, _mk.x2, _mk.y2)) {
		_kw_hover = true;
		queue_tooltip(_mmx, _mmy, "Mocked", "While Mock lasts, this die's attack can't roll higher than 1. Rerolling it won't help.");
	}
}
// Settings > Display > Action icons on dice: a small symbol so types don't rely on colour alone
if (global.action_icons) draw_action_type_icon(struct.action_type, x - sprite_width * 0.32, y + sprite_height * 0.32, scale);

if (debug_mode) {
    draw_set_color(c_black);
	draw_set_font(ftDefault);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_alpha(1.0);
}

if (!_kw_hover && mouse_hovering(x, y, sprite_width, sprite_height, true)) {
	var dice_output = get_dice_output(struct, -1, -1, true, "player"); // read only: hovering must never trigger keepsakes
	// the range sits in the tooltip's title ("Inkwell Die (1-4)"), not on the die where it could cover a keyword icon
	// rolled dice: the title says what it rolled, and the body how to reroll it
	var _rolled = (room == rmCombat && die_has_faces(struct) && !tumbling);
	var _title = string(struct.name) + (_rolled ? ": rolled " + string(die_face_total(struct)) : "") + " (" + string(dice_output.min_roll) + "-" + string(dice_output.max_roll) + ")";
	// the compact tip (queue_die_tip): above the die, never over the hand; the name, what it rolled (or its range), a
	// mini chart of its core, and its effect. Keywords are explained on their icons.
	var _sub = _rolled ? "rolled " + string(die_face_total(struct)) : string(dice_output.min_roll) + "-" + string(dice_output.max_roll);
	var _r_now = (_coded ? 36 * scale : sprite_height / 2);
	// in an event, a click sends it to the bag (F149, oDice Step); not while the plank waits for one
	var _ev_hint = (room == rmEvent && !(instance_exists(oEventManager) && oEventManager.deleting_die == 1)) ? "Click to put it in your bag." : "";
	queue_die_tip(struct, x, y - _r_now * 1.25, undefined, _ev_hint);
	
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