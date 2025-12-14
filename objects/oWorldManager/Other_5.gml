if (room == rmMap) {

} else {
	page_previous = room;
	if (nodes_cleared > 9) {
		oRunManager.voyage++;
	} else {
		nodes_cleared++;
			
		// The second time we draft:
		if (nodes_cleared == 1) {
			combat_chance = 47;
			event_chance = 33;
			workbench_chance = 10;
			shop_chance = 10;
		}
		
		// After we've cleared 5 nodes, start allowing bounties
		if (nodes_cleared == 5) {
			bounty_chance += 30;
			combat_chance -= 10;
			event_chance -= 10;
			workbench_chance -= 5;
			shop_chance -= 5;
			
			// and change the enemy counters
			ds_list_clear(possible_encounters);
			ds_list_add(possible_encounters, "Encounter 1");
			ds_list_add(possible_encounters, "Encounter 2");
			ds_list_add(possible_encounters, "Encounter 3");
			ds_list_add(possible_encounters, "Encounter 4");
			ds_list_add(possible_encounters, "Encounter 5");
		}
		
		// After we've cleared 7 nodes, start allowing elites
		if (bounty != undefined && nodes_cleared >= 8) {
			elite_chance += 100;
			combat_chance = 0;
			event_chance = 0;
			workbench_chance = 0;
			shop_chance = 0;		
		}
	}
}

if (room == rmCombat) {
	ds_list_clear(room_enemies);
}

combat_chance = max(0, combat_chance);
event_chance = max(0, event_chance);
workbench_chance = max(0, workbench_chance);
shop_chance = max(0, shop_chance);
bounty_chance = max(0, bounty_chance);
elite_chance = max(0, elite_chance);