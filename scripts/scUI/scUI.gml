// =====================================================================
// scUI: the UI kit for the logbook look (docs/design-ui-rework.md)
// Ink on paper for anything you read; pigments that only mean their action; gold ink only for insight.
// Grown screen by screen: combat first (tickets, tags, HP bars, glyphs, paper).
// =====================================================================

/// @func ui_init()
/// @desc The palette, set once at game start (oSettingsMenu Create). global.ui_col.* for surfaces and ink; the action pigments live in
///       global.color_attack / block / heal / intel (dice, slots, intents); global.text_* are their readable versions
///       for text on dark surfaces (tooltips, the table).
function ui_init() {
	global.ui_col = {
		ink:        make_color_rgb(42, 29, 18),
		ink_soft:   make_color_rgb(91, 70, 50),
		paper:      make_color_rgb(231, 214, 176),
		paper_hi:   make_color_rgb(241, 228, 196),
		paper_shade: make_color_rgb(201, 180, 138),
		slate:      make_color_rgb(26, 30, 40),
		rule:       make_color_rgb(226, 212, 176),
		brass:      make_color_rgb(201, 160, 96),
		bone:       make_color_rgb(233, 224, 204),
		danger:     make_color_rgb(110, 30, 24),
		table_dim:  make_color_rgb(40, 26, 18),   // laid over the fight's backdrop (dusk)
		felt:       make_color_rgb(24, 18, 13),   // the tray under your hand
		bonus_ink:  make_color_rgb(44, 110, 74),  // a bonus written on paper
	};
	global.ui_on_paper = false; // true while text is drawn on paper (ui_paper_text): colour-coded words use dark inks
	// the action pigments: a brightness ladder (attack darkest, then heal, block, insight lightest)
	global.color_attack = make_color_rgb(179, 58, 34);
	global.color_block  = make_color_rgb(111, 168, 232);
	global.color_heal   = make_color_rgb(60, 154, 104);
	global.color_intel  = make_color_rgb(242, 210, 74);
	// their text versions on dark surfaces (on paper, use the *_on_paper ones)
	global.text_attack = make_color_rgb(226, 115, 95);
	global.text_block  = make_color_rgb(143, 189, 240);
	global.text_heal   = make_color_rgb(110, 200, 150);
	global.text_attack_on_paper = make_color_rgb(154, 46, 28);
	global.text_block_on_paper  = make_color_rgb(31, 79, 143);
	global.text_heal_on_paper   = make_color_rgb(44, 110, 74);
	global.text_intel_on_paper  = make_color_rgb(110, 82, 10);
}

/// @func ui_hash(_seed, _k)
/// @desc A steady pseudo-random 0-1 from two numbers (the torn paper edge uses it, so it never shimmers).
function ui_hash(_seed, _k) {
	var _v = sin(_seed * 12.9898 + _k * 78.233) * 43758.5453;
	return _v - floor(_v);
}

/// @func ui_paper(_x1, _y1, _x2, _y2, _seed, [_fill], [_alpha], [_border], [_shadow])
/// @desc A piece of paper: a soft shadow, a slightly torn edge (steady, from _seed, scaling with the paper), its fill
///       and an ink border. Cheap: one fan and a line loop.
function ui_paper(_x1, _y1, _x2, _y2, _seed, _fill = undefined, _alpha = 1, _border = 3, _shadow = true) {
	if (is_undefined(_fill)) _fill = global.ui_col.paper;
	var _w = _x2 - _x1, _h = _y2 - _y1;
	// the outline: points every ~18 px round the edge, each nudged in or out a little
	var _pts = [];
	var _nx = max(3, round(_w / 18)), _ny = max(3, round(_h / 18));
	var _k = 0;
	for (var i = 0; i < _nx; i++) { array_push(_pts, [_x1 + _w * i / _nx, _y1 + (ui_hash(_seed, _k++) - 0.5) * 3]); }
	for (var i = 0; i < _ny; i++) { array_push(_pts, [_x2 + (ui_hash(_seed, _k++) - 0.5) * 3, _y1 + _h * i / _ny]); }
	for (var i = 0; i < _nx; i++) { array_push(_pts, [_x2 - _w * i / _nx, _y2 + (ui_hash(_seed, _k++) - 0.5) * 3]); }
	for (var i = 0; i < _ny; i++) { array_push(_pts, [_x1 + (ui_hash(_seed, _k++) - 0.5) * 3, _y2 - _h * i / _ny]); }
	var _n = array_length(_pts);
	var _cx = (_x1 + _x2) / 2, _cy = (_y1 + _y2) / 2;
	if (_shadow) {
		draw_set_alpha(0.4 * _alpha);
		draw_set_color(c_black);
		draw_roundrect_ext(_x1 + 3, _y1 + 9, _x2 + 3, _y2 + 9, 10, 10, false);
	}
	draw_set_alpha(_alpha);
	draw_set_color(_fill);
	draw_primitive_begin(pr_trianglefan);
	draw_vertex(_cx, _cy);
	for (var i = 0; i <= _n; i++) { var _p = _pts[i mod _n]; draw_vertex(_p[0], _p[1]); }
	draw_primitive_end();
	if (_border > 0) {
		draw_set_color(global.ui_col.ink);
		for (var i = 0; i < _n; i++) {
			var _a = _pts[i], _b = _pts[(i + 1) mod _n];
			draw_line_width(_a[0], _a[1], _b[0], _b[1], _border);
		}
	}
	draw_set_alpha(1);
	draw_set_color(c_white);
}

/// @func ui_glyph(_type, _x, _y, _size, _col, [_alpha])
/// @desc An action's glyph drawn in code, about _size px across: ATK a sword, BLK a shield, HEAL a heart, INTEL an eye.
///       Every action colour also has this shape, so nothing depends on colour alone.
function ui_glyph(_type, _x, _y, _size, _col, _alpha = 1) {
	var _s = _size / 20; // drawn on a 20 px grid
	draw_set_alpha(_alpha);
	draw_set_color(_col);
	switch (_type) {
		case "ATK": // a sword, blade up-right
			draw_line_width(_x - 7 * _s, _y + 7 * _s, _x + 7 * _s, _y - 7 * _s, 2.8 * _s);
			draw_line_width(_x + 3 * _s, _y - 8.5 * _s, _x + 8.5 * _s, _y - 8.5 * _s, 2.4 * _s);
			draw_line_width(_x + 8.5 * _s, _y - 8.5 * _s, _x + 8.5 * _s, _y - 3 * _s, 2.4 * _s);
			draw_line_width(_x - 8.5 * _s, _y + 3 * _s, _x - 3 * _s, _y + 8.5 * _s, 2.6 * _s); // the guard
			draw_circle(_x - 9 * _s, _y + 9 * _s, 2 * _s, false); // the pommel
			break;
		case "BLK": // a shield
			draw_primitive_begin(pr_trianglefan);
			draw_vertex(_x, _y);
			draw_vertex(_x, _y - 9 * _s); draw_vertex(_x + 8 * _s, _y - 6 * _s); draw_vertex(_x + 7 * _s, _y + 3 * _s);
			draw_vertex(_x, _y + 10 * _s); draw_vertex(_x - 7 * _s, _y + 3 * _s); draw_vertex(_x - 8 * _s, _y - 6 * _s);
			draw_vertex(_x, _y - 9 * _s);
			draw_primitive_end();
			break;
		case "HEAL": // a heart
			draw_circle(_x - 4 * _s, _y - 2.5 * _s, 4.6 * _s, false);
			draw_circle(_x + 4 * _s, _y - 2.5 * _s, 4.6 * _s, false);
			draw_triangle(_x - 8.4 * _s, _y - 1 * _s, _x + 8.4 * _s, _y - 1 * _s, _x, _y + 9 * _s, false);
			break;
		case "INTEL": // an eye
			for (var t = -1; t <= 1; t += 2) {
				var _px = _x - 9 * _s, _py = _y;
				for (var k = 1; k <= 8; k++) {
					var _u = k / 8;
					var _qx = _x - 9 * _s + 18 * _s * _u, _qy = _y + t * 7 * _s * sin(_u * pi);
					draw_line_width(_px, _py, _qx, _qy, 2.2 * _s);
					_px = _qx; _py = _qy;
				}
			}
			draw_circle(_x, _y, 3.2 * _s, false);
			break;
	}
	draw_set_alpha(1);
	draw_set_color(c_white);
}

/// @func ui_numeral(_text, _x, _y, _size, _col, [_alpha], [_halign])
/// @desc A number in the numeral face (Lato Black, ftDamage at 40 px) at about _size px: 48 totals and intents, 32 HP,
///       20 bonuses and counts. Scaled from the one Lato font until the numeral fonts are made (see the design doc).
function ui_numeral(_text, _x, _y, _size, _col, _alpha = 1, _halign = fa_center) {
	draw_set_font(ftDamage);
	draw_set_halign(_halign);
	draw_set_valign(fa_middle);
	var _sc = (abs(_size - 40) <= 8) ? 1 : _size / 40; // near its own size: drawn unscaled, crisp (scaled up, it blurs)
	draw_set_alpha(_alpha);
	draw_set_color(_col);
	draw_text_transformed(_x, _y, string(_text), _sc, _sc, 0);
	draw_set_alpha(1);
	draw_set_color(c_white);
}

/// @func ui_hp_bar(_cx, _y, _w, _hp_shown, _hp, _max, [_alpha])
/// @desc A readable health bar centred on _cx: a 20 px inked bar (red for what's left), and the number under it in
///       the numeral face ("22 / 30"), cream with an ink halo so it reads on the table. Returns its height.
function ui_hp_bar(_cx, _y, _w, _hp_shown, _hp, _max, _alpha = 1) {
	// a 26 px inked bar with the number on it (Molly: smaller, on the bar, so buffs and debuffs sit close under it)
	var _x1 = _cx - _w / 2, _x2 = _cx + _w / 2;
	var _r = clamp(_hp_shown / max(1, _max), 0, 1);
	draw_set_alpha(_alpha);
	draw_set_color(global.ui_col.ink);
	draw_roundrect_ext(_x1 - 3, _y - 3, _x2 + 3, _y + 29, 12, 12, false);
	draw_set_color(make_color_rgb(28, 23, 18));
	draw_roundrect_ext(_x1, _y, _x2, _y + 26, 10, 10, false);
	if (_r > 0) {
		draw_set_color(global.color_attack);
		draw_roundrect_ext(_x1 + 2, _y + 2, _x1 + 2 + (_w - 4) * _r, _y + 24, 8, 8, false);
		draw_set_color(merge_colour(global.color_attack, c_white, 0.25));
		draw_line_width(_x1 + 6, _y + 6, max(_x1 + 6, _x1 + (_w - 8) * _r), _y + 6, 2); // a little shine
	}
	// the number on the bar, cream with an ink halo
	var _txt = string(round(_hp)) + " / " + string(_max);
	draw_set_font(ftBig);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(global.ui_col.ink);
	for (var a = 0; a < 8; a++) draw_text(_cx + lengthdir_x(2, a * 45), _y + 13 + lengthdir_y(2, a * 45), _txt);
	draw_set_color(global.ui_col.paper_hi);
	draw_text(_cx, _y + 13, _txt);
	draw_set_alpha(1);
	draw_set_color(c_white);
	return 32;
}

/// @func ui_ticket(_x, _y, _w, _h, _type, _label, _total, _bonus, _seed, [_state])
/// @desc A slot as a paper ticket pinned to the table: a band in its action's pigment with its glyph and name, the
///       total huge in ink, the slot's bonus inked beside it ("+1"). _type "None" (empty) is plain paper with "Empty";
///       _state: "" normal, "acting" (resolving now: a brass edge), "locked" (greyed band), "faded".
function ui_ticket(_x, _y, _w, _h, _type, _label, _total, _bonus, _seed, _state = "") {
	var _empty = (_type == "None" || _type == "" || _label == "" || _label == "No action");
	var _alpha = (_state == "faded") ? 0.55 : 1;
	if (_state == "acting") {
		draw_set_color(global.ui_col.brass);
		draw_set_alpha(0.55 + 0.25 * sin(current_time / 120));
		draw_roundrect_ext(_x - 9, _y - 9, _x + _w + 9, _y + _h + 9, 14, 14, false);
		draw_set_alpha(1);
	}
	ui_paper(_x, _y, _x + _w, _y + _h, _seed, _empty ? global.ui_col.paper_shade : global.ui_col.paper, _alpha);
	var _band_h = round(_h * 0.25);
	var _col = _empty ? make_color_rgb(150, 140, 120) : get_dice_color(_type);
	if (_state == "locked") _col = make_color_rgb(90, 86, 80);
	draw_set_alpha(_alpha);
	draw_set_color(_col);
	draw_rectangle(_x + 4, _y + 4, _x + _w - 4, _y + _band_h, false);
	draw_set_color(global.ui_col.ink);
	draw_line_width(_x + 4, _y + _band_h, _x + _w - 4, _y + _band_h, 2);
	draw_set_alpha(1);
	// on the band: the glyph and the name, light on dark pigments, ink on light ones
	var _lum = 0.299 * colour_get_red(_col) + 0.587 * colour_get_green(_col) + 0.114 * colour_get_blue(_col);
	var _on = (_lum < 150) ? global.ui_col.paper_hi : global.ui_col.ink;
	var _by = _y + 4 + (_band_h - 4) / 2;
	if (!_empty) ui_glyph(_type, _x + 20, _by, _band_h * 0.55, _on, _alpha);
	draw_set_font(ftBig); // 20 px: readable at 1080 (UI rework, round 2)
	draw_set_halign(_empty ? fa_center : fa_left);
	draw_set_valign(fa_middle);
	draw_set_color(_on);
	draw_set_alpha(_alpha);
	var _name = _empty ? "Empty" : _label;
	var _name_x = _empty ? _x + _w / 2 : _x + 36;
	var _sc = min(1, (_w - (_empty ? 16 : 44)) / max(1, string_width(_name)));
	draw_text_transformed(_name_x, _by, _name, _sc, _sc, 0);
	draw_set_alpha(1);
	// an empty ticket still shows what its place adds (B138)
	if (_empty && _bonus != "") ui_numeral(_bonus, _x + _w / 2, _y + _band_h + (_h - _band_h) * 0.5, 30, global.ui_col.bonus_ink, _alpha * 0.85);
	// the total, huge in ink, and the bonus beside it
	if (!_empty && string(_total) != "") {
		var _tx = _bonus != "" ? _x + _w * 0.42 : _x + _w / 2;
		ui_numeral(_total, _tx, _y + _band_h + (_h - _band_h) * 0.52, 44, global.ui_col.ink, _alpha); // the numeral face at its own size: crisp
		if (_bonus != "") ui_numeral(_bonus, _x + _w * 0.78, _y + _band_h + (_h - _band_h) * 0.5, min(30, _h * 0.2), global.ui_col.bonus_ink, _alpha);
	}
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_color(c_white);
}

/// @func ui_tag(_cx, _cy, _w, _h, _seed, [_alpha])
/// @desc An intent's paper tag hung over an enemy: a short string up to a nail, then the paper (the icons and number go on
///       top, drawn by the caller in ink).
function ui_tag(_cx, _cy, _w, _h, _seed, _alpha = 1) {
	draw_set_alpha(_alpha);
	draw_set_color(global.ui_col.rule);
	draw_line_width(_cx, _cy - _h / 2 - 22, _cx, _cy - _h / 2 + 2, 2);
	draw_set_color(global.ui_col.ink);
	draw_circle(_cx, _cy - _h / 2 - 22, 3, false);
	draw_set_alpha(1);
	ui_paper(_cx - _w / 2, _cy - _h / 2, _cx + _w / 2, _cy + _h / 2, _seed, global.ui_col.paper, _alpha);
}

/// @func ui_dashed_box(_x1, _y1, _x2, _y2, _col, [_alpha], [_dash], [_width])
/// @desc A dashed outline (a place for something that isn't there yet: the new-slot tile), with a faint wash inside.
function ui_dashed_box(_x1, _y1, _x2, _y2, _col, _alpha = 1, _dash = 16, _width = 3) {
	draw_set_alpha(0.07 * _alpha);
	draw_set_color(global.ui_col.paper);
	draw_rectangle(_x1, _y1, _x2, _y2, false);
	draw_set_alpha(0.7 * _alpha);
	draw_set_color(_col);
	var _edges = [[_x1, _y1, _x2, _y1], [_x2, _y1, _x2, _y2], [_x2, _y2, _x1, _y2], [_x1, _y2, _x1, _y1]];
	for (var e = 0; e < 4; e++) {
		var _a = _edges[e];
		var _len = point_distance(_a[0], _a[1], _a[2], _a[3]);
		for (var d = 0; d < _len; d += _dash * 1.7) {
			var _t0 = d / _len, _t1 = min(1, (d + _dash) / _len);
			draw_line_width(lerp(_a[0], _a[2], _t0), lerp(_a[1], _a[3], _t0), lerp(_a[0], _a[2], _t1), lerp(_a[1], _a[3], _t1), _width);
		}
	}
	draw_set_alpha(1);
	draw_set_color(c_white);
}

/// @func ui_primary_button(_cx, _cy, _w, _h, _text, _frame_col, _active, [_hover])
/// @desc The screen's one commit action (End Turn, Embark...): the brightest paper on the table in a thick frame
///       (brass; gold ink while the ink view is open), its words in ink. Inactive: faded. Hovered: lifts a little.
function ui_primary_button(_cx, _cy, _w, _h, _text, _frame_col, _active, _hover = false, _alpha = 1) {
	var _lift = (_hover && _active) ? 3 : 0;
	var _x1 = _cx - _w / 2, _y1 = _cy - _h / 2 - _lift, _x2 = _cx + _w / 2, _y2 = _cy + _h / 2 - _lift;
	var _a = (_active ? 1 : 0.55) * _alpha;
	draw_set_alpha(0.45 * _a);
	draw_set_color(c_black);
	draw_roundrect_ext(_x1 + 4, _y1 + 10 + _lift, _x2 + 4, _y2 + 10 + _lift, 18, 18, false);
	draw_set_alpha(_a);
	draw_set_color(global.ui_col.ink);
	draw_roundrect_ext(_x1 - 3, _y1 - 3, _x2 + 3, _y2 + 3, 18, 18, false);
	draw_set_color(_frame_col);
	draw_roundrect_ext(_x1, _y1, _x2, _y2, 16, 16, false);
	draw_set_color(global.ui_col.ink);
	draw_roundrect_ext(_x1 + 8, _y1 + 8, _x2 - 8, _y2 - 8, 11, 11, false);
	draw_set_color(_active ? global.ui_col.paper_hi : global.ui_col.paper_shade);
	draw_roundrect_ext(_x1 + 10, _y1 + 10, _x2 - 10, _y2 - 10, 10, 10, false);
	draw_set_font(ftBigger);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(global.ui_col.ink);
	var _sc = min(1.35, (_w - 40) / max(1, string_width(_text)));
	draw_text_transformed(_cx, _cy - _lift, _text, _sc, _sc, 0);
	draw_set_alpha(1);
	draw_set_color(c_white);
}

/// @func ui_text_on_paper(_col)
/// @desc The readable-on-paper version of a text colour (colour-coded words on a paper card are darker inks):
///       used by draw_outline_text while global.ui_on_paper is true.
function ui_text_on_paper(_col) {
	if (_col == global.text_block || _col == global.color_block) return global.text_block_on_paper;
	if (_col == global.text_heal || _col == global.color_heal || _col == c_lime) return global.text_heal_on_paper;
	if (_col == global.text_attack || _col == global.color_attack || _col == c_red) return global.text_attack_on_paper;
	if (_col == global.color_intel || _col == c_yellow) return global.text_intel_on_paper;
	if (_col == c_aqua || _col == c_teal) return make_color_rgb(18, 104, 104);
	if (_col == c_orange) return make_color_rgb(150, 80, 12);
	if (_col == c_ltgray || _col == c_silver || _col == c_gray) return global.ui_col.ink_soft;
	if (_col == make_colour_rgb(230, 50, 230)) return make_color_rgb(128, 34, 128);
	if (_col == c_white) return global.ui_col.ink;
	return _col;
}

/// @func ui_paper_text(_text, _x, _y, [_width], [_alpha])
/// @desc Text on paper: ink, colour-coded words in their dark inks, a faint paper halo. Uses the current font/align.
function ui_paper_text(_text, _x, _y, _width = -1, _alpha = 1) {
	global.ui_on_paper = true;
	draw_outline_text(_text, global.ui_col.paper_hi, global.ui_col.ink, 1, _x, _y, 1, _alpha, 0, _width);
	global.ui_on_paper = false;
}

/// @func ui_primary(_cx, _cy, _w, _h, _text, _active, [_reason], [_layer], [_alpha], [_frame_col])
/// @desc The screen's commit action with its input: draws ui_primary_button (lifting on hover) and returns
///       { hover, click }. Inactive: faded, and _reason shows on hover.
function ui_primary(_cx, _cy, _w, _h, _text, _active, _reason = "", _layer = UI_LAYER.BASE, _alpha = 1, _frame_col = undefined) {
	if (is_undefined(_frame_col)) _frame_col = global.ui_col.brass;
	var _hover = (_alpha > 0.5) && mouse_hovering(_cx - _w / 2, _cy - _h / 2, _w, _h, false, soSlotHover, noone, !global.all_input_disabled, _layer); // not during a cutscene
	ui_primary_button(_cx, _cy, _w, _h, _text, _frame_col, _active, _hover, _alpha);
	if (_hover && !_active && _reason != "") queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), _text, _reason);
	var _click = _hover && _active && mouse_check_button_pressed(mb_left);
	if (_click) sfx_play(soClick4, AUDIO_GROUP.UI, random_range(0.01, 0.05), 1);
	return { hover: _hover, click: _click };
}

/// @func ui_summon_icon(_cx, _cy, _scale, _alpha)
/// @desc A summon intent's icon (F139): two hands' worth of crew, one in front of the other, with a "+" for the newcomer,
///       in ink and amber, about 40 px across at scale 1.
function ui_summon_icon(_cx, _cy, _scale = 1, _alpha = 1) {
	var _s = _scale, _ink = global.ui_col.ink, _amb = make_color_rgb(230, 150, 60);
	draw_set_alpha(_alpha);
	// the one behind
	draw_set_color(_ink);
	draw_circle(_cx + 7 * _s, _cy - 9 * _s, 7 * _s, false);
	draw_roundrect_ext(_cx - 3 * _s, _cy - 1 * _s, _cx + 17 * _s, _cy + 16 * _s, 10 * _s, 10 * _s, false);
	// the newcomer in front, in amber with an ink edge
	draw_circle(_cx - 6 * _s, _cy - 5 * _s, 8.5 * _s, false);
	draw_roundrect_ext(_cx - 18 * _s, _cy + 3 * _s, _cx + 6 * _s, _cy + 20 * _s, 11 * _s, 11 * _s, false);
	draw_set_color(_amb);
	draw_circle(_cx - 6 * _s, _cy - 5 * _s, 6.5 * _s, false);
	draw_roundrect_ext(_cx - 16 * _s, _cy + 5 * _s, _cx + 4 * _s, _cy + 20 * _s, 9 * _s, 9 * _s, false);
	// the +
	draw_set_color(_ink);
	draw_line_width(_cx + 14 * _s, _cy - 22 * _s, _cx + 14 * _s, _cy - 10 * _s, 4 * _s);
	draw_line_width(_cx + 8 * _s, _cy - 16 * _s, _cx + 20 * _s, _cy - 16 * _s, 4 * _s);
	draw_set_alpha(1);
	draw_set_color(c_white);
}

/// @func ui_label(_cx, _cy, _text, _font, _seed, [_alpha], [_pad])
/// @desc A heading on a strip of paper (the draft's "Choose a page to draft"): ink text on a torn paper label.
function ui_label(_cx, _cy, _text, _font, _seed, _alpha = 1, _pad = 28) {
	draw_set_font(_font);
	var _w = string_width(_text) + _pad * 2, _h = string_height(_text) + _pad * 0.8;
	ui_paper(_cx - _w / 2, _cy - _h / 2, _cx + _w / 2, _cy + _h / 2, _seed, global.ui_col.paper_hi, _alpha);
	draw_set_font(_font);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_alpha(_alpha);
	draw_set_color(global.ui_col.ink);
	draw_text(_cx, _cy, _text);
	draw_set_alpha(1);
	draw_set_color(c_white);
}
