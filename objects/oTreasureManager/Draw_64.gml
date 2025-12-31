var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);
	
// Show treasure chest
var chest_w = sprite_get_width(sChest);
var chest_h = sprite_get_height(sChest);
var chest_x = gui_w/2;
var chest_y = gui_h/2 + 200;
var chest_hover = mouse_hovering(chest_x, chest_y, chest_w, chest_h, true);

if (chest_hover) {
	chest_scale = lerp(chest_scale, 1.1, 0.2);
	if (mouse_check_button_pressed(mb_left)) {
		chest_open = true;
	}
} else {
	chest_scale = lerp(chest_scale, 1.0, 0.2);
}

// Draw chest
draw_sprite_ext(sChest, chest_open, chest_x, chest_y, 1, 1, 0, c_white, 1.0);

var min_val = 0.7;
var max_val = 1.0;
var spd   = 0.002;

var mid = (min_val + max_val) * 0.5;
var amp = (max_val - min_val) * 0.5;

var value = mid + sin(current_time * spd) * amp;

// Draw chest glow
if (chest_open) {
	draw_sprite_ext(sChestGlow, 0, chest_x, chest_y - 140, 1, 1, 0, c_white, value);
	
	var pos = value * 50;
	
	if (keepsake_reward[| 0] != undefined) {
		draw_sprite_ext(sKeepsake, keepsake_reward[| 0].sub_image, chest_x, chest_y - 300 + pos, 1.5, 1.5, 0, c_white, 1.0); 
	
		var hover_keepsake = mouse_hovering(chest_x, chest_y - 300 + pos/2, 110, 110, true);
	
		if (hover_keepsake) {
			queue_tooltip(mouse_x, mouse_y, keepsake_reward[| 0].name, keepsake_reward[| 0].desc);
		
			if (mouse_check_button_pressed(mb_left)) {
				ds_list_add(oRunManager.keepsakes, keepsake_reward[| 0]);
			
				keepsake_reward[| 0] = undefined;
			}
		}
	}
}

// Draw exit button
draw_set_font(ftBigger);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
	
var exit_col = c_red;

var hover_exit = mouse_hovering(gui_w - 150, gui_h - 200, exit_scale*sprite_get_width(sButtonSmall)*0.75, exit_scale*sprite_get_height(sButtonSmall)*0.75, true);

if (hover_exit && !oRunManager.is_dealing_dice && exit_col == c_red && !oRunManager.holding_item) {
	if (mouse_check_button_pressed(mb_left)) {
		room_goto(rmMap);
	}
	exit_scale = lerp(exit_scale, 1.2, 0.2);
} else {
	exit_scale = lerp(exit_scale, 1.0, 0.2);
}

draw_sprite_ext(sButtonSmall, 0, gui_w - 150, gui_h - 200, exit_scale*0.75, exit_scale*0.75, 0, exit_col, 1.0);
draw_outline_text("Exit", c_black, c_white, 2, gui_w - 150, gui_h - 200, 1, 1, 0);