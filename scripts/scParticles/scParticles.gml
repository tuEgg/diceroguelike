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