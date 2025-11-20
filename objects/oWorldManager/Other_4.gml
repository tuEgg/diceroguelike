if (room == rmMap && pages_turned > 0) {
	
	// generate a new set of pages
	var _num = irandom_range(1, 3);
	
	if (pages_turned > 9) _num = 1;
	
	for (var i = 0; i < _num; i++) {
		_page = page_combat;
		
		if (pages_turned <= 9) {
			if (page_previous == rmCombat) {
				if (i == 1) {
					var n = irandom(2);
					if (n == 0) _page = choose(page_shop, page_workbench);
				}
				if (i == 2) {
					var n = irandom(1);
					if (n == 0) _page = choose(page_shop, page_workbench);
				}
			}
		} else {
			_page = page_boss;
		}
	
		ds_list_add(pages_shown, _page);
	}
	
	// eventual plan here would be have each region have 12 sets of pages offered.
	// 1st offering is always combat
	// 2nd is 2 or 3 possibilities (between combat, event, shop)
	// elite fights can't happen in the first half of a region
}