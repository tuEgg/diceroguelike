/// oCombat - Clean Up Event

// --- Destroy temporary lists ---
if (ds_exists(global.discard_pile, ds_type_list)) {
	ds_list_destroy(global.discard_pile); 
	global.discard_pile = undefined;
}
if (ds_exists(global.sacrifice_list, ds_type_list)) {
	ds_list_destroy(global.sacrifice_list);
	global.sacrifice_list = undefined;
}
if (ds_exists(global.sacrifice_history, ds_type_list)) {
	ds_list_destroy(global.sacrifice_history);
	global.sacrifice_history = undefined;
}
if (ds_exists(reward_dice_options, ds_type_list)) ds_list_destroy(reward_dice_options);
if (ds_exists(reward_consumable_options, ds_type_list)) ds_list_destroy(reward_consumable_options);
if (ds_exists(reward_keepsake_options, ds_type_list)) ds_list_destroy(reward_keepsake_options);
if (ds_exists(reward_list, ds_type_list)) ds_list_destroy(reward_list);
if (ds_exists(room_enemies, ds_type_list)) ds_list_destroy(room_enemies);

// Free the per-fight lists each enemy owned
for (var i = 0; i < array_length(fight_enemy_records); i++) {
	var _enemy = fight_enemy_records[i];
	if (ds_exists(_enemy.data.moves, ds_type_list)) ds_list_destroy(_enemy.data.moves);
	if (ds_exists(_enemy.move_history, ds_type_list)) ds_list_destroy(_enemy.move_history);
	if (ds_exists(_enemy.debuffs, ds_type_list)) ds_list_destroy(_enemy.debuffs);
}
