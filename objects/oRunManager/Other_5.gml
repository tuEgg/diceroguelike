if (room == rmWorkbench || room = rmEvent) {
	holding_item = false;
	dice_dealt = false;
}

if (room == rmCombat) {
	ds_list_clear(global.player_debuffs);
	bonus_dice_next_combat = 0;
}