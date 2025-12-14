if (room == rmMap) {
	if (nodes_cleared == 0) {
		// Define variables at start of game
		combat_chance = 30;
		event_chance = 70;
		workbench_chance = 0;
		shop_chance = 0;
		bounty_chance = 0;
		elite_chance = 0;
	}
	
	if (!ds_exists(pages_shown, ds_type_list)) pages_shown = ds_list_create();
	
	if (nodes_til_drafting == 0) generate_pages();
}