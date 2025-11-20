// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function trace() {
	/// trace(...values)
	var r = string(argument[0]), i;
	for (i = 1; i < argument_count; i++) {
	    r += ", " + string(argument[i]);
	}
	show_debug_message(r);
}