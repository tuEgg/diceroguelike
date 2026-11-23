// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
// particle_emit( x, y, type, color, [amount])
function particle_emit( _x, _y, _type, _col, _amount = 30) {
	
	repeat(_amount) {
		var _index = irandom(3);
		
		var _color = make_color_rgb(
			clamp(color_get_red(_col) + random_range(-30, 30), 0, 255),
			clamp(color_get_green(_col) + random_range(-30, 30), 0, 255),
			clamp(color_get_blue(_col) + random_range(-30, 30), 0, 255)
		);
		
		var p = instance_create_depth(_x, _y, -200, oParticle);
		if (_type == "burst") {
			p.speed = random_range(9,12);
			p.direction = random(360);
			p.size = random_range(1, 1.5);
			p.life = 30;
		}
		
		if (_type == "ring") {
		    var _dir = random(360);
		    p.direction = _dir;
    
		    // Calculate a multiplier between 0 and 1 based on horizontal alignment
		    // abs(dcos(0))   = 1.0 (Full speed)
		    // abs(dcos(90))  = 0.0 (Min speed)
		    // abs(dcos(180)) = 1.0 (Full speed)
		    // abs(dcos(270)) = 0.0 (Min speed)
		    var _modifier = abs(dcos(_dir));
    
		    // Use lerp to ensure speed stays within a nice range (e.g., 4 to 12)
		    // When _modifier is 1, speed is 12. When 0, speed is 4.
		    p.speed = lerp(4, random_range(9, 12), _modifier);
    
		    p.size = random_range(1, 1.5);
		    p.life = 40;
		}
		
		if (_type == "rise") {
			p.x = _x + random_range(-30, 30);
			p.y = _y + random_range(-20, 20);
			p.speed = random_range(2, 3.5);
			p.direction = random_range(88, 92);
			p.size = random_range(0.75, 1.5);
			p.life = 60;
		}
		
		if (_type == "constant") {
			p.x = _x + random_range(-80, 80);
			p.y = _y + random_range(-80, 80);
			p.speed = random_range(0.5, 2);
			p.direction = random_range(70, 110);
			p.size = random_range(0.6, 1.2);
			p.life = 40;
		}
		
		p.spin = choose(-1, 0, 1); // 1 for rotate right, 0 for no rotation, -1 for rotate left
		p.fade = true;
		p.type = _type;
		p.image_blend = _color;
		p.image_index = _index;
		
		p.image_xscale = 1/10 * p.size;
		p.image_yscale = 1/10 * p.size;
	}
}

function gain_coins(_x, _y, _amount) {
	
	repeat (_amount) {
		
		var wait = instance_number(oParticleCoin);
		
		_x += random_range(-20, 20);
		_y += random_range(-20, 20);
		
		var c = instance_create_depth(_x, _y, -200, oParticleCoin);
		c.delay = min(wait, (wait / _amount) * (1.00 * game_get_speed(gamespeed_fps)));
		c.image_alpha = 0;
	}
}



/// @func alignment_colour(_alignment)
/// @desc The compass bar's colour at this alignment (0 ruthless to 100 merciful): purple, red, orange, yellow, green, teal,
///       read off the sAlignmentBar sprite.
function alignment_colour(_a) {
	var _stops = [
		[0,   make_color_rgb(140, 20, 110)],
		[22,  make_color_rgb(215, 35, 60)],
		[42,  make_color_rgb(245, 140, 30)],
		[55,  make_color_rgb(240, 215, 50)],
		[75,  make_color_rgb(95, 195, 85)],
		[100, make_color_rgb(25, 175, 205)],
	];
	_a = clamp(_a, 0, 100);
	for (var i = 0; i < array_length(_stops) - 1; i++) {
		var _s0 = _stops[i], _s1 = _stops[i + 1];
		if (_a <= _s1[0]) return merge_colour(_s0[1], _s1[1], (_a - _s0[0]) / (_s1[0] - _s0[0]));
	}
	return _stops[array_length(_stops) - 1][1];
}

/// @func alignment_target()
/// @desc Where the compass marker is on screen (oRunManager Draw GUI draws it): GUI coordinates, as a [x, y].
function alignment_target() {
	return [display_get_gui_width() - 530 - 112 + global.player_alignment * 2.24, (sprite_get_height(sTopBar) - 3) / 2];
}

/// @func gain_alignment(_amount, [_x], [_y])
/// @desc Moves the compass: one glowing mote per point bursts out from _x, _y (where you clicked, by default), each in
///       the compass bar's colour at the point it will land on, and streams up to the marker; each one moves it a step
///       as it lands (oParticleAlignment Destroy). A word under the compass says how far and which way.
function gain_alignment(_amount, _x = device_mouse_x_to_gui(0), _y = device_mouse_y_to_gui(0)) {
	var _num = abs(_amount);
	if (_num == 0) return;
	var _neg = _amount < 0 ? -1 : 1;
	var _fps = game_get_speed(gamespeed_fps);

	for (var i = 0; i < _num; i++) {
		var c = instance_create_depth(_x + random_range(-20, 20), _y + random_range(-20, 20), -200, oParticleAlignment);
		c.delay = floor(i * _fps * 0.05) + 1; // a quick ripple, one after another
		c.negative = _neg;
		c.order = i;
		c.col = alignment_colour(global.player_alignment + _neg * (i + 1));
	}

	// "+5 alignment" / "-7 alignment" under the compass (oRunManager Draw GUI)
	with (oRunManager) {
		alignment_popup_text = (_neg > 0 ? "+" : "-") + string(_num) + " alignment";
		alignment_popup_col = alignment_colour(_neg > 0 ? 90 : 5);
		alignment_popup_t = 0;
	}
}

/// @func particle_emit_later(_x, _y, _type, _col, [_amount])
/// @desc particle_emit, but made in oRunManager's Step (particles_flush): safe to call from Draw GUI, where making
///       instances made the web build skip a frame (B108). For juice fired from drawing code (potions, sacrifices).
function particle_emit_later(_x, _y, _type, _col, _amount = 30) {
	if (!variable_global_exists("particles_pending")) global.particles_pending = [];
	array_push(global.particles_pending, { x: _x, y: _y, type: _type, col: _col, amount: _amount });
}

/// @func particles_flush()
/// @desc oRunManager Step: makes the particles queued by particle_emit_later.
function particles_flush() {
	if (!variable_global_exists("particles_pending")) return;
	for (var i = 0; i < array_length(global.particles_pending); i++) {
		var _p = global.particles_pending[i];
		particle_emit(_p.x, _p.y, _p.type, _p.col, _p.amount);
	}
	global.particles_pending = [];
}

/// @func potion_burst(_x, _y)
/// @desc A potion used (F41): glass glints out, a coloured puff rises. Queued (it's called from Draw GUI).
function potion_burst(_x, _y) {
	particle_emit_later(_x, _y, "burst", make_color_rgb(226, 236, 240), 14);
	particle_emit_later(_x, _y, "rise", global.color_heal, 16);
	sfx_play(choose(soBubbles1, soBubbles2, soBubbles3), AUDIO_GROUP.SFX, 0.05, 0.9);
}
