gui_w = display_get_gui_width();
gui_h = display_get_gui_height();
var _mx = device_mouse_x_to_gui(0), _my = device_mouse_y_to_gui(0);

// Continue: every die on the table goes back to the bag; once they've landed (and a loaded core is back in the top
// bar), off to the map
if (exiting) {
	for (var i = array_length(wb_dice) - 1; i >= 0; i--) wb_to_bag(wb_dice[i]);
	if (!instance_exists(oDiceParticle)) {
		var _dr = wb_tool_of(oDrill);
		if (_dr != undefined && _dr.core != undefined) {
			var _slot = -1;
			if (_dr.core_slot != -1 && oRunManager.items[_dr.core_slot] == undefined) _slot = _dr.core_slot;
			else for (var i = 0; i < array_length(oRunManager.items); i++) if (oRunManager.items[i] == undefined) { _slot = i; break; }
			if (_slot != -1) {
				_dr.core.dragging = false;
				oRunManager.items[_slot] = _dr.core;
			}
			_dr.core = undefined;
		}
		room_goto(rmMap);
	}
	exit;
}

var _fps = game_get_speed(gamespeed_fps);
var _input = global.ui_layer == UI_LAYER.BASE && !global.show_settings && oRunManager.dice_selection == false && wb_job == undefined;

// ---------------------------------------------------------------- dice on the table
for (var i = 0; i < array_length(wb_dice); i++) {
	var _d = wb_dice[i];
	var _held = is_struct(wb_held) && wb_held.ref == _d;
	if (_held) {
		_d.x = _mx + wb_held.ox;
		_d.y = _my + wb_held.oy;
	} else if (is_struct(_d.fly) && _d.fly.kind == "deal") {
		// dealt from the bag as in a fight (oDice): a wait for its turn, then out with the roll sound, tumbling,
		// slowing near its spot and landing on it with a small pop
		var _f = _d.fly;
		if (_f.delay > 0) _f.delay--;
		else {
			if (_f.spd == 0) {
				_f.spd = max(30, point_distance(_d.x, _d.y, _f.tx, _f.ty) / 40);
				sfx_play(choose(soDiceRolling1, soDiceRolling2, soDiceRolling3), AUDIO_GROUP.SFX, random_range(0.01, 0.05), 0.4);
			}
			var _left = point_distance(_d.x, _d.y, _f.tx, _f.ty);
			if (_left < 150) _f.spd = max(10, lerp(_f.spd, 0, 0.12));
			if (_left <= _f.spd) {
				_d.x = _f.tx;
				_d.y = _f.ty;
				_d.fly = undefined;
				_d.scale = 1.22;
				_d.sv = 0;
			} else {
				var _dir = point_direction(_d.x, _d.y, _f.tx, _f.ty);
				_d.x += lengthdir_x(_f.spd, _dir);
				_d.y += lengthdir_y(_f.spd, _dir);
				_d.rot += 26;
			}
		}
	} else if (is_struct(_d.fly)) {
		// a coin hopping off the Cutters: eased, on an arc, landing with a pop
		var _f = _d.fly;
		_f.t += 1 / _f.dur;
		var _e = 1 - power(1 - clamp(_f.t, 0, 1), 3);
		_d.x = lerp(_f.sx, _f.tx, _e);
		_d.y = lerp(_f.sy, _f.ty, _e) - sin(clamp(_f.t, 0, 1) * pi) * _f.arc;
		_d.rot = (1 - clamp(_f.t, 0, 1)) * _f.spin;
		if (_f.t >= 1) {
			_d.fly = undefined;
			_d.rot = 0;
			_d.scale = 1.3;
			particle_emit(_d.x, _d.y + 26, "burst", global.ui_col.paper_shade, 6);
			sfx_play(soSlotPlace, AUDIO_GROUP.SFX, 0.15, 0.4);
		}
	} else {
		// a hop (knocked by a hammer): up and down, sliding a little, a pop where it lands
		if (_d.hop > 0 || _d.vy != 0) {
			_d.hop += _d.vy;
			_d.vy -= 0.9;
			if (_d.hop <= 0) { _d.hop = 0; _d.vy = 0; _d.scale = 1.25; }
		}
		_d.x += _d.vx;
		_d.vx *= 0.86;
		_d.rot += angle_difference(0, _d.rot) * 0.35; // settles square, the short way round
	}
	// a springy scale: a landing or a craft sets it high, it settles back to 1 (Jared, 2026-11-22: less bouncy)
	if (!variable_struct_exists(_d, "sv")) _d.sv = 0;
	var _target = _held ? 1.15 : 1;
	_d.sv = (_d.sv + (_target - _d.scale) * 0.25) * 0.55;
	_d.scale += _d.sv;
	_d.flash *= 0.9;
}
// dice don't stack: two too close are nudged apart (not the one in hand, nor ones in the air)
for (var i = 0; i < array_length(wb_dice); i++) for (var j = i + 1; j < array_length(wb_dice); j++) {
	var _a = wb_dice[i], _b = wb_dice[j];
	if (is_struct(_a.fly) || is_struct(_b.fly)) continue;
	var _dist = point_distance(_a.x, _a.y, _b.x, _b.y);
	if (_dist >= 66) continue;
	var _dir = (_dist < 0.5) ? random(360) : point_direction(_b.x, _b.y, _a.x, _a.y);
	var _push = (66 - _dist) * 0.25;
	var _a_held = is_struct(wb_held) && wb_held.ref == _a, _b_held = is_struct(wb_held) && wb_held.ref == _b;
	if (!_a_held) { _a.x += lengthdir_x(_push, _dir); _a.y += lengthdir_y(_push, _dir); }
	if (!_b_held) { _b.x -= lengthdir_x(_push, _dir); _b.y -= lengthdir_y(_push, _dir); }
}
for (var i = 0; i < array_length(wb_dice); i++) {
	var _d = wb_dice[i];
	if (is_struct(_d.fly) || (is_struct(wb_held) && wb_held.ref == _d)) continue;
	_d.x = clamp(_d.x, table.x1 + 50, table.x2 - 50);
	_d.y = clamp(_d.y, table.y1 + 50, table.y2 - 50);
	if (wb_near_bag(_d.x, _d.y)) _d.y = global.gui.bag_y - 70; // out of the bag's corner
}

// ---------------------------------------------------------------- the tools
for (var i = 0; i < array_length(wb_tools); i++) {
	var _t = wb_tools[i];
	var _held = is_struct(wb_held) && wb_held.ref == _t;
	if (_held) {
		// the grip comes under the mouse (from where it was grabbed), so the working point sits where the tool is held
		var _v = wb_tool_vec(_t.kind);
		wb_held.ox = lerp(wb_held.ox, wb_rot_x(_v.wx * wb_tool_k, _v.wy * wb_tool_k, _t.ang), 0.3);
		wb_held.oy = lerp(wb_held.oy, wb_rot_y(_v.wx * wb_tool_k, _v.wy * wb_tool_k, _t.ang), 0.3);
		_t.hx = _mx + wb_held.ox;
		_t.hy = _my + wb_held.oy;
		_t.lift = lerp(_t.lift, 1, 0.3);
	} else {
		_t.lift = lerp(_t.lift, 0, 0.2);
		if (_t.returning) {
			_t.hx = lerp(_t.hx, _t.home_x, 0.18);
			_t.hy = lerp(_t.hy, _t.home_y, 0.18);
			_t.ang = lerp(_t.ang, 0, 0.2);
			if (point_distance(_t.hx, _t.hy, _t.home_x, _t.home_y) < 2) {
				_t.hx = _t.home_x; _t.hy = _t.home_y; _t.ang = 0; _t.frame = 0;
				_t.returning = false;
				_t.wob = 0.6; // a little swing as it hangs back up
			}
		}
	}
	_t.wob *= 0.9;
}
var _ht = (is_struct(wb_held) && wb_held.kind == "tool") ? wb_held.ref : undefined;
wb_target = (_ht != undefined) ? wb_tool_target(_ht) : undefined;

// ---------------------------------------------------------------- picking up and putting down
if (_input && wb_held == undefined && mouse_check_button_pressed(mb_left)) {
	// a tool first (they hang over the table's edge), then the topmost die
	for (var i = array_length(wb_tools) - 1; i >= 0; i--) {
		var _t = wb_tools[i];
		var _b = wb_tool_box(_t);
		if (_mx < _b.x1 || _mx > _b.x2 || _my < _b.y1 || _my > _b.y2) continue;
		if (_t.used) {
			throw_error("Used", "Each tool works once per visit.");
		} else {
			wb_held = { kind: "tool", ref: _t, ox: _t.hx - _mx, oy: _t.hy - _my };
			_t.returning = false;
			sfx_play(soClick4, AUDIO_GROUP.UI, 0.05, 0.7);
		}
		break;
	}
	if (wb_held == undefined) {
		var _d = wb_die_at(_mx, _my, undefined, 42);
		if (_d != undefined && !is_struct(_d.fly)) {
			// to the top of the pile
			wb_remove_die(_d);
			array_push(wb_dice, _d);
			wb_held = { kind: "die", ref: _d, ox: _d.x - _mx, oy: _d.y - _my };
			sfx_play(soSlotHover, AUDIO_GROUP.UI, 0.05, 0.6);
		}
	}
}

// a tool in hand goes back on the rack with a right click
if (is_struct(wb_held) && wb_held.kind == "tool" && mouse_check_button_pressed(mb_right)) {
	wb_held.ref.returning = true;
	wb_held = undefined;
}

if (is_struct(wb_held) && !mouse_check_button(mb_left)) {
	var _h = wb_held;
	wb_held = undefined;
	if (_h.kind == "die") {
		var _d = _h.ref;
		var _gb = global.gui;
		if (_mx > _gb.bag_x - 20 && _mx < _gb.bag_x + _gb.bag_w + 20 && _my > _gb.bag_y - 20 && _my < _gb.bag_y + _gb.bag_h + 20) {
			// dropped on the bag: back in it
			wb_to_bag(_d);
			sfx_play(soClick4, AUDIO_GROUP.UI, 0.05, 0.7);
		} else {
			_d.x = clamp(_d.x, table.x1 + 50, table.x2 - 50);
			_d.y = clamp(_d.y, table.y1 + 50, table.y2 - 50);
			_d.scale = 1.3; // a squash as it lands
			particle_emit(_d.x, _d.y + 26, "burst", global.ui_col.paper_shade, 6);
			sfx_play(soSlotPlace, AUDIO_GROUP.SFX, 0.1, 0.5);
		}
	} else {
		var _t = _h.ref;
		var _tg = wb_tool_target(_t);
		var _job = undefined;
		switch (_t.kind) {
			case "drill":
				if (_tg.ok) _job = { kind: "drill", die: _tg.die };
				else if (_tg.die != undefined) { float_text(_t.hx, _t.hy - 80, _tg.text, c_white); _t.wob = 1; }
				break;
			case "hammer":
				if (_t.hx > rack.x1 - 20) break; // put back on the rack
				if (_tg.ok) _job = { kind: "hammer", pair: _tg.pair, die: undefined, text: "" };
				else if (_tg.pair != undefined) _job = { kind: "hammer_fail", pair: _tg.pair, die: undefined, text: _tg.text };
				else if (_t.hx > table.x1 && _t.hx < table.x2 && _t.hy > table.y1 && _t.hy < table.y2) _job = { kind: "miss", pair: undefined, die: wb_die_at(_t.hx, _t.hy, undefined, 70), text: "" };
				break;
			default:
				if (_tg.ok) _job = { kind: "cut", die: _tg.die };
				else if (_tg.die != undefined) { float_text(_t.hx, _t.hy - 80, _tg.text, c_white); _t.wob = 1; }
				break;
		}
		if (is_struct(_job)) {
			_job.tool = _t;
			_job.t = 0;
			_job.x0 = _t.hx;
			_job.y0 = _t.hy;
			wb_job = _job;
		} else _t.returning = true;
	}
}

// ---------------------------------------------------------------- a tool at work
if (is_struct(wb_job)) {
	var _j = wb_job;
	var _t = _j.tool;
	var _jt = _j.t;
	switch (_j.kind) {
		case "drill":
			// down onto the die, a long whirr with sparks, then the core sinks in
			var _d = _j.die;
			if (_jt < 12) {
				var _e = 1 - power(1 - _jt / 12, 3);
				_t.hx = lerp(_j.x0, _d.x, _e);
				_t.hy = lerp(_j.y0, _d.y - 36, _e);
			} else if (_jt < 18) {
				_t.hx = _d.x;
				_t.hy = lerp(_d.y - 36, _d.y - 6, (_jt - 12) / 6);
				if (_jt == 17) screen_shake(4);
			} else if (_jt < 62) {
				_t.hx = _d.x + random_range(-1.5, 1.5);
				_t.hy = _d.y - 6;
				if (_jt mod 2 == 0) _t.frame = (_t.frame + 1) mod max(1, sprite_get_number(_t.sprite));
				_d.rot = random_range(-6, 6);
				if (_jt mod 3 == 0) particle_emit(_d.x + random_range(-8, 8), _d.y - 6, "burst", choose(c_white, global.color_gold, global.ui_col.brass), 3);
				if (_jt mod 12 == 0) sfx_play(choose(soSmallRocks1, soSmallRocks2, soSmallRocks3, soSmallRocks4, soSmallRocks5), AUDIO_GROUP.SFX, 0.2, 0.35); // grit off the drill (until there's a drill sound)
				screen_shake(1.5);
			} else if (_jt == 62) {
				var _core = _t.core;
				var _nd = clone_die(_d.die, "");
				_nd.distribution = _core.distribution;
				_d.die = _nd;
				_d.rot = 0;
				_d.flash = 1;
				_d.scale = 1.5;
				particle_emit(_d.x, _d.y, "burst", global.color_gold, 30);
				particle_emit(_d.x, _d.y, "burst", c_white, 20);
				array_push(wb_rings, { x: _d.x, y: _d.y, col: global.color_gold, t: 0 });
				screen_shake(9);
				float_text(_d.x, _d.y - 80, string(_core.name), global.color_gold);
				sfx_play(soShieldLight1, AUDIO_GROUP.SFX, 0.1, 0.8);
				_t.core = undefined;
				_t.core_slot = -1;
				array_push(tools_used, oDrill); // the Drill works again, as long as you have cores (F237): it's never marked used
			} else {
				_t.hy -= 4; // lifts off
				_t.frame = 0;
				if (_jt >= 74) { _t.returning = true; wb_job = undefined; }
			}
			break;

		case "hammer":
		case "hammer_fail":
		case "miss":
			// a real swing, as the old hammer did (Jared, 2026-11-23): the head tips back to the right, then thwacks down
			// to the left, turning anticlockwise; the hit lands on the way down, the head on the gap (or where it was let go)
			var _hx = is_struct(_j.pair) ? _j.pair.mx : _j.x0, _hy = is_struct(_j.pair) ? _j.pair.my : _j.y0;
			var _ia = 65; // the angle at the hit: the head down to the left of the grip
			var _hv = wb_tool_vec("hammer");
			var _gx = _hx - wb_rot_x(_hv.wx * wb_tool_k, _hv.wy * wb_tool_k, _ia), _gy = _hy - wb_rot_y(_hv.wx * wb_tool_k, _hv.wy * wb_tool_k, _ia);
			if (_jt == 0) { var _g0 = wb_tool_grip(_t); _j.sgx = _g0.x; _j.sgy = _g0.y; _j.sa = _t.ang; }
			var _ang = _ia, _px = _gx, _py = _gy;
			if (_jt < 10) {
				var _e = 1 - power(1 - _jt / 10, 3);
				_ang = lerp(_j.sa, -22, _e);
				_px = lerp(_j.sgx, _gx, _e);
				_py = lerp(_j.sgy, _gy - 20, _e);
			} else if (_jt < 14) {
				var _e = power((_jt - 10) / 4, 3); // faster and faster
				_ang = lerp(-22, _ia, _e);
				_py = lerp(_gy - 20, _gy, _e);
			} else if (_jt > 14) {
				var _b = sin(min(1, (_jt - 14) / 10) * pi); // a little bounce off the table
				_ang = _ia - 12 * _b;
				_py = _gy - 16 * _b;
			}
			_t.ang = _ang;
			wb_tool_place(_t, _px, _py);
			if (_jt == 14 && _j.kind == "miss") {
				screen_shake(8);
				particle_emit(_hx, _hy + 10, "burst", make_color_rgb(138, 106, 68), 14);
				sfx_play(soShieldLight2, AUDIO_GROUP.SFX, 0.1, 0.8);
				if (is_struct(_j.die)) {
					_j.die.vy = 7; _j.die.hop = 0.1; _j.die.scale = 1.3;
					float_text(_hx, _hy - 90, "Needs two dice side by side.", c_white);
				} else array_push(wb_scuffs, { x: _hx, y: _hy + 10, r: 16, a: random(180), t: current_time });
			} else if (_jt == 14) {
				var _p = _j.pair;
				array_push(wb_scuffs, { x: _p.mx, y: _p.my + 12, r: 22, a: random(180), t: current_time });
				particle_emit(_p.mx, _p.my + 12, "burst", make_color_rgb(200, 166, 118), 30);
				particle_emit(_p.mx, _p.my + 12, "burst", make_color_rgb(138, 106, 68), 18);
				sfx_play(soShieldMedium, AUDIO_GROUP.SFX, 0.1, 1); // until there's a hammer sound
				sfx_play(choose(soSmallRocks1, soSmallRocks2, soSmallRocks3, soSmallRocks4, soSmallRocks5), AUDIO_GROUP.SFX, 0.1, 0.6); // the chips flying
				if (_j.kind == "hammer") {
					screen_shake(18);
					// the die with a core is the one that carries on (a core at random if both have one; Jared, 2026-11-22)
					var _base = _p.a.die, _other = _p.b.die;
					if (_base.distribution == "" && _other.distribution != "") { _base = _p.b.die; _other = _p.a.die; }
					var _nd = clone_die(_base, "");
					_nd.dice_value += _other.dice_value - 2; // a merge loses 2 sides (F236, Jared 2026-11-23: the Hammer was too strong)
					if (_base.distribution != "" && _other.distribution != "" && irandom(1) == 0) _nd.distribution = _other.distribution;
					die_size_changed(_nd); // a hammered coin is no longer a coin
					wb_remove_die(_p.a);
					wb_remove_die(_p.b);
					var _n = wb_add_die(_nd, _p.mx, _p.my);
					_n.scale = 0.3;
					_n.sv = 0.25; // springs up past full size
					_n.flash = 1;
					particle_emit(_p.mx, _p.my, "burst", get_dice_color(_nd.possible_type), 20);
					particle_emit(_p.mx, _p.my, "burst", c_white, 14);
					array_push(wb_rings, { x: _p.mx, y: _p.my, col: global.ui_col.paper_hi, t: 0 });
					float_text(_p.mx, _p.my - 90, "d" + string(_nd.dice_value), c_white);
					workbench_tool_used(oHammer);
				} else {
					screen_shake(12);
					var _jump = [_p.a, _p.b];
					for (var k = 0; k < 2; k++) {
						var _jd = _jump[k];
						_jd.vy = 8; _jd.hop = 0.1; _jd.scale = 1.3;
						_jd.vx = (_jd.x < _p.mx) ? -7 : 7;
					}
					float_text(_p.mx, _p.my - 90, _j.text, c_white);
				}
			}
			if (_jt >= 30) { _t.returning = true; wb_job = undefined; }
			break;

		case "cut":
			// over the die, a snip, and a coin hops out beside it
			var _d = _j.die;
			if (_jt < 10) {
				var _e = 1 - power(1 - _jt / 10, 3);
				_t.hx = lerp(_j.x0, _d.x, _e);
				_t.hy = lerp(_j.y0, _d.y, _e);
				_t.frame = 0;
			} else if (_jt < 14) {
				_t.hx = _d.x; _t.hy = _d.y;
			} else if (_jt == 14) {
				_t.frame = min(1, sprite_get_number(_t.sprite) - 1); // the blades shut
				screen_shake(7);
				var _v = _d.die.dice_value;
				var _nd = clone_die(_d.die, "");
				_nd.dice_value = _v - 2;
				die_size_changed(_nd); // cut down to a d2, it plays as a coin
				if (_nd.dice_value == 2) _nd.distribution = ""; // a coin has no core: it's lost (the hover says so)
				var _base = global.dice_d2_none;
				switch (_d.die.action_type) {
					case "ATK": _base = global.dice_d2_atk; break;
					case "BLK": _base = global.dice_d2_blk; break;
					case "INTEL": _base = global.dice_d2_intel; break;
					case "HEAL": _base = global.dice_d2_heal; break;
				}
				var _coin = clone_die(_base, "");
				_coin.dice_value = 2;
				_d.die = _nd;
				_d.scale = 1.4;
				_d.flash = 0.8;
				particle_emit(_d.x, _d.y, "burst", global.ui_col.paper_hi, 14);
				particle_emit(_d.x, _d.y, "burst", get_dice_color(_nd.possible_type), 10);
				var _side = (_d.x > table.x2 - 200) ? -1 : 1;
				var _c = wb_add_die(_coin, _d.x, _d.y);
				_c.scale = 0.5;
				_c.fly = { kind: "hop", sx: _d.x, sy: _d.y, tx: _d.x + _side * 120, ty: _d.y + 10, t: 0, dur: 26, arc: 90, spin: 360 * _side };
				float_text(_d.x, _d.y - 80, (_nd.dice_value == 2) ? "Coin" : "d" + string(_nd.dice_value), c_white);
				sfx_play(choose(soSwordLight1, soSwordLight2, soSwordLight3), AUDIO_GROUP.SFX, 0.15, 0.8); // until there's a snip sound
				workbench_tool_used(oScissors);
			} else {
				_t.hy -= 2;
				if (_jt >= 30) { _t.returning = true; wb_job = undefined; }
			}
			break;
	}
	if (is_struct(wb_job)) wb_job.t++;
}

// the hammer's marks on the table fade out over 3 s
for (var i = array_length(wb_scuffs) - 1; i >= 0; i--) if (current_time - wb_scuffs[i].t > 3000) array_delete(wb_scuffs, i, 1);

// the expanding rings from a craft
for (var i = array_length(wb_rings) - 1; i >= 0; i--) {
	wb_rings[i].t += 1 / (_fps * 0.5);
	if (wb_rings[i].t >= 1) array_delete(wb_rings, i, 1);
}

oRunManager.holding_item = is_struct(wb_held) || is_struct(wb_job);
