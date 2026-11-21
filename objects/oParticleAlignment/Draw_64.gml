if (delay > 0) exit;

// the trail: fading, shrinking dots behind it
var _n = array_length(trail);
for (var i = 0; i < _n; i++) {
	var _f = (i + 1) / (_n + 1);
	draw_set_alpha(0.5 * _f);
	draw_set_color(col);
	draw_circle(trail[i][0], trail[i][1], size * (0.3 + 0.6 * _f), false);
}

// a soft glow, then the mote: its colour, a bright core, and a glint that turns
gpu_set_blendmode(bm_add);
draw_set_alpha(0.35);
draw_set_color(col);
draw_circle(x, y, size * 2.4, false);
draw_set_alpha(0.25);
draw_circle(x, y, size * 1.6, false);
gpu_set_blendmode(bm_normal);
draw_set_alpha(1);
draw_set_color(merge_colour(col, c_black, 0.35));
draw_circle(x, y, size + 1.5, false);
draw_set_color(col);
draw_circle(x, y, size, false);
draw_set_color(merge_colour(col, c_white, 0.7));
draw_circle(x - size * 0.25, y - size * 0.25, size * 0.4, false);
draw_set_color(c_white);
draw_line_width(x + lengthdir_x(size * 1.8, spin), y + lengthdir_y(size * 1.8, spin), x - lengthdir_x(size * 1.8, spin), y - lengthdir_y(size * 1.8, spin), 1.5);
draw_set_alpha(1);
