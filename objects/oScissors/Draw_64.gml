draw_self();

var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();
	
//if (mouse_check_button(mb_left)) {
	
//	var x1 = x - 183;
//	var y1 = y - 423;
//	var x2 = x + 53;
//	var y2 = y - 160;
//	draw_set_color(c_black);
//	draw_set_alpha(0.5);
//	draw_rectangle(x1, y1, x2, y2, false);
//	draw_set_color(c_white);
//	draw_set_font(ftDefault);
//	draw_set_halign(fa_center);
//	draw_set_valign(fa_middle);
//	draw_text(x1 - 10, y1 - 10, "x: " + string(x1) + ", y: " + string(y1));
//	draw_text(x2 + 10, y2 + 10, "x: " + string(x2) + ", y: " + string(y2));
//	draw_text(mouse_x + 10, mouse_y + 10, "x: " + string(mouse_x) + ", y: " + string(mouse_y));
//}

//if (is_dragging) {	
//	draw_set_color(c_black);
//	draw_set_alpha(0.4);
//	draw_rectangle(gui_w/2 + 200, gui_h/2 + 280, gui_w/2 + 400, gui_h/2 + 280 + 122, false);
//}