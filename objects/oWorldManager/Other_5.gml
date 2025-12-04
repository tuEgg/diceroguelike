if (room == rmMap) {

} else {
	page_previous = room;
	if (pages_turned > 9) {
		oRunManager.voyage++;
	} else {
		pages_turned++;
		if (pages_turned == 1) {
			combat_chance = 47;
			event_chance = 33;
			workbench_chance = 10;
			shop_chance = 10;
		}
	}
}

if (room == rmCombat) {
	if (pages_turned == 3) {
		with (oRunManager) {
			//ds_list_add(keepsakes, get_keepsake_by_id("lucky_coin"));
		}
	}
}