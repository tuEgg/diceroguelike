if (room == rmMap) {	
	var gui_w = display_get_gui_width();
	var gui_h = display_get_gui_height();
	
	// Keep scale list synced with keepsake size
	if (ds_list_size(page_scale) < ds_list_size(pages_shown)) {
	    repeat(ds_list_size(pages_shown) - ds_list_size(page_scale)) ds_list_add(page_scale, 1.0);
	} else if (ds_list_size(page_scale) > ds_list_size(pages_shown)) {
	    repeat(ds_list_size(page_scale) - ds_list_size(pages_shown)) ds_list_delete(page_scale, ds_list_size(page_scale) - 1);
	}

	var page_count = ds_list_size(pages_shown);
	
	var page_padding = 50;
	var page_width = sprite_get_width(sLogbookPage);
	var page_height = sprite_get_height(sLogbookPage);
	
	var total_page_w = ((page_count - 1) * page_width) + ((max(0, page_count - 1)) * page_padding);
	var page_start_x = (gui_w / 2) - (total_page_w / 2);
	
	for (var p = 0; p < page_count; p++) {
		var page = pages_shown[| p];
		var add_x = p * (page_padding + page_width)
		
		var btn = draw_gui_button(page_start_x + add_x - page_width/2, gui_h/2 - page_height/2, page_width, page_height, page_scale[| p], "", c_white, ftSmall, 1, false);
		page_scale[| p] = btn.scale;
		
		draw_sprite_ext(sLogbookPage, page.subimg, page_start_x + add_x, gui_h/2,  page_scale[| p],  page_scale[| p], 0, c_white, 1.0);
	
		if (btn.hover && mouse_check_button_pressed(mb_left)) {
			start_fight(page);
		}
		
		draw_set_font(ftLogbook);
		draw_set_color(c_white);
		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		
		// --- Draw text scaled with page hover ---
		var txt_scale = page_scale[| p];
		var txt_y = gui_h / 2 + 192 * txt_scale; // optional: move text up/down slightly with scale

		draw_set_font(ftLogbook);
		draw_set_color(c_white);
		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);

		// Use draw_text_transformed for scaling
		draw_text_transformed(
		    page_start_x + add_x,
		    txt_y,
		    string(page.text),
		    txt_scale,
		    txt_scale,
		    0
		);

	}
}