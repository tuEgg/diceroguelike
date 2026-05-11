// Motion variables
x_speed = random_range(-1, 1);
y_speed = -irandom_range(2, 3);
grav = 0.3;

// Target
target_x = 1480 - 112 + (global.player_alignment * 2.24);
target_y = 50;

// Visuals
color_main = c_white;
scale = 0.5;

// State
life = 0;
phase = "float"; // phases: float -> attract -> done

alarm[0] = 1;

image_xscale = random_range(1.0, 1.3);
image_yscale = image_xscale;