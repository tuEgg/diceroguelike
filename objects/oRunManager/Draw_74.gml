// Draw GUI Begin: the log's ink look (F118). While the log is open in a fight, this frame's whole screen (the room as
// drawn, then every Draw GUI event) goes into ink_scene instead of straight to the screen. Draw GUI End (Draw_75)
// resets the target first thing, and combat_insight_view_draw draws ink_scene back through shInk.
ink_capturing = false;
if (room == rmCombat && instance_exists(oCombat) && oCombat.insight_view && shader_is_compiled(shInk)) {
	var _gw = display_get_gui_width(), _gh = display_get_gui_height();
	if (!surface_exists(ink_scene) || surface_get_width(ink_scene) != _gw || surface_get_height(ink_scene) != _gh) {
		if (surface_exists(ink_scene)) surface_free(ink_scene);
		ink_scene = surface_create(_gw, _gh);
	}
	surface_set_target(ink_scene);
	draw_clear(c_black);
	if (surface_exists(application_surface)) draw_surface_stretched(application_surface, 0, 0, _gw, _gh);
	ink_capturing = true;
}
