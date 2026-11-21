// Motion variables
x_speed = random_range(-1, 1);
y_speed = -irandom_range(2, 3);
grav = 0.3;

// Target
target_x = variable_global_exists("gold_pos") ? global.gold_pos : 310; // the gold in the top bar
target_y = 35;

// Visuals
color_main = c_white;
scale = 0.5;

// State
life = 0;
phase = "float"; // phases: float -> attract -> done

alarm[0] = 1;