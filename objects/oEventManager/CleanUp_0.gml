if (ds_exists(global.master_event_list, ds_type_list)) {
	ds_list_destroy(global.master_event_list);
	global.master_event_list = undefined;
}
if (ds_exists(options_scale, ds_type_list)) ds_list_destroy(options_scale);
if (ds_exists(options_hover, ds_type_list)) ds_list_destroy(options_hover);