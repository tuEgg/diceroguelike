if (room == rmMap && pages_turned > 0) {
	
	// generate a new set of pages
	var _number_of_pages = 3;
	
	do {
		// Combat should always appear for the first instance
		// Then it should be an equal chance of events and combat for the next 2-3 rounds
		// By round 4 we should be seeing at least a workbench or a shop
		// By round 6 we should be seeing the other of the above
		// By round 9 we should have had 3 of: workshop and shop
		// Can never have workbenches back to back, or shops back to back
		_page = choose(node_combat, node_event);
		
		if (pages_turned mod 12 == 0) {
			_page = page_boss;
		}
		
		if (_page.linked_room == page_previous) {
			continue;
		} else {
			ds_list_add(pages_shown, _page);
		}
	} until (ds_list_size(pages_shown) == _number_of_pages);
	
	// eventual plan here would be have each region have 12 sets of pages offered.
	// 1st offering is always combat
	// 2nd is 2 or 3 possibilities (between combat, event, shop)
	// elite fights can't happen in the first half of a region
}