if (room == rmMap) {
	var mx = device_mouse_x_to_gui(0);
	var my = device_mouse_y_to_gui(0);

	// for every node in the list
	for (var i = 0; i < ds_list_size(node_list); i++) {
		var node = node_list[| i];
		var prev_cleared = true;
		if (i > 0) {
			prev_cleared = node_list[| i-1].cleared;
		}
	
		// get their width
		var node_width = sprite_get_width(sMapIcon) * node.scale;
		var node_height = sprite_get_height(sMapIcon) * node.scale;
	
		// check if we are hovering over that node
		var hover = !node.cleared * prev_cleared * (mx < node.pos_x + (node_width/2) && mx > node.pos_x - (node_width/2) && my < node.pos_y + (node_height/2) && my > node.pos_y - (node_height/2));
	
		if (node.visited) {
			draw_set_alpha(1.0);
			draw_set_color(c_green);
			
			var _rad = 52;
			draw_circle(node.pos_x, node.pos_y, _rad, true);
			draw_circle(node.pos_x, node.pos_y, _rad - 1, true);
			draw_circle(node.pos_x, node.pos_y, _rad - 2, true);
		}
		
		// Check if previous node has been cleared
		var _alpha = prev_cleared ? 1.0 : 0.2;
	
		// draw line from node to previous nodes
		if (i > 0) {
			for (var n = 0; n < ds_list_size(node.connections); n++) {
				var node_x = node.connections[| n].pos_x;
				var node_y = node.connections[| n].pos_y;
				draw_set_color(c_black);
				draw_set_alpha(node_list[| i-1].visited ? 0.2 : 1.0);
				draw_line_width(node.pos_x, node.pos_y, node_x, node_y, 2);
			}
		}
		
		// pulse if previous was cleared
		var pulse = 1;
		if (prev_cleared && !node.cleared) {
			if (!hover) time += 0.07;
			pulse = 1.1 + 0.2* ( sin(time));
		}
	
		// Smooth scale update
		var current_scale = node.scale;
	    var target_scale = hover ? 1.2 : 1.0;
	    current_scale = lerp(current_scale, target_scale, 0.2);
	    node.scale = current_scale;
	
		draw_set_alpha(0.5 * _alpha);
		draw_set_color(c_black);
		draw_circle(node.pos_x, node.pos_y, node_width * 0.7 * pulse, false);
	
		// draw the node icon at the correct scale
		draw_sprite_ext(
			sMapIcon,
			node.node_type,
			node.pos_x,
			node.pos_y,
			node.scale * pulse,
			node.scale * pulse,
			0,
			c_white,
			_alpha
		);
	
		// Click to go into room
		if (hover && mouse_check_button_pressed(mb_left) && !node.visited && prev_cleared) {
			room_goto(rmCombat);
			current_node = node;
			node.visited = true;
			node_enemy = node.enemy;
		}
	}
}