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
			
			// Add thug after first encounter, just because it's slightly harder than the other early encounters
			ds_list_add(possible_encounters, "Early 4");
		}
		
		// Change enemy encounters after we've cleared 4 nodes
		if (nodes_cleared == 4) {
			ds_list_clear(possible_encounters);
			ds_list_add(possible_encounters, "Encounter 1");
			ds_list_add(possible_encounters, "Encounter 2");
			ds_list_add(possible_encounters, "Encounter 3");
			ds_list_add(possible_encounters, "Encounter 4");
			ds_list_add(possible_encounters, "Encounter 5");
			ds_list_add(possible_encounters, "Encounter 6");
			ds_list_add(possible_encounters, "Encounter 7");
			ds_list_add(possible_encounters, "Encounter 8");
		}
		
		// After we've cleared 5 nodes, start allowing bounties
		if (nodes_cleared == 5) {
			bounty_chance += 50;
			combat_chance -= 10;
			event_chance -= 10;
			workbench_chance -= 5;
			shop_chance -= 5;
		}
		
		// After we've cleared 7 nodes, start allowing elites
		if (oRunManager.active_bounty != undefined && nodes_cleared >= 8) {
			elite_chance = 80;
			combat_chance = 5;
			event_chance = 5;
			workbench_chance = 5;
			shop_chance = 5;
		}
	}
}

if (room == rmCombat) {
	ds_list_clear(room_enemies);
}

if (room == rmBounty) {
	if (oRunManager.active_bounty != undefined) {
		ds_list_add(possible_elites, oRunManager.active_bounty.elite_encounter);
	}
}

combat_chance = max(0, combat_chance);
event_chance = max(0, event_chance);
workbench_chance = max(0, workbench_chance);
shop_chance = max(0, shop_chance);
bounty_chance = max(0, bounty_chance);
elite_chance = max(0, elite_chance);