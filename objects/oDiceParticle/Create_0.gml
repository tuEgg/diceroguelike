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

// set once here: changing depth inside a draw event re-sorts the draw list mid-frame (a likely cause of the
// black flash when taking a reward die, B102). -10 in a fight (above the dice), -13 elsewhere (above the workbench).
depth = (room == rmCombat) ? -10 : -13;
