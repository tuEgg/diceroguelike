define_events();

chosen_event = undefined;

generate_event();
show_debug_message("Event pointer: " + string(chosen_event));

deleting_die = false;
delete_scale = 1.0;

options_scale = ds_list_create();
options_hover = ds_list_create();

repeat(ds_list_size(chosen_event.options)) ds_list_add(options_scale, 1.0);
repeat(ds_list_size(chosen_event.options)) ds_list_add(options_hover, false);

event_selected = false;
event_complete = -1;
chosen_option = -1;

exit_scale = 1.0;
exiting = false;