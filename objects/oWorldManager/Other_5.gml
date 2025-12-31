if (room == rmMap) {

} else {
	alarm[0] = 1;
	
	page_previous = room;
	if (nodes_cleared > 100) {
		oRunManager.voyage++;
	} else {
		if (room != rmWorkbench) nodes_cleared++;
			
		// The second time we draft:
		if (nodes_cleared == 1) {
			combat_chance = 40;
			event_chance = 40;
			shop_chance = 20;
			
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
		
		// Start pushing for bounties after node 3
		if (nodes_cleared > 3 && bounty_nodes_this_voyage == 0) {
			bounty_chance += 5;
			combat_chance -= 2;
			event_chance -= 2;
			shop_chance -= 1;
		}
		
		// If we haven't had a bounty by node 7, really push for one
		if (nodes_cleared == 7 && bounty_nodes_this_voyage == 0) {
			bounty_chance += 40;
			combat_chance -= 20;
			event_chance -= 15;
			shop_chance -= 10;
		}
		
		if (room == rmBounty) {
			bounty_chance = 0;
			elite_chance += 10;
		}
		
		// Start allowing elites from node 7
		if (nodes_cleared >= 7 && elite_nodes_this_voyage <= 2) {
			elite_chance += 2.5 + ((2 - elite_nodes_this_voyage) * 1.5); // 5-10% if we've fought 2-0 elites
		}
		
		// Once we have a bounty active, start really pushing elites
		if (oRunManager.active_bounty != undefined) {
			if (!oRunManager.active_bounty.complete) {
				if (elite_nodes_this_voyage < 2) {
					// Add a further 10% for elite chance once we have a bounty
					elite_chance += 5;
				}
			}
			
			if (oRunManager.active_bounty.complete || oRunManager.active_bounty.condition.failed) {
				// once victorious, unset the bounty
				oRunManager.active_bounty = undefined;
			}
		}
		
		if (elite_nodes_this_voyage > 2) {
			elite_chance = 0;
		}
	}
}

if (room == rmCombat) {
	ds_list_clear(room_enemies);
}

if (room == rmBounty) {
	if (oRunManager.active_bounty != undefined) {
		ds_list_copy(elite_list_before_bounty, possible_elites);
		ds_list_clear(possible_elites);
		ds_list_add(possible_elites, oRunManager.active_bounty.elite_encounter);
	}
}

combat_chance =		clamp(0, combat_chance, 100);
event_chance =		clamp(0, event_chance, 100);
shop_chance =		clamp(0, shop_chance, 100);
bounty_chance =		clamp(0, bounty_chance, 100);
elite_chance =		clamp(0, elite_chance, 100);