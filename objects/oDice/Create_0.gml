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

// rolled dice, drawn in code in fights (draw_die): a tumble as it's dealt or rerolled, then a pop as it lands (Step)
tumbling = false;
tumble_angle = 0;
flick_face = 1;    // the face shown while it tumbles
flick_timer = 0;
roll_anim = 0;     // frames of tumbling still to go (deal, reroll)
land_pop = 0;      // 1 just after landing, back to 0
no_tumble = false; // taken back from a slot: it keeps its roll, so it doesn't tumble
over_discard = false; // being dragged over the discard pile (Step): it swells, wobbles and says what letting go does

alarm[0] = 1; // delay moving until we've defined create event