// Motion variables
x_speed = random_range(-1, 1);
y_speed = -irandom_range(2, 3);
grav = 0.3;

// Target
target_x = 310;
target_y = 35;

// Visuals
color_main = c_white;
scale = 0.5;

// State
life = 0;
phase = "float"; // phases: float -> attract -> done

alarm[0] = 1;