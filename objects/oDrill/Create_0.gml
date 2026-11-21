is_dragging = false;
hovered = false;
depth = -12;
first_selected = false; // used for preventing hammer smash first pick up
over_button = false;

drill_timer = 0;
drill_change_time_start = 8; // how many frames to change 
drill_change_time_min = 2; // how many frames to change 
drill_change_time = drill_change_time_start; // how many frames to change 
image_speed = 0;
image_index = 0;
tool_used = false; // crafted this visit (workbench_tool_used): greyed out, can't be picked up again
used_timer = 0;   // frames left in hand after crafting, so the last pose shows
grab_spin = 0;    // frames left of the little whirr when picked up (B135): it spins on the grab, without drilling
