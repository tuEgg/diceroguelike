// need to shuffle bag every time we enter combat
if (room == rmCombat) {
	ds_list_shuffle(global.dice_bag);
}

for (var i = 0; i < ds_list_size(global.dice_bag); i++) {
	var die = global.dice_bag[| i];
	
	die.statistics.times_rolled_this_combat = 0;
	die.statistics.times_played_this_combat = 0;
	
	if (die.reset_at_end_combat != false) {
		die.reset_at_end_combat(die);
		die.reset_at_end_combat = false;
		//show_debug_message("Resetting at the end of combat");
	}
}