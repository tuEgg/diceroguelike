gui_w = display_get_gui_width();
gui_h = display_get_gui_height();

var bar_height = sprite_get_height(sTopBar) - 3;
var bar_half = bar_height/2;

// New run offering: the quartermaster's offer (offering_draw, scHelpers)
if (new_run_offering) offering_draw();

// Draw top bar
var bar_scale_w = global.ui_scale;
draw_sprite_ext(sTopBar, 1, -3*bar_scale_w, -4, bar_scale_w, 1, 0, c_white, 1);
// with the bag open, the top bar can still be hovered for its tooltips (mouse_hovering_check); its clicks are
// guarded by the base layer, so nothing in it can be used until the bag closes
global.ui_peek_top_bar = (global.ui_layer == UI_LAYER.BAG);

// Draw voyage act
draw_set_font(ftBig);
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
var act = "I";
switch (voyage) {
	case 1:
	act = "II";
	break;
	case 2:
	act = "III";
	break;
	case 3:
	act = "IV";
	break;
}
draw_outline_text("Voyage " + act, c_black, c_white, 2, 20, bar_half, 1, 1, 0);
var voyage_hover = mouse_hovering(20, bar_half, string_width("Voyage III"), string_height("Voyage III"), false, noone, noone);
if (voyage_hover) queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Voyages Sailed", "You are on voyage " + string(act) + "/III", undefined, 0, undefined);

// Draw pages turned
draw_set_font(ftBig);
draw_set_halign(fa_center);
draw_set_valign(fa_top);
var pages_x = 190;
draw_sprite_ext(sPaper, 0, pages_x, bar_half, 0.8, 0.8, 0, c_white, 1.0);
draw_outline_text(string(oWorldManager.nodes_cleared), c_black, c_white, 2, pages_x + 20, bar_half, 1, 1, 0);
var pages_hover = mouse_hovering(pages_x, bar_half, sprite_get_width(sPaper), sprite_get_height(sPaper), true, noone, noone);
if (pages_hover) queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Events Explored", "You have explored " + string(oWorldManager.nodes_cleared) + " events from the Captain's logbook", undefined, 0, undefined);

// Draw money
draw_set_font(ftBig);
var nodes_x = pages_x + 80;
draw_sprite_ext(sCoin, 1, nodes_x, bar_half, credits_scale * 0.8, credits_scale * 0.8, 0, c_white, 1.0);
draw_outline_text(string(credits), c_black, c_white, 2, nodes_x + 20, bar_half, 1, 1, 0);
var credits_hover = mouse_hovering(nodes_x, bar_half, sprite_get_width(sPaper), sprite_get_height(sPaper), true);
if (credits_hover) queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Gold Doubloons", "You have " + string(credits) + " gold doubloons", undefined, 0, undefined);
credits_scale = lerp(credits_scale, 1.0, 0.05);

// Draw health
var health_x = nodes_x + 100;
global.heal_pos = health_x;
draw_sprite(sHeart, 0, health_x, bar_half);
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_set_font(ftBig);
draw_outline_text(string(global.player_hp) + "/" +string(global.player_max_hp), c_black, c_white, 2, health_x + 30, bar_half, 1, 1, 0);
health_scale = lerp(health_scale, 1.0, 0.2);
var health_hover = mouse_hovering(health_x + 55, bar_half, 135, 50, true, noone, noone);
if (health_hover) queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Your Health", "You have " + string(global.player_hp) + "/" +string(global.player_max_hp) + " health");

// Draw cores and consumables
var core_x = health_x + 185;
var core_y = bar_half;

for (var i = 0; i < array_length(items); i++) {
	var i_x = i * 80;
	var sprite_x;
	var sprite_y;
	
	if (items[i] != undefined) {
		if (items[i].dragging) {
			sprite_x = device_mouse_x_to_gui(0);
			sprite_y = device_mouse_y_to_gui(0);
		} else {
			sprite_x = core_x + i_x;
			sprite_y = core_y;
		}
	}
	
	draw_sprite_ext(sTopBarSlot, 0, core_x + i_x, core_y, 0.8, 0.8, 0, c_white, 1.0);
	
	if (items[i] != undefined) {
		var default_scale = 0.8;
		var default_angle = 0;
		
		if (items[i].type == "consumable") {
			default_scale = 0.9;
			default_angle = -30;
		}
		
		// a carried item is drawn in Draw GUI End (dragged_item_draw), above the workbench slots and every window
		if (!items[i].dragging) draw_sprite_ext(items[i].sprite, items[i].index, sprite_x, sprite_y, items_hover_scale[i], items_hover_scale[i], default_angle, c_white, 1.0);
		
		//draw_outline_text(items[i].quantity, c_black, c_white, 2, core_x + 70 + 5 + i_x, 25, 1, 1, 0);
		
		items_hover[i] = mouse_hovering(core_x + i_x, core_y, sprite_get_width(sTopBarSlot), sprite_get_height(sTopBarSlot), true);
		
		items_hover_scale[i] = lerp(items_hover_scale[i], items_hover[i] ? default_scale * 1.2 : default_scale, 0.2);
		
		if (items_hover[i]) {
			var die = undefined;
			if (string_pos("Core", items[i].name) > 0) {
				die = core_preview_die();
				die.distribution = items[i].distribution;
			}
			// a potion says how it's used (F24: testers didn't know)
			var _how = "";
			if (items[i].type == "consumable" && is_struct(items[i].effects) && variable_struct_exists(items[i].effects, "trigger")) {
				if (items[i].effects.trigger == "on_item_played_to_slot") _how = " [subtext]Drag it onto a slot in a fight to use it.";
				else if (items[i].effects.trigger == "on_clicked") _how = " [subtext]Click it to use it.";
			}
			queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), items[i].name, items[i].description + _how, undefined, 0, die);
		}
		
		if (global.ui_layer == UI_LAYER.BASE) {
			if (items_hover[i] && mouse_check_button(mb_left)) {
				items[i].show_item_delete_confirmation = false;
			}

			if (items_hover[i] && mouse_check_button_pressed(mb_right)) {
				items[i].show_item_delete_confirmation = 1 - items[i].show_item_delete_confirmation;
			}
				
			if (items[i].show_item_delete_confirmation) {
				var padding = 15;
				
				draw_set_font(ftDefault);
				var _width = string_width_ext("Delete this item?", -1, 140) + (padding*2);
				var _height = string_height_ext("Delete this item?", font_get_size(draw_get_font()) * 1.5, 140) + (padding*1.5);
				
				var xx = sprite_x - _width - 30;
				var yy = sprite_y + 30;
				
				draw_set_alpha(0.8);
			    draw_set_color(c_black);
			    draw_roundrect(xx - 2, yy - 2, xx + _width + 2, yy + _height + 2, false);
			    draw_set_color(global.color_bg);
			    draw_roundrect(xx, yy, xx + _width, yy + _height, false);
			    draw_set_alpha(1);
				
				draw_set_font(ftDefault);
				draw_set_halign(fa_left);
				draw_set_valign(fa_top);
				draw_outline_text("Delete this item?", c_black, c_white, 2, xx + padding, yy + padding, 1, 1, 0, _width - (padding*2));
				
				var btn_x = xx + _width;
				var btn_y = yy + _height;
				
				var confirm_hover = mouse_hovering(btn_x, btn_y, _width, _height, true);
				
				items[i].item_delete_confirmation_scale = lerp(items[i].item_delete_confirmation_scale, confirm_hover ? 1.2 : 1.0, 0.2);
				
				if (!items_hover[i] && !confirm_hover) {
					if (mouse_check_button_pressed(mb_left) || mouse_check_button_pressed(mb_right)) {
						items[i].show_item_delete_confirmation = false;
					}
				}
				
				draw_sprite_ext(sButtonSmall, 0, btn_x, btn_y, items[i].item_delete_confirmation_scale * 0.5, items[i].item_delete_confirmation_scale * 0.5, 0, c_white, 1.0);
				draw_sprite_ext(sButtonSmall, 0, btn_x, btn_y, items[i].item_delete_confirmation_progress/30, items[i].item_delete_confirmation_scale * 0.5, 0, c_red, 1.0);
				draw_set_font(ftDefault);
				draw_set_halign(fa_center);
				draw_set_valign(fa_middle);
				draw_outline_text("Delete", c_black, c_white, 2, btn_x, btn_y, items[i].item_delete_confirmation_scale, 1, 0);
				
				if (confirm_hover && mouse_check_button(mb_left)) {
					items[i].item_delete_confirmation_progress++;
				} else {
					items[i].item_delete_confirmation_progress = 0;
				}
				
				if (items[i].item_delete_confirmation_progress >= game_get_speed(gamespeed_fps) * 0.3) {
					items[i] = undefined;
					holding_item = false;
				}
			}
			
			// Add core dragging functionality
			// (the item may have just been deleted above)
			if (room == rmWorkbench && items[i] != undefined) {
				if (items[i].type == "core") {
					// drag the core
					if (items_hover[i] && mouse_check_button(mb_left)) {
						items[i].dragging = true;
					}
					// release the core: over the workbench's middle slot it goes in (handled here, so it works
					// whichever of this and the workbench draws first)
					if (items[i].dragging and mouse_check_button_released(mb_left)) {
						items[i].dragging = false;
						if (instance_exists(oWorkbenchManager) && oWorkbenchManager.workbench_take_core(items[i], i)) items[i] = undefined;
					}
				}
			}
		
			if (items[i] != undefined) {
				// Add potion dragging functionality
				if (items[i].type == "consumable") {

					if (items_hover[i] && mouse_check_button(mb_left) && !holding_item) {
						items[i].dragging = true;
						holding_item = true;
					}

					if (items[i].dragging and mouse_check_button_released(mb_left)) {
						items[i].dragging = false;
						holding_item = false;
						// a potion that goes on a slot: used if it was let go over one
						if (combat_item_drop(items[i])) items[i] = undefined;
					}
			
					// (the potion may have just been used on a slot above, leaving the item slot empty)
					if (items[i] != undefined && items[i].dragging && mouse_check_button_pressed(mb_left)) {
						if (items[i].effects.trigger == "on_clicked" && items[i].effects.flags() ) {
							var ctx = {
								use_potion: true,
							};
						
							trigger_item_effects(items[i], "on_clicked", ctx);
							combat_trigger_effects("on_consumable_used", ctx);
						
							if (ctx.use_potion) {
								items[i] = undefined;
								holding_item = false;
							}
						}
					}
				}
			}
		}
	}
}

// Draw tools
if (room == rmWorkbench) show_tools = true;
var num_tools = string(ds_list_size(tools));

var toolbar_hover = mouse_hovering(gui_w - 940, bar_half, sprite_get_width(sToolbag) + 10, bar_height, true);
if (toolbar_hover) {
	if (mouse_check_button_pressed(mb_left) && global.ui_layer == UI_LAYER.BASE) {
		show_tools = 1 - show_tools;
	}
	if (room == rmMap) {
		if (can_visit_workbench) {
			queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Toolbag", "Tools used to manipulate your dice at the workbench.");
		} else {
			queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Toolbag", "Tools for the workbench. You can stop there at sea, each time you finish a page.");
		}
	} else {
		queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Toolbag", "Tools used to manipulate your dice at the workbench.");
	}
}

toolbag_scale = lerp(toolbag_scale, toolbar_hover ? 1.2 : 1.0, 0.1);

draw_set_font(ftBig);
var tools_x = gui_w - 940; // (moved 80 px left for the menu cog)

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_outline_text(num_tools, c_black, c_white, 2, tools_x, bar_half - 20, toolbag_scale, 1.0, 0);

draw_sprite_ext(sToolbag, 0, tools_x, bar_half + 10, toolbag_scale, toolbag_scale, 0, c_white, 1.0);

if (show_tools) {
	for (var i = 0; i < ds_list_size(tools); i++) {
		var tool = tools[| i];
		var tile_width = sprite_get_width(sToolButton) + 10;
		var starting_offset = (ds_list_size(tools)-1)/2 * tile_width; // 1 tool, offset by 0, 2 tools, offset by 0.5, 3 tools offset by 1,
		var tool_x = tools_x - starting_offset + (tile_width*i);
		
		var tool_hover = mouse_hovering(tool_x, 130, tile_width - 10, tile_width - 10, true);
		
		tools_scale[| i] = lerp(tools_scale[| i], tool_hover ? 1.2 : 1.0, 0.2);
		
		draw_sprite_ext(sToolButton, 0, tool_x, 130, tools_scale[| i], tools_scale[| i], 0, c_gray, 1.0);
		draw_sprite_ext(sToolSilhouettes, tool.index, tool_x, 130, tools_scale[| i], tools_scale[| i], 0, c_gray, 1.0);
		
		if (tool_hover) {
			queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), tool.name, tool.desc);

			if (mouse_check_button_pressed(mb_left) && global.ui_layer == UI_LAYER.BASE) {
				if (room == rmWorkbench) {
					if (instance_exists(oWorkbenchManager) && array_contains(oWorkbenchManager.tools_used, tool.object)) {
						throw_error("Used this visit", "Each tool works once per visit to the workbench.");
					} else if (!instance_exists(tool.object)) {
						var pos_x;
						var pos_y;
				
						switch(i) {
							case 0:
							pos_x = gui_w - 150;
							pos_y = gui_h/2 + 50;
							break;
					
							case 1:
							pos_x = 150;
							pos_y = gui_h/2 + 50;
							break;
					
							case 2:
							pos_x = gui_w - 300;
							pos_y = gui_h - 200;
							break;
						}
						instance_create_layer(pos_x, pos_y, "Instances", tool.object);
					} else {
						throw_error("Tool already exists", "This tool is already on the workbench");
					}
				} else {
					throw_error("Open at the workbench", "You can't open the toolbag outside of the workbench");
				}
			}
		}
	}
} else {
	if (tools_scale[| 0] > 0.5) {
		for (var i = 0; i < ds_list_size(tools); i++) {
			tools_scale[| i] = 0.5;
		}
	}
}

// Draw alignment
var alignment_color = make_color_rgb(250, 166, 20);
var alignment_x = gui_w - 530; // (moved 80 px left for the menu cog)

var alignment_hover = mouse_hovering(alignment_x - 25, bar_half, sprite_get_width(sAlignmentBar) + 50, sprite_get_height(sAlignmentBar), true, noone, noone);
draw_sprite_ext(sMapIcon, 8, alignment_x - 170, bar_half, 1, 1, 0, c_white, 1.0);
draw_sprite_ext(sAlignmentBar, 0, alignment_x, bar_half, alignment_scale, alignment_scale, 0, c_white, 1.0);
alignment_scale = lerp(alignment_scale, 1.0, 0.2);

var alignment_pos_x = alignment_x - 112 + ((global.player_alignment) * 2.24);
draw_sprite_ext(sCircleSmall, 0, alignment_pos_x, bar_half + 2, alignment_scale, alignment_scale, 0, c_white, 1.0); // swells as motes land

// "+5 merciful" / "-7 ruthless" under the compass for a moment after it moves (gain_alignment)
if (alignment_popup_t >= 0) {
	alignment_popup_t++;
	var _pa = clamp(2 - alignment_popup_t / (game_get_speed(gamespeed_fps) * 1.5), 0, 1); // holds, then fades over ~1.5s
	if (_pa <= 0) alignment_popup_t = -1;
	else {
		draw_set_font(ftDefault);
		draw_set_halign(fa_center);
		draw_set_valign(fa_top);
		draw_outline_text(alignment_popup_text, c_black, alignment_popup_col, 2, alignment_x, bar_half + 26 + min(alignment_popup_t, 10), 1, _pa, 0);
	}
}

var alignment_text = "Neutral";
var alignment_description = "Actions have consequences, make decisions that change how the sea interacts with you.";

if (global.player_alignment >= 0 && global.player_alignment < 10) {
	alignment_text = "Eldritch Horror";
	global.alignment_stage = 0;
} else if (global.player_alignment >= 10 && global.player_alignment < 25) {
	alignment_text = "Darkest Captain";
	global.alignment_stage = 1;
} else if (global.player_alignment >= 25 && global.player_alignment < 40) {
	alignment_text = "Cursed Sailor";
	global.alignment_stage = 2;
} else if (global.player_alignment >= 40 && global.player_alignment < 60) {
	alignment_text = "Neutral";
	global.alignment_stage = 3;
} else if (global.player_alignment >= 60 && global.player_alignment < 75) {
	alignment_text = "Honest Captain";
	global.alignment_stage = 4;
} else if (global.player_alignment >= 75 && global.player_alignment < 90) {
	alignment_text = "Sea Nobility";
	global.alignment_stage = 5;
} else if (global.player_alignment >= 90 && global.player_alignment <= 100) {
	alignment_text = "Seafaring Light & Justice";
	global.alignment_stage = 6;
}

if (alignment_hover) {
	queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Alignment: " + alignment_text, alignment_description);
}

// Draw bounty information
draw_sprite_ext(sMapIcon, 5, gui_w - 330, 45, 1, 1, 0, c_white, 1.0); // (moved 80 px left for the menu cog)

draw_set_font(ftBig);
var bounty_name = "-";
var bounty_description = "You aren't hunting any bounties";
var bounty_col = c_dkgray;
if (active_bounty != undefined) {
	bounty_name = active_bounty.enemy_name;
	bounty_description =  "Defeat " + string(active_bounty.enemy_name) + " " +active_bounty.condition.description;
	bounty_col = c_white;
	if (active_bounty.condition.failed) {
		bounty_description = "Bounty failed.";
		bounty_col = c_red;
	}
	if (active_bounty.complete) {
		bounty_name = active_bounty.enemy_name;
		bounty_description =  "Bounty completed.";
		bounty_col = c_lime;
	}
}
draw_set_halign(fa_left);
draw_set_valign(fa_middle);
draw_outline_text(bounty_name, c_black, bounty_col, 2, gui_w - 330 + 30, 44, 1, 1, 0);

var bounty_hover = mouse_hovering(gui_w - 360, 20, 270, 50, false, noone, noone); 
if (bounty_hover) {
	queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Active Bounty: " + bounty_name, bounty_description);
}

// Keep scale list synced with keepsake size
if (ds_list_size(keepsake_scale) < ds_list_size(keepsakes)) {
    repeat(ds_list_size(keepsakes) - ds_list_size(keepsake_scale)) ds_list_add(keepsake_scale, 4.0);
} else if (ds_list_size(keepsake_scale) > ds_list_size(keepsakes)) {
    repeat(ds_list_size(keepsake_scale) - ds_list_size(keepsakes)) ds_list_delete(keepsake_scale, ds_list_size(keepsake_scale) - 1);
}

// Keep scale list synced with tools size
if (ds_list_size(tools_scale) < ds_list_size(tools)) {
    repeat(ds_list_size(tools) - ds_list_size(tools_scale)) ds_list_add(tools_scale, 0.5);
} else if (ds_list_size(tools_scale) > ds_list_size(tools)) {
    repeat(ds_list_size(tools_scale) - ds_list_size(tools)) ds_list_delete(tools_scale, ds_list_size(tools_scale) - 1);
}

// Draw keepsakes
var ks_x = 15;

for (var k = 0; k < ds_list_size(keepsakes); k++) {
	var xx = (k mod 31) * 60;
	var ks_y = bar_height + 10 + ((k div 31) * 60);
	var _keepsake = keepsakes[| k];
	var btn_size = 64;
	var btn = draw_gui_button(ks_x + xx, ks_y, btn_size, btn_size, keepsake_scale[| k], "", c_white, ftSmall, 1, false);
	keepsake_scale[| k] = btn.scale;
	draw_sprite_ext(sKeepsake, _keepsake.sub_image, ks_x + xx + btn_size/2, ks_y + btn_size/2, keepsake_scale[| k] * 0.8, keepsake_scale[| k] * 0.8, 0, c_white, 1);

	// just fired: its name floats up from under its icon and fades (F15), so you can tell which keepsake did something
	if (variable_struct_exists(_keepsake, "flash_time")) {
		var _ft = (current_time - _keepsake.flash_time) / 1100;
		if (_ft >= 0 && _ft < 1) {
			draw_set_font(ftDefault);
			draw_set_halign(fa_left); // left-aligned under the icon so names in the first column stay on screen
			draw_set_valign(fa_top);
			draw_outline_text(_keepsake.name + "!", c_black, global.color_intel, 2, ks_x + xx + 4, ks_y + btn_size + 4 - 14 * _ft, 1, 1 - _ft * _ft, 0);
		}
	}
	
	if (btn.hover) {
		queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), keepsakes[| k].name, keepsakes[| k].desc, undefined, 0, undefined);
	}
}

var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);

// the menu cog (far right): opens the pause menu, like Escape or Tab
var cog_x = gui_w - 45, cog_y = bar_half;
var cog_hover = mouse_hovering(cog_x, cog_y, 56, 56, true);
cog_scale = lerp(cog_scale, cog_hover ? 1.15 : 1.0, 0.25);
cog_turn += cog_hover ? 2 : 0;
draw_cog_icon(cog_x, cog_y, 18 * cog_scale, cog_turn);
if (cog_hover) {
	queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Menu", "Pause, settings, or save and quit. Escape or Tab opens it too.");
	if (mouse_check_button_pressed(mb_left) && global.ui_layer == UI_LAYER.BASE && run_over == undefined && oCutsceneManager.cutscene_state == CUTSCENE_STATE.FINISHED) pause_open();
}

global.ui_peek_top_bar = false; // end of the top bar

// the bag icon is drawn in Draw GUI End too (Draw_75), so the map and room windows never cover it

// the bag view and the dice picker are drawn in Draw GUI End (Draw_75), above every room's windows
