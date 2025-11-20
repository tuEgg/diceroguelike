if (room == rmCombat) {
	current_node.cleared = true;
	nodes_cleared++;

	if (nodes_cleared == 3) {
		with (oRunManager) {
			ds_list_add(keepsakes, get_keepsake_by_id("lucky_coin"));
		}
	}
}