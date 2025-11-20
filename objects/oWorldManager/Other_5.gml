if (room == rmMap) {
	ds_list_clear(pages_shown);
} else {
	page_previous = room;
	if (pages_turned > 9) {
		oRunManager.voyage++;
	} else {
		pages_turned++;
	}
}

if (room == rmCombat) {
	if (pages_turned == 3) {
		with (oRunManager) {
			ds_list_add(keepsakes, get_keepsake_by_id("lucky_coin"));
		}
	}
}