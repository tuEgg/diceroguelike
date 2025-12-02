dice_amount = 1;
dice_value = 4;
action_type = "None";
struct = "";
image_speed = 0;
has_rolled = false;
can_discard = true;

// Hover animation settings
scale = 1.0;
hover_target = 1.0;

hover_speed = 0.2; // how fast it lerps
hover_scale = 1.3; // how big it grows on hover

// Dragging logic
is_dragging = false;
drag_offset_x = 0;
drag_offset_y = 0;

// Return / snapping logic
snap_speed = 0.1;

// if in a workbench slot
in_slot = false;
still = false; // used in creation of workbench made dice

alarm[0] = 1; // delay moving until we've defined create event