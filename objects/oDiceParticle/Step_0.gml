switch (phase) {
    case "float":
        // Basic upward float with gravity
        x += x_speed;
        y += y_speed;

        // Once we've started falling (y_speed > 5), begin homing
        if (y_speed > 2) {
            var dist = point_distance(x, y, target_x, target_y);
            var dir = point_direction(x, y, target_x, target_y);

            // --- Homing acceleration (speeds up as we get closer) ---
            var accel = clamp(0.5 + (300 / (dist + 1)), 0.5, 10);
            x_speed += lengthdir_x(accel, dir);
            y_speed += lengthdir_y(accel * 0.8, dir);

            // --- Apply movement ---
            x += x_speed;
            y += y_speed;

            // --- Visual fade/scale ---
            if (dist < 100) {
                scale = lerp(scale, 0.5, 0.1);
            }

            // --- Check if we've reached the discard button ---
            if (dist < 64 || y > target_y + 50) {
                phase = "done";
            }
        } else {
			y_speed += grav;
		}
        break;

    case "done":
        instance_destroy();
        break;
}


image_angle += y_speed;

image_index = get_dice_index(die_struct.dice_value);
image_blend = get_dice_color(die_struct.possible_type);

life++;