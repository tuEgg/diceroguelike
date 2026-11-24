// the free bench (F224): the table, the rack, the dice, the tools; input is in Step
var _mx = device_mouse_x_to_gui(0), _my = device_mouse_y_to_gui(0);
var _input = global.ui_layer == UI_LAYER.BASE && !global.show_settings && oRunManager.dice_selection == false && wb_job == undefined && !exiting;

// ---------------------------------------------------------------- the table: planks, the marks of earlier work
var _tx1 = table.x1, _ty1 = table.y1, _tx2 = table.x2, _ty2 = table.y2;
draw_set_alpha(0.35);
draw_set_color(c_black);
draw_roundrect_ext(_tx1 + 8, _ty1 + 12, _tx2 + 8, _ty2 + 12, 22, 22, false); // its shadow
draw_set_alpha(1);
var _plank_h = (_ty2 - _ty1) / 9;
for (var i = 0; i < 9; i++) {
	var _py = _ty1 + i * _plank_h;
	draw_set_color((i mod 2) ? make_color_rgb(116, 82, 52) : make_color_rgb(100, 69, 43));
	draw_rectangle(_tx1, _py, _tx2, _py + _plank_h, false);
	draw_set_color(make_color_rgb(30, 18, 10));
	draw_set_alpha(0.55);
	draw_line_width(_tx1, _py, _tx2, _py, 3);
	// the grain
	draw_set_color(make_color_rgb(255, 230, 190));
	draw_set_alpha(0.05);
	for (var g = 0; g < 4; g++) {
		var _gy = _py + 14 + g * 16;
		var _px = _tx1;
		for (var s = 1; s <= 12; s++) {
			var _nx = _tx1 + (_tx2 - _tx1) * s / 12;
			draw_line_width(_px, _gy + sin((s - 1) * 0.9 + i + g) * 3, _nx, _gy + sin(s * 0.9 + i + g) * 3, 1.5);
			_px = _nx;
		}
	}
	draw_set_alpha(1);
}
for (var i = 0; i < array_length(wb_scuffs); i++) {
	var _s = wb_scuffs[i];
	draw_set_alpha(0.2 * clamp(1 - (current_time - _s.t) / 3000, 0, 1)); // the hammer's mark, fading
	draw_set_color(make_color_rgb(25, 14, 6));
	draw_ellipse(_s.x - _s.r, _s.y - _s.r * 0.5, _s.x + _s.r, _s.y + _s.r * 0.5, false);
}
draw_set_alpha(1);
draw_set_color(make_color_rgb(42, 26, 14));
for (var k = 0; k < 5; k++) draw_roundrect_ext(_tx1 - k, _ty1 - k, _tx2 + k, _ty2 + k, 20, 20, true);
// a sheet pinned to the bench, the logbook touch
var _lx = _tx2 - 260, _ly = _ty1 + 70;
ui_paper(_lx - 170, _ly - 50, _lx + 170, _ly + 50, 7);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_font(ftBig);
draw_set_color(global.ui_col.ink);
draw_text(_lx, _ly - 14, "Shipwright's bench");
draw_set_alpha(0.6);
draw_line_width(_lx - 120, _ly + 8, _lx + 120, _ly + 8, 1.5);
draw_set_alpha(1);
draw_set_font(font_tip());
draw_text(_lx, _ly + 28, "Tools work where they land.");
draw_set_color(global.ui_col.brass);
draw_circle(_lx, _ly - 46, 6, false); // the pin

// ---------------------------------------------------------------- the rack: a pegboard
draw_set_color(make_color_rgb(59, 42, 27));
draw_roundrect_ext(rack.x1, rack.y1, rack.x2, rack.y2, 16, 16, false);
draw_set_color(make_color_rgb(32, 20, 10));
for (var k = 0; k < 4; k++) draw_roundrect_ext(rack.x1 - k, rack.y1 - k, rack.x2 + k, rack.y2 + k, 16, 16, true);
draw_set_color(c_black);
draw_set_alpha(0.35);
for (var _yy = rack.y1 + 30; _yy < rack.y2 - 10; _yy += 40) for (var _xx = rack.x1 + 25; _xx < rack.x2 - 10; _xx += 40) draw_circle(_xx, _yy, 4, false);
draw_set_alpha(1);
// the visit's actions: 2 pips over the rack, filled while left (2026-11-24)
// two rounded bars across the rack's width, brass while left; the ones the thing in hand would spend pulse
var _prev = 0;
if (is_struct(wb_held)) {
	if (wb_held.kind == "tool") _prev = wb_cost(wb_held.ref.kind);
	else if (wb_in_bin(_mx, _my)) _prev = wb_cost("bin");
}
var _pw2 = (rack.x2 - rack.x1 - 8) / 2;
draw_set_font(font_tip());
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
for (var p = 0; p < 2; p++) {
	var _px1 = rack.x1 + p * (_pw2 + 8), _py1 = rack.y1 - 50;
	var _full = p < actions_left;
	var _spend = _full && p >= actions_left - _prev;
	draw_set_color(global.ui_col.ink);
	draw_roundrect_ext(_px1 - 3, _py1 - 3, _px1 + _pw2 + 3, _py1 + 33, 16, 16, false);
	draw_set_color(_full ? global.ui_col.brass : make_color_rgb(70, 52, 36));
	draw_roundrect_ext(_px1, _py1, _px1 + _pw2, _py1 + 30, 14, 14, false);
	if (_full) {
		draw_set_color(merge_colour(global.ui_col.brass, c_white, _spend ? 0.35 + 0.35 * sin(current_time / 110) : 0.3));
		draw_roundrect_ext(_px1 + 5, _py1 + 4, _px1 + _pw2 - 5, _py1 + 12, 4, 4, false);
	}
	draw_set_color(_full ? global.ui_col.ink : make_color_rgb(130, 108, 84));
	draw_text(_px1 + _pw2 / 2, _py1 + 19, _full ? "Action" : "Used");
}
for (var i = 0; i < array_length(wb_tools); i++) {
	var _t = wb_tools[i];
	if (_t.kind == "bin") continue; // the Bin isn't on the rack
	var _hb = wb_tool_box({ kind: _t.kind, hx: _t.home_x, hy: _t.home_y, ang: 0 });
	draw_set_color(global.ui_col.ink);
	draw_circle((_hb.x1 + _hb.x2) / 2, _hb.y1 + 2, 9, false);
	draw_set_color(global.ui_col.brass);
	draw_circle((_hb.x1 + _hb.x2) / 2, _hb.y1 + 2, 7, false);
}

// ---------------------------------------------------------------- the Bin: a fixed area; drop a die on it to throw it away
var _drag_die = is_struct(wb_held) && wb_held.kind == "die";
var _bin_hot = _input && _drag_die && wb_in_bin(_mx, _my);
var _bin_lit = _drag_die && wb_job == undefined;
var _bin_pulse = _bin_lit ? 0.5 + 0.5 * sin(current_time / 140) : 0;
ui_paper(bin_area.x1, bin_area.y1, bin_area.x2, bin_area.y2, 7, _bin_hot ? global.ui_col.paper_hi : global.ui_col.paper_shade);
if (_bin_lit) {
	draw_set_color(global.ui_col.brass);
	draw_set_alpha(_bin_hot ? 1 : 0.4 + 0.4 * _bin_pulse);
	for (var k = 0; k < 3; k++) draw_roundrect_ext(bin_area.x1 - k, bin_area.y1 - k, bin_area.x2 + k, bin_area.y2 + k, 14, 14, true);
	draw_set_alpha(1);
}
draw_bin_icon(bin_area.x1 + 66, (bin_area.y1 + bin_area.y2) / 2 + 4, _bin_hot ? 1.15 : 1, 1, c_white);
draw_set_font(font_tip());
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_set_color(global.ui_col.ink);
draw_text(bin_area.x1 + 130, (bin_area.y1 + bin_area.y2) / 2 - 16, "Bin");
draw_set_color(merge_colour(global.ui_col.ink, global.ui_col.paper_shade, 0.35));
draw_text(bin_area.x1 + 130, (bin_area.y1 + bin_area.y2) / 2 + 12, wb_cost_text("bin"));
if (_input && ((_drag_die && _bin_hot) || (!_drag_die && wb_held == undefined && wb_in_bin(_mx, _my)))) {
	var _bin_txt = "Remove a die from your bag.";
	if (_drag_die && ds_list_size(global.dice_bag) + array_length(wb_dice) <= 6) _bin_txt = "Your bag can't go below 6 dice.";
	else if (_drag_die && actions_left < wb_cost("bin")) _bin_txt = "Not enough actions.";
	queue_tooltip(_mx, _my, "Bin", _bin_txt + "\n" + wb_cost_text("bin"));
}

// ---------------------------------------------------------------- the dice
var _held_die = (is_struct(wb_held) && wb_held.kind == "die") ? wb_held.ref : undefined;
var _hover_die = undefined;
if (_input && wb_held == undefined) _hover_die = wb_die_at(_mx, _my, undefined, 42);
// what the tool in hand is over: a ring round each die it would work on (brass if it can, red if it can't)
var _ring_dice = [];
var _ring_ok = false;
if (is_struct(wb_target)) {
	_ring_ok = wb_target.ok;
	if (is_struct(wb_target.die)) array_push(_ring_dice, wb_target.die);
	if (is_struct(wb_target.pair)) { array_push(_ring_dice, wb_target.pair.a); array_push(_ring_dice, wb_target.pair.b); }
}
for (var i = 0; i < array_length(wb_dice); i++) {
	var _d = wb_dice[i];
	if (_d == _held_die) continue;
	wb_draw_die(_d, _d == _hover_die, array_contains(_ring_dice, _d), _ring_ok);
}
if (is_struct(wb_target) && is_struct(wb_target.pair)) {
	// where the head will land
	var _p = wb_target.pair;
	draw_set_color(_ring_ok ? global.ui_col.paper_hi : global.text_attack);
	draw_set_alpha(0.8);
	draw_line_width(_p.mx - 10, _p.my - 10, _p.mx + 10, _p.my + 10, 3);
	draw_line_width(_p.mx - 10, _p.my + 10, _p.mx + 10, _p.my - 10, 3);
	draw_set_alpha(1);
}
for (var i = 0; i < array_length(wb_rings); i++) {
	var _r = wb_rings[i];
	draw_set_color(_r.col);
	draw_set_alpha(1 - _r.t);
	var _rr = 30 + 90 * (1 - power(1 - _r.t, 3));
	for (var k = 0; k < 3; k++) draw_circle(_r.x, _r.y, _rr + k, true);
}
draw_set_alpha(1);
if (_hover_die != undefined) queue_die_tip(_hover_die.die, _hover_die.x, _hover_die.y - 44);

// ---------------------------------------------------------------- the tools
var _core_dragged = false;
for (var i = 0; i < array_length(oRunManager.items); i++) {
	var _it = oRunManager.items[i];
	if (is_struct(_it) && _it.type == "core" && variable_struct_exists(_it, "dragging") && _it.dragging) _core_dragged = true;
}
for (var i = 0; i < array_length(wb_tools); i++) {
	var _t = wb_tools[i];
	if (_t.kind == "bin") continue; // drawn above as a fixed area
	var _o = wb_tool_origin(_t);
	var _k = wb_tool_k * (1 + 0.06 * _t.lift);
	var _ang = _t.ang + sin(current_time / 90) * 6 * _t.wob;
	// a shadow under it while it's off the rack
	if (_t.hx < rack.x1 - 10) {
		draw_set_color(c_black);
		draw_set_alpha(0.25 * (0.6 + 0.4 * _t.lift));
		draw_ellipse(_t.hx - 46, _t.hy + 18 - 10, _t.hx + 46, _t.hy + 18 + 10, false);
		draw_set_alpha(1);
	}
	var _rest = actions_left < wb_cost(_t.kind) && !is_struct(wb_job); // too few actions left for it: it rests, greyed
	if (_t.sprite >= 0) draw_sprite_ext(_t.sprite, _t.frame, _o.x, _o.y, _k, _k, _ang, _rest ? c_gray : c_white, _rest ? 0.6 : 1);
	else draw_bin_icon(_o.x, _o.y, (1 + 0.06 * _t.lift), _rest ? 0.6 : 1, _rest ? c_gray : c_white);
	// the drill's chuck: a loaded core glows in it; while you carry a core, an empty chuck shows where it goes
	if (_t.kind == "drill") {
		var _s = wb_socket(_t);
		if (_t.core != undefined) {
			var _gl = 0.5 + 0.5 * sin(current_time / 160);
			draw_set_color(global.color_gold);
			draw_set_alpha(0.25 + 0.2 * _gl);
			draw_circle(_s.x, _s.y, 26 + 4 * _gl, false);
			draw_set_alpha(1);
			draw_sprite_ext(sCores, _t.core.index, _s.x, _s.y, 0.6, 0.6, 0, c_white, 1);
		} else if (_core_dragged) {
			var _pl = 0.5 + 0.5 * sin(current_time / 120);
			draw_set_color(global.ui_col.brass);
			draw_set_alpha(0.5 + 0.5 * _pl);
			for (var a = 0; a < 360; a += 30) draw_arc_thick_deg(_s.x, _s.y, 26 + 4 * _pl, 30 + 4 * _pl, a, a + 18, 4);
			draw_set_alpha(1);
		}
	}

	// hover: what it does (or that it's used)
	if (_input && wb_held == undefined) {
		var _b = wb_tool_box(_t);
		if (_mx > _b.x1 && _mx < _b.x2 && _my > _b.y1 && _my < _b.y2) {
			var _what = "Cut a die down and get a coin.";
			switch (_t.kind) {
				case "drill": _what = (_t.core != undefined) ? "Loaded: " + string(_t.core.name) + ".\nDrill it into a die." : "Drill a core into a die."; break;
				case "hammer": _what = "Combine two dice of the same type."; break;
			}
			queue_tooltip(_mx, _my, _t.name, _what + "\n" + wb_cost_text(_t.kind) + ((actions_left < wb_cost(_t.kind)) ? " You have " + string(actions_left) + "." : ""));
		}
	}
}
// (the tool in hand's notes, what it would do here and how to use it, are drawn together below)

// and how to use it, while it is in your hand (Jared, 2026-11-24)
if (is_struct(wb_held) && wb_held.kind == "tool" && wb_job == undefined) {
	var _ht = wb_held.ref;
	var _how = "";
	switch (_ht.kind) {
		case "drill": _how = (_ht.core != undefined) ? "Release over a die to drill the core into it." : "Load a core first: drag one from the top bar onto the drill."; break;
		case "hammer": _how = "Release between two dice of the same type to join them."; break;
		case "scissors": case "cutters": _how = "Release over a die to cut 2 sides off it. You get a coin."; break;
		default: _how = "Release over a die to use it.";
	}
	// two notes in a column under the cursor, left edges together (Jared, 2026-11-24): what it would do where it is,
	// then how to use it
	var _notes = [];
	if (is_struct(wb_target) && wb_target.text != "") array_push(_notes, { text: wb_target.text, ok: wb_target.ok });
	array_push(_notes, { text: _how, ok: true });
	array_push(_notes, { text: wb_cost_text(_ht.kind), ok: true });
	draw_set_font(font_tip());
	var _col_w = 0;
	for (var _ni = 0; _ni < array_length(_notes); _ni++) _col_w = max(_col_w, string_width(_notes[_ni].text) + 34);
	var _hx = clamp(_mx - 20, 20, gui_w - _col_w - 20), _hy = _my + 70;
	for (var _ni = 0; _ni < array_length(_notes); _ni++) {
		var _nt = _notes[_ni];
		ui_paper(_hx, _hy, _hx + _col_w, _hy + 44, 3 + _ni * 6, _nt.ok ? global.ui_col.paper_hi : global.ui_col.paper_shade);
		draw_set_halign(fa_left);
		draw_set_valign(fa_middle);
		draw_set_color(_nt.ok ? global.ui_col.ink : global.ui_col.danger);
		draw_text(_hx + 17, _hy + 23, _nt.text);
		_hy += 52;
	}
}

// the die in hand, over everything on the bench
if (_held_die != undefined) wb_draw_die(_held_die, false, false, false);

// ---------------------------------------------------------------- before anything else: dice from the bag
if (array_length(wb_dice) == 0 && oRunManager.dice_selection == false && !exiting) { // an empty bench: the note offers the bag
	var _pw = 520, _ph = 160;
	var _cx = (table.x1 + table.x2) / 2, _cy = (table.y1 + table.y2) / 2;
	ui_paper(_cx - _pw / 2, _cy - _ph / 2, _cx + _pw / 2, _cy + _ph / 2, 5);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_font(ftDefault);
	draw_set_color(global.ui_col.ink);
	draw_text(_cx, _cy - 38, "Take dice from your bag.");
	var _pick = ui_button(_cx, _cy + 30, 260, 64, pick_scale, "Open the bag", global.ui_primary);
	pick_scale = _pick.scale;
	if (_pick.click) workbench_open_picker();
}

// ---------------------------------------------------------------- Continue: everything on the bench goes back in the bag
var _ready = wb_job == undefined && wb_held == undefined && !oRunManager.holding_item && !exiting;
var _exit_btn = ui_primary(gui_w - 44 - 140, gui_h - 40 - 48, 280, 96, "Continue", _ready, "");
if (_exit_btn.click) exiting = true;

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1);
