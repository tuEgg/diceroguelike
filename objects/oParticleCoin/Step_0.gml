if (delay == 0) {
	switch (phase) {
	    case "float":
	        // Basic upward float with gravity
	        x += x_speed;
	        y += y_speed;

	        // Once we've started falling (y_speed > 5), begin homing
	        var dist = point_distance(x, y, target_x, target_y);
	        var dir = point_direction(x, y, target_x, target_y);

	        // --- Homing acceleration (speeds up as we get closer) ---
			var accel = clamp(0.5 + (300 / (dist + 1)), 0.5, 20);
			x_speed += lengthdir_x(accel, dir);
			y_speed += lengthdir_y(accel, dir);
		
			var spd = point_distance(0, 0, x_speed, y_speed);
			if (spd > 14) { // tweak this
			    var s = 14 / spd;
			    x_speed *= s;
			    y_speed *= s;
			}

	        // --- Apply movement ---
	        x += x_speed;
	        y += y_speed;

	        // --- Visual fade/scale ---
	        if (dist < 100) {
	            scale = lerp(scale, 0.5, 0.1);
	        }

	        // --- Check if we've reached the credits button ---
	        if (dist < 14) {
	            phase = "done";
	        }
	       break;

	    case "done":
	        instance_destroy();
	    break;
	}


	image_angle += y_speed;

	life++;
}