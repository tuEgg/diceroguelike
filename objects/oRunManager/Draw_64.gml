gui_w = display_get_gui_width();
gui_h = display_get_gui_height();

var bar_height = 70;

// Draw top bar
draw_sprite(sTopBar, 0, -3, -4);

// Draw voyage act
draw_set_font(ftTopBar);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
var act = "I"
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
draw_outline_text("Voyage " + act, c_black, c_white, 2, 20, 15, 1, 1, 0);
var voyage_hover = mouse_hovering(20, 15, string_width("Voyage III"), string_height("Voyage III"), false);
if (voyage_hover) queue_tooltip(mouse_x, mouse_y, "Voyages Sailed", "You are on voyage " + string(act) + "/III", undefined, 0, undefined);

// Draw pages turned
draw_set_halign(fa_center);
draw_set_valign(fa_top);
draw_sprite(sTopBarIcons, 0, 280 + 5, 15);
draw_outline_text(string(oWorldManager.pages_turned), c_black, c_white, 2, 350 + 5, 30, 1, 1, 0);
var pages_hover = mouse_hovering(280 + 5, 15, sprite_get_width(sTopBarIcons), sprite_get_height(sTopBarIcons), false);
if (pages_hover) queue_tooltip(mouse_x, mouse_y, "Pages Turned", "You have turned " + string(oWorldManager.pages_turned) + " pages of the Captain's logbook", undefined, 0, undefined);

// Draw money
draw_sprite(sTopBarIcons, 1, 400 + 5, 15);
draw_outline_text(string(credits), c_black, c_white, 2, 470 + 5, 30, 1, 1, 0);
var credits_hover = mouse_hovering(400 + 5, 15, sprite_get_width(sTopBarIcons), sprite_get_height(sTopBarIcons), false);
if (credits_hover) queue_tooltip(mouse_x, mouse_y, "Gold Doubloons", "You have " + string(credits) + " gold doubloons", undefined, 0, undefined);

// Draw cores and consumables
var core_x = 800;
var core_y = 18;
for (var i = 0; i < array_length(items); i++) {
	var i_x = 90 * i;
	var sprite_x;
	var sprite_y;
	
	if (items[i] != undefined) {
		if (items[i].dragging) {
			sprite_x = mouse_x;
			sprite_y = mouse_y;
		} else {
			sprite_x = core_x + 5 + i_x + sprite_get_width(sTopBarSlot)/2;
			sprite_y = core_y + sprite_get_height(sTopBarSlot)/2;
		}
	}
	
	draw_sprite(sTopBarSlot, 1, core_x + 5 + i_x, core_y);
	
	if (items[i] != undefined) {
		var default_scale = 1.0;
		var default_angle = 0;
		if (items[i].type == "consumable") {
			default_scale = 1.2;
			default_angle = -30;
		}
		draw_sprite_ext(items[i].sprite, items[i].index, sprite_x, sprite_y, items_hover_scale[i], items_hover_scale[i], default_angle, c_white, 1.0);
		
		//draw_outline_text(items[i].quantity, c_black, c_white, 2, core_x + 70 + 5 + i_x, 25, 1, 1, 0);
		
		items_hover[i] = mouse_hovering(core_x + 5 + i_x, core_y, sprite_get_width(sTopBarSlot), sprite_get_height(sTopBarSlot), false);
		
		items_hover_scale[i] = lerp(items_hover_scale[i], items_hover[i] ? default_scale * 1.2 : default_scale, 0.2);
		
		if (items_hover[i]) {
			var die = undefined;
			if (string_pos("Core", items[i].name) > 0) {
				die = clone_die(global.dice_d6_atk, "");
				die.distribution = items[i].distribution;
			}
			queue_tooltip(mouse_x, mouse_y, items[i].name, items[i].description, undefined, 0, die);
		}
	
		// Add core dragging functionality
		if (room == rmWorkbench) {
			if (items[i].type == "core") {
				// drag the core
				if (items_hover[i] && mouse_check_button(mb_left)) {
					items[i].dragging = true;
				}
				// release the core
				if (items[i].dragging and mouse_check_button_released(mb_left)) {
					items[i].dragging = false;
				}
			}
		}
		
		// Add potion dragging functionality
		if (items[i].type == "consumable") {

			if (items_hover[i] && mouse_check_button(mb_left)) {
				items[i].dragging = true;
			}

			if (items[i].dragging and mouse_check_button_released(mb_left)) {
				items[i].dragging = false;
			}
			
			if (items[i].dragging && mouse_check_button_pressed(mb_left)) {
				if (room == rmCombat && !oCombat.show_rewards && items[i].effects.trigger == "on_clicked") {
					var ctx = {};
					trigger_item_effects(items[i], "on_clicked", ctx);
					items[i] = undefined;
				}
			}

			if (items_hover[i] && mouse_check_button(mb_right)) {
				items[i] = undefined;
			}
		}
	}
}

// Keep scale list synced with keepsake size
if (ds_list_size(keepsake_scale) < ds_list_size(keepsakes)) {
    repeat(ds_list_size(keepsakes) - ds_list_size(keepsake_scale)) ds_list_add(keepsake_scale, 1.0);
} else if (ds_list_size(keepsake_scale) > ds_list_size(keepsakes)) {
    repeat(ds_list_size(keepsake_scale) - ds_list_size(keepsakes)) ds_list_delete(keepsake_scale, ds_list_size(keepsake_scale) - 1);
}

var ks_x = 15;
var ks_y = bar_height + 25;

for (var k = 0; k < ds_list_size(keepsakes); k++) {
	var xx = k * 60;
	var _keepsake = keepsakes[| k];
	var btn_size = 64;
	var btn = draw_gui_button(ks_x + xx, ks_y, btn_size, btn_size, keepsake_scale[| k], "", c_white, ftSmall, 1, false);
	keepsake_scale[| k] = btn.scale;
	draw_sprite_ext(sKeepsake, _keepsake.sub_image, ks_x + xx + btn_size/2, ks_y + btn_size/2, keepsake_scale[| k] * 0.8, keepsake_scale[| k] * 0.8, 0, c_white, 1);
	
	if (btn.hover) {
		queue_tooltip(mouse_x, mouse_y, keepsakes[| k].name, keepsakes[| k].desc, undefined, 0, undefined);
	}
}

// Draw draw bag (discard bag in oCombat)
draw_sprite(sDiceBag, 0, 60, gui_h - 40);
draw_set_font(ftBigger);
draw_set_valign(fa_bottom)
draw_set_halign(fa_left);
draw_outline_text(room = rmCombat ? "DRAW" : "BAG", c_black, c_white, 2, 110, gui_h - 33, 1, 1, 0);

var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);

// Draw bag preview
var bag_x = GUI_LAYOUT.BAG_X;
var bag_y = gui_h - GUI_LAYOUT.BAG_Y - GUI_LAYOUT.BAG_H;
var bag_w = GUI_LAYOUT.BAG_W;
var bag_h = GUI_LAYOUT.BAG_H;
bag_hover = (mx > bag_x && mx < bag_x + bag_w && my > bag_y && my < bag_y + bag_h);

// Draw bag count
draw_set_color(c_black);
draw_circle(70, gui_h - 55, 20, false);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(c_white);
draw_set_font(ftBig);
draw_text(70, gui_h - 55, string(ds_list_size(global.dice_bag)));

if (bag_hover) {
    var bag_bg_offset = 200;
	var bag_bg_w = 420;
	var bag_bg_h = 180;
    draw_set_color(c_black);
    draw_set_alpha(0.3);
	draw_roundrect(bag_bg_offset, gui_h - bag_bg_offset, bag_bg_offset + bag_bg_w, gui_h - bag_bg_offset - bag_bg_h, false);

    // === Draw dice from bag ===
    var dice_per_row = 5;
	var dice_scale = 1;
    var dice_spacing = 80 * dice_scale;
	var padding = 50 * dice_scale;
    var start_x = bag_bg_offset + padding;
    var start_y = gui_h - bag_bg_offset - bag_bg_h + padding;

    for (var i = 0; i < ds_list_size(global.dice_bag); i++) {
        var die_struct = global.dice_bag[| i];

        // Position in grid
        var col = i mod dice_per_row;
        var row = i div dice_per_row;

        var xx = start_x + (col * dice_spacing);
        var yy = start_y + (row * dice_spacing);

        // Choose color based on action type
        var colr = get_dice_color(die_struct.action_type);

        // Choose image index based on dice type
        var frame = get_dice_index(die_struct.dice_value);

        // Draw dice sprite
        draw_set_alpha(1);
        draw_set_color(colr);
        draw_sprite_ext(sDice, frame, xx, yy, dice_scale, dice_scale, 0, colr, 1);
		draw_dice_keywords(die_struct, xx, yy, 1);

        // Optional: outline or count number
        //draw_set_color(c_black);
        //draw_set_alpha(0.5);
        //draw_rectangle(xx - 32, yy - 32, xx + 32, yy + 32, false);
    }
}

// Draw all tooltips
draw_all_tooltips();