if (ds_exists(global.master_dice_list, ds_type_list)) ds_list_destroy(global.master_dice_list);
if (ds_exists(global.alignment_dice_list, ds_type_list)) ds_list_destroy(global.alignment_dice_list);
if (ds_exists(global.master_item_list, ds_type_list)) ds_list_destroy(global.master_item_list);
if (ds_exists(global.master_tool_list, ds_type_list)) ds_list_destroy(global.master_tool_list);
if (ds_exists(global.master_keepsake_list, ds_type_list)) ds_list_destroy(global.master_keepsake_list);
if (ds_exists(global.rollable_keepsake_list, ds_type_list)) ds_list_destroy(global.rollable_keepsake_list);
if (ds_exists(global.shop_keepsake_list, ds_type_list)) ds_list_destroy(global.shop_keepsake_list);
if (ds_exists(global.boss_keepsake_list, ds_type_list)) ds_list_destroy(global.boss_keepsake_list);
if (ds_exists(global.enemy_list, ds_type_list)) ds_list_destroy(global.enemy_list);
if (ds_exists(keepsakes, ds_type_list)) ds_list_destroy(keepsakes);
if (ds_exists(keepsake_scale, ds_type_list)) ds_list_destroy(keepsake_scale);
if (ds_exists(global.enemy_debuffs, ds_type_list)) ds_list_destroy(global.enemy_debuffs);
if (ds_exists(global.player_debuffs, ds_type_list)) ds_list_destroy(global.player_debuffs);
if (ds_exists(global.player_intel_data, ds_type_list)) ds_list_destroy(global.player_intel_data);
if (ds_exists(global.master_event_list, ds_type_list)) {
	ds_list_destroy(global.master_event_list);
	global.master_event_list = undefined;
}