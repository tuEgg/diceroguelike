if (ds_exists(global.master_dice_list, ds_type_list)) ds_list_destroy(global.master_dice_list);
if (ds_exists(global.enemy_list, ds_type_list)) ds_list_destroy(global.enemy_list);
if (ds_exists(keepsakes, ds_type_list)) ds_list_destroy(keepsakes);
if (ds_exists(keepsake_scale, ds_type_list)) ds_list_destroy(keepsake_scale);
if (ds_exists(keepsakes_master, ds_type_list)) ds_list_destroy(keepsakes_master);
if (ds_exists(global.enemy_debuffs, ds_type_list)) ds_list_destroy(global.enemy_debuffs);
if (ds_exists(global.player_debuffs, ds_type_list)) ds_list_destroy(global.player_debuffs);