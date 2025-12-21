if (room == rmMap) {
	if (nodes_cleared == 0) {
		// Define variables at start of game
		combat_chance = 15;
		event_chance = 65;
		workbench_chance = 5;
		shop_chance = 15;
		bounty_chance = 0;
		elite_chance = 0;
	}
	
	if (!ds_exists(pages_shown, ds_type_list)) pages_shown = ds_list_create();
	
	if (nodes_til_drafting == 0) {
		// Heal the player 4
		global.player_hp = min(global.player_max_hp, global.player_hp + 4);
		particle_emit(650, 25, "burst", c_lime);
		generate_pages();
	}
	
	show_debug_message("Possible elites " + string(ds_list_size(possible_elites)));
	show_debug_message("Elite list before bounty " + string(ds_list_size(elite_list_before_bounty)));
}