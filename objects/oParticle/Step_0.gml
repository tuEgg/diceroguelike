life--;

depth = -100;

if (life <= 0) {
	instance_destroy();
}

if (life < 30) {
	if (fade) {
		image_alpha = clamp(life / 20, 0, 1);
		if (image_alpha < 1) {
			image_xscale *= 0.94;
			image_yscale *= 0.94;
		}
	}
}

image_angle += spin;

if (type == "burst") {
	speed *= 0.91;
}

if (type == "rise") {
	speed *= 1.03;
}