var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);
	
// Show treasure chest
var chest_w = sprite_get_width(sChest);
var chest_h = sprite_get_height(sChest);
var chest_x = gui_w/2;
var chest_y = gui_h/2 + 200;
var chest_hover = mouse_hovering(chest_x, chest_y - 130, chest_w, chest_h, true);

if (chest_hover) {
	chest_scale = lerp(chest_scale, 1.1, 0.2);
	if (mouse_check_button_pressed(mb_left) && !chest_open) {
		chest_open = true;
	}
} else {
	chest_scale = lerp(chest_scale, 1.0, 0.2);
}

if (mouse_check_button_released(mb_left)) can_click = true

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
	draw_sprite_ext(sChestGlow, 0, chest_x, chest_y - 140, 1 + value/2, 1 + value/2, 0, c_white, value);
	draw_sprite_ext(sChestGlow, 0, chest_x, chest_y - 140, 0.8 + value/3, 0.8 + value/3, 0, c_white, value + 0.2);
	draw_sprite_ext(sChestGlow, 0, chest_x, chest_y - 140, 0.6 + value/4, 0.6 + value/4, 0, c_white, value + 0.4);
	
	var pos = value * 50 + keepsake_y;
	
	keepsake_y = lerp(keepsake_y, 0, 0.07);
	keepsake_alpha = lerp(keepsake_alpha, 1.0, 0.07);
	
	if (keepsake_reward[| 0] != undefined) {
		draw_sprite_ext(sKeepsake, keepsake_reward[| 0].sub_image, chest_x, chest_y - 300 + pos, 1.5, 1.5, 0, c_white, keepsake_alpha); 
	
		var hover_keepsake = mouse_hovering(chest_x, chest_y - 300 + pos/2, 110, 110, true);
	
		if (hover_keepsake) {
			queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), keepsake_reward[| 0].name, keepsake_reward[| 0].desc);
		
			if (mouse_check_button_pressed(mb_left) && keepsake_alpha > 0.8) {
				gain_keepsake(keepsake_reward[| 0], global.rollable_keepsake_list);
			
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

// the room's commit action, bottom right (ui_primary, UI rework)
// leaving with the treasure still there asks first (B136): the first click turns it into "Leave it?" for a few seconds
var _untaken = !chest_open || keepsake_reward[| 0] != undefined;
if (exit_confirm > 0) exit_confirm--;
var _asking = _untaken && exit_confirm > 0;
var exit_btn = ui_primary(gui_w - 44 - 140, gui_h - 40 - 48, 280, 96, _asking ? "Leave it?" : "Continue", !oRunManager.is_dealing_dice && !oRunManager.holding_item, "", UI_LAYER.BASE, 1, _asking ? global.ui_col.danger : undefined);
if (_asking) {
	draw_set_font(ftDefault);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_outline_text(chest_open ? "The keepsake stays behind." : "The chest is still closed.", c_black, c_white, 2, gui_w - 44 - 140, gui_h - 40 - 48 - 72, 1, 1, 0);
}
if (exit_btn.click) {
	if (_untaken && exit_confirm <= 0) exit_confirm = round(game_get_speed(gamespeed_fps) * 3);
	else room_goto(rmMap);
}