if (nodes_til_drafting == 0) {
	choices_locked = false;
	pages_drafted = 0;
}

if (room == rmMap) {
    
    // Smooth map towards target offset every step
    map_position.x = lerp(map_position.x, map_offset.x, 0.06);
    map_position.y = lerp(map_position.y, map_offset.y, 0.06);
    
    if (node_to_move_to != undefined) {
		
        // We only care about how close we are to the *target offset*
        var dx = map_offset.x - map_position.x;
        var dy = map_offset.y - map_position.y;
		
		boat_data.spd = point_distance(0, 0, dx, dy);

        // Debug if you like
        //show_debug_message("Cam delta: " + string(dx) + ", " + string(dy));

        if (abs(dx) < 5 && abs(dy) < 5) {
            // Snap cleanly to target offset
            map_position.x = map_offset.x;
            map_position.y = map_offset.y;

            // We have "arrived" at the node
            enter_node(node_to_move_to);
            node_to_move_to.cleared = true;
            nodes_til_drafting--;

            last_node = node_to_move_to;
			node_drift = 0;
            node_to_move_to = undefined;
			next_node = undefined;
        }
    }
	
	if (next_node == undefined) {
		for (var n = 0; n < ds_list_size(all_nodes); n++) {
			if (!all_nodes[| n].cleared) {
				next_node = all_nodes[| n];
				break;
			}
		}
	}

	if (last_node != undefined) {
		node_drift -= 1.5;
	}
}