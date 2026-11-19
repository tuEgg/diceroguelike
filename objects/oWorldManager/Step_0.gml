if (nodes_til_drafting == 0) {
	choices_locked = false;
	pages_drafted = 0;
}

if (room == rmMap) {
    
	world_finish_spread_if_done();
	
	// if we have a node to move to, animate the ship moving
    if (node_to_move_to != undefined) {
		
        // add checking for boat position in here
		var drift_speed = 0.1;
		var drift_direction = point_direction(boat_data.x, boat_data.y, node_to_move_to.x + 10, node_to_move_to.y);
		boat_data.x = lerp(boat_data.x, node_to_move_to.x, 0.05);
		boat_data.y = lerp(boat_data.y, node_to_move_to.y + 5, 0.05);

        // Debug if you like
        //show_debug_message("Cam delta: " + string(dx) + ", " + string(dy));

        if (point_distance(node_to_move_to.x, node_to_move_to.y + 5, boat_data.x, boat_data.y) < 10) {

            // We have "arrived" at the node
            enter_node(node_to_move_to);
            node_to_move_to.cleared = true;
            nodes_til_drafting--;
			nodes_til_page_cleared--;

			if (nodes_til_page_cleared == 0) {
				pages_cleared++;
				// a page's island is done: back on the map you're at sea, with time to work on your dice (F02)
				oRunManager.can_visit_workbench = true; // whether a tool has work is checked when the buoy or strait shows (workbench_useful), after this stop's rewards: a core won here counts
				if (pages_cleared % 2 == 0) {
					spreads_cleared++;
				}
	
				if (nodes_til_drafting > 0) {
					nodes_til_page_cleared = nodes_til_drafting;
				}
			}
			
			show_debug_message("nodes_til_page_cleared: " + string(nodes_til_page_cleared));
			show_debug_message("pages_cleared: " + string(pages_cleared));

            last_node = node_to_move_to;
			node_drift = 0;
            node_to_move_to = undefined;
			next_node = undefined;
        }
    }
	
	// find the next node
	if (next_node == undefined) {
		for (var n = 0; n < ds_list_size(all_nodes); n++) {
			if (!all_nodes[| n].cleared) {
				next_node = all_nodes[| n];
				break;
			}
		}
	}
}

if (oRunManager.dutchman_taken) shop_chance = 0;

if (combat_chance + event_chance + shop_chance + bounty_chance + elite_chance + alignment_chance < 100) {
	do { combat_chance++ } until (combat_chance + event_chance + shop_chance + bounty_chance + elite_chance + alignment_chance == 100);
}

if (combat_chance + event_chance + shop_chance + bounty_chance + elite_chance + alignment_chance > 100) {
	do {
		combat_chance -= 0.7;
		event_chance -= 0.3;
	} until (combat_chance + event_chance + shop_chance + bounty_chance + elite_chance + alignment_chance == 100);
	
	combat_chance = ceil(combat_chance);
	event_chance = floor(event_chance);
}
