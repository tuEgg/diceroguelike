// The workbench as a free bench (F224, Jared 2026-11-22; docs/mockups/workbench-freeform.html): no slots. Dice sit
// anywhere on the table; the tools hang on a rack and work wherever they land. The Drill takes a core in its chuck and
// drills it into a die; the Hammer swung on the gap between two dice joins them; the Cutters trim a die and a coin
// hops out. Each tool once per visit. Dice come from the bag any time (the bag icon opens the picker, no limit) and
// go back to it by being dropped on the bag, or all at once on Continue.
gui_w = display_get_gui_width();
gui_h = display_get_gui_height();

table = { x1: 90, y1: 210, x2: 1540, y2: 960 };
rack = { x1: 1590, y1: 210, x2: 1870, y2: 880 };

wb_dice = [];            // dice on the table: { die (struct), x, y, scale, rot, flash, hop, vx, vy }
wb_held = undefined;     // what the mouse carries: { kind: "die" | "tool", ref, ox, oy }
wb_job = undefined;      // a tool at work (an animation that ends in the craft): { kind, tool, t, ... }
wb_scuffs = [];          // marks the hammer left on the table: { x, y, r, a }
wb_rings = [];           // rings that spread from a craft: { x, y, col, t }
wb_tool_k = 0.42;        // the tools' sprites are big; drawn at this scale
tools_used = [];         // tool objects used this visit (each tool works once per visit)
exiting = false;
wb_target = undefined;   // what the tool in hand would do where it is (wb_tool_target), for the hover text and rings

// the tools you own, on the rack. hx, hy: the working point (the drill's tip, the hammer's head, where the blades
// cross); everything else is drawn from it (wb_tool_origin)
wb_tools = [];
for (var i = 0; i < ds_list_size(oRunManager.tools); i++) {
	var _tl = oRunManager.tools[| i];
	var _kind = (_tl.object == oDrill) ? "drill" : ((_tl.object == oHammer) ? "hammer" : "cutters");
	var _home = (_kind == "drill") ? [1660, 560] : ((_kind == "hammer") ? [1800, 330] : [1730, 760]);
	array_push(wb_tools, {
		kind: _kind, object: _tl.object, name: _tl.name, sprite: object_get_sprite(_tl.object),
		hx: _home[0], hy: _home[1], home_x: _home[0], home_y: _home[1],
		ang: 0, frame: 0, used: false, lift: 0, wob: 0, core: undefined, core_slot: -1, returning: false, grab_t: 0,
	});
}

/// @func wb_tool_origin(_t)
/// @desc Where a tool's sprite is drawn from (its origin), given its working point. The hammer swings round it.
wb_tool_origin = function(_t) {
	var _k = wb_tool_k;
	switch (_t.kind) {
		case "drill": return { x: _t.hx, y: _t.hy - 269 * _k };          // the tip is 269 px under the chuck
		case "hammer": return { x: _t.hx + 3 * _k, y: _t.hy + 403 * _k }; // the end of the handle, 403 px under the head
		default: return { x: _t.hx + 28 * _k, y: _t.hy + 178 * _k };     // where the blades cross
	}
}

/// @func wb_tool_box(_t)
/// @desc The part of a tool you can grab, as a rectangle round its sprite.
wb_tool_box = function(_t) {
	var _o = wb_tool_origin(_t), _k = wb_tool_k;
	switch (_t.kind) {
		case "drill": return { x1: _o.x - 210 * _k, y1: _o.y - 440 * _k, x2: _o.x + 40 * _k, y2: _o.y + 269 * _k };
		case "hammer": return { x1: _o.x - 133 * _k, y1: _o.y - 553 * _k, x2: _o.x + 127 * _k, y2: _o.y + 136 * _k };
		default: return { x1: _o.x - 223 * _k, y1: _o.y - 423 * _k, x2: _o.x + 246 * _k, y2: _o.y + 92 * _k };
	}
}

/// @func wb_socket(_t)
/// @desc The drill's chuck, where a core goes.
wb_socket = function(_t) {
	var _o = wb_tool_origin(_t);
	return { x: _o.x, y: _o.y + 20 * wb_tool_k };
}

/// @func wb_tool_of(_object)
wb_tool_of = function(_object) {
	for (var i = 0; i < array_length(wb_tools); i++) if (wb_tools[i].object == _object) return wb_tools[i];
	return undefined;
}

/// @func wb_die_at(_x, _y, _except, _reach)
/// @desc The topmost die on the table within reach of a point, or undefined.
wb_die_at = function(_x, _y, _except = undefined, _reach = 46) {
	for (var i = array_length(wb_dice) - 1; i >= 0; i--) {
		var _d = wb_dice[i];
		if (_d != _except && point_distance(_x, _y, _d.x, _d.y) < _reach) return _d;
	}
	return undefined;
}

/// @func wb_pair_at(_x, _y)
/// @desc The two dice a hammer at this point would join: side by side (at most 200 px apart), their gap under it.
wb_pair_at = function(_x, _y) {
	var _best = undefined, _bd = 70;
	for (var i = 0; i < array_length(wb_dice); i++) for (var j = i + 1; j < array_length(wb_dice); j++) {
		var _a = wb_dice[i], _b = wb_dice[j];
		if (point_distance(_a.x, _a.y, _b.x, _b.y) > 200) continue;
		var _mx = (_a.x + _b.x) / 2, _my = (_a.y + _b.y) / 2;
		var _dd = point_distance(_x, _y, _mx, _my);
		if (_dd < _bd) { _bd = _dd; _best = { a: _a, b: _b, mx: _mx, my: _my }; }
	}
	return _best;
}

/// @func wb_add_die(_die, _x, _y)
/// @desc Puts a die (struct) on the table.
wb_add_die = function(_die, _x, _y) {
	var _d = { die: _die, x: _x, y: _y, scale: 1, rot: 0, flash: 0, hop: 0, vx: 0, vy: 0, fly: undefined };
	array_push(wb_dice, _d);
	return _d;
}

/// @func wb_remove_die(_d)
wb_remove_die = function(_d) {
	for (var i = array_length(wb_dice) - 1; i >= 0; i--) if (wb_dice[i] == _d) array_delete(wb_dice, i, 1);
}

/// @func wb_free_spot()
/// @desc A spot on the table clear of the other dice (for a die from the bag).
wb_free_spot = function() {
	for (var _try = 0; _try < 60; _try++) {
		var _x = irandom_range(table.x1 + 120, table.x2 - 120), _y = irandom_range(table.y1 + 160, table.y2 - 90);
		if (wb_die_at(_x, _y, undefined, 110) == undefined) return [_x, _y];
	}
	return [irandom_range(table.x1 + 120, table.x2 - 120), irandom_range(table.y1 + 160, table.y2 - 90)];
}

/// @func wb_to_bag(_d)
/// @desc A die on the table goes back in the bag: it flies there and is added when it lands (oDiceParticle).
wb_to_bag = function(_d) {
	var _p = instance_create_depth(_d.x, _d.y, -13, oDiceParticle);
	_p.die_struct = clone_die(_d.die, _d.die.permanence);
	_p.color_main = get_dice_color(_d.die.possible_type);
	_p.target_x = 60;
	_p.target_y = gui_h - 40;
	wb_remove_die(_d);
}

/// @func wb_tool_target(_t)
/// @desc What the tool in hand would do where it is now: { ok, text, die, pair }. ok false with a text: it says why not.
wb_tool_target = function(_t) {
	var _r = { ok: false, text: "", die: undefined, pair: undefined };
	if (_t.hx > rack.x1 - 20) return _r; // over the rack: putting it back
	switch (_t.kind) {
		case "drill":
			var _d = wb_die_at(_t.hx, _t.hy);
			if (_d == undefined) return _r;
			_r.die = _d;
			if (_d.die.dice_value <= 2) _r.text = "Coins can't take a core.";
			else if (_t.core == undefined) _r.text = "Load a core into the drill first.";
			else { _r.ok = true; _r.text = "Add the " + string(_t.core.name) + " to this die."; }
			break;
		case "hammer":
			var _p = wb_pair_at(_t.hx, _t.hy);
			if (_p == undefined) return _r;
			_r.pair = _p;
			var _sum = _p.a.die.dice_value + _p.b.die.dice_value;
			if (_p.a.die.action_type != _p.b.die.action_type) _r.text = "Only dice of the same type combine.";
			else if (_sum > 12) _r.text = "Too big: d12 at most.";
			else { _r.ok = true; _r.text = "Combine these dice into a d" + string(_sum) + "."; }
			break;
		default:
			var _d = wb_die_at(_t.hx, _t.hy);
			if (_d == undefined) return _r;
			_r.die = _d;
			var _v = _d.die.dice_value;
			if (_v <= 2) _r.text = "A coin can't be cut.";
			else if (_v - 2 == 2 && _d.die.distribution != "") { _r.ok = true; _r.text = "Cut it down to a coin and get a coin. Its core is lost."; }
			else { _r.ok = true; _r.text = "Cut it down to a " + ((_v - 2 == 2) ? "coin" : "d" + string(_v - 2)) + " and get a coin."; }
			break;
	}
	return _r;
}

/// @func workbench_take_core(_core, _item_slot)
/// @desc A core let go of at the mouse (oRunManager, on release): over the drill it loads the drill's chuck. Returns
///       true when taken (the caller clears its top-bar slot).
workbench_take_core = function(_core, _item_slot) {
	var _t = wb_tool_of(oDrill);
	if (_core.type != "core" || _t == undefined || _t.used || _t.core != undefined || wb_job != undefined) return false;
	var _s = wb_socket(_t);
	var _b = wb_tool_box(_t);
	var _mx = device_mouse_x_to_gui(0), _my = device_mouse_y_to_gui(0);
	if (point_distance(_mx, _my, _s.x, _s.y) > 70 && !(_mx > _b.x1 && _mx < _b.x2 && _my > _b.y1 && _my < _b.y2)) return false;
	_t.core = _core;
	_t.core_slot = _item_slot;
	_t.wob = 1;
	particle_emit(_s.x, _s.y, "burst", c_white, 18);
	array_push(wb_rings, { x: _s.x, y: _s.y, col: global.color_gold, t: 0 });
	screen_shake(2);
	sfx_play(soSlotPlace, AUDIO_GROUP.SFX, 0.1, 0.8);
	return true;
}

/// @func wb_draw_die(_d, _hover, _ring, _ok)
/// @desc A die on the table: its shadow, a ring when the tool in hand is over it (brass if it can work on it, red if
///       not), the die, a white flash after a craft, and a small gem on its corner when it has a core.
wb_draw_die = function(_d, _hover, _ring, _ok) {
	var _r = 36 * _d.scale * (_hover ? 1.08 : 1);
	var _y = _d.y - _d.hop;
	var _v = _d.die.dice_value;
	draw_set_color(c_black);
	draw_set_alpha(0.28 * (1 - min(0.6, _d.hop / 120)));
	draw_ellipse(_d.x - _r * 0.9, _d.y + _r * 0.55, _d.x + _r * 0.9, _d.y + _r * 0.95, false);
	draw_set_alpha(1);
	if (_ring) {
		var _pl = 0.5 + 0.5 * sin(current_time / 110);
		draw_die_shape(_d.x, _y, _r * (1.28 + 0.06 * _pl), _v, _ok ? global.ui_col.brass : global.text_attack, _d.rot, 0.55 + 0.3 * _pl);
	}
	draw_die(_d.x, _y, _r, _v, -1, die_colours(_d.die.possible_type), _d.rot, 1, _d.die);
	if (_d.flash > 0.02) draw_die_shape(_d.x, _y, _r * 1.02, _v, c_white, _d.rot, _d.flash * 0.8);
	if (_d.die.distribution != "" && get_core_index(_d.die) >= 0) draw_sprite_ext(sCores, get_core_index(_d.die), _d.x + _r * 0.8, _y - _r * 0.8, 0.4, 0.4, 0, c_white, 1);
}

// the bag doesn't open by itself: a note on the bench (and the bag icon) open it to choose dice (workbench_open_picker)
pick_pending = false;
pick_scale = 1;
with (oRunManager) {
	if (!dice_dealt) {
		turn_count = 1;
		dice_dealt = true;
		other.pick_pending = true;
	}
}
