// Motion variables
x_speed = random_range(-1, 1);
y_speed = -irandom_range(8, 10);
grav = 0.3;

// Target (set externally)
target_x = x;
target_y = y;

// Visuals
color_main = c_white;
scale = 5;

// State
life = 0;
phase = "float"; // phases: float -> attract -> done