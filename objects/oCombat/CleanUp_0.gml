/// oCombat - Clean Up Event
// --- Return discarded dice to bag ---
if (ds_exists(global.discard_pile, ds_type_list)) {
    for (var i = 0; i < ds_list_size(global.discard_pile); i++) {
        var discard_die = global.discard_pile[| i];
        ds_list_add(global.dice_bag, clone_die(discard_die, "temporary"));
    }
    ds_list_clear(global.discard_pile);
}


// --- Return historically sacrificed dice to bag ---
if (ds_exists(global.sacrifice_history, ds_type_list)) {
    for (var j = 0; j < ds_list_size(global.sacrifice_history); j++) {
        var sac_die = global.sacrifice_history[| j];
        ds_list_add(global.dice_bag, clone_die(sac_die, "temporary"));
    }
    ds_list_clear(global.sacrifice_history);
}

// --- Destroy temporary lists ---
if (ds_exists(global.discard_pile, ds_type_list)) ds_list_destroy(global.discard_pile);
if (ds_exists(global.sacrifice_list, ds_type_list)) ds_list_destroy(global.sacrifice_list);
if (ds_exists(global.sacrifice_history, ds_type_list)) ds_list_destroy(global.sacrifice_history);
if (ds_exists(reward_options, ds_type_list)) ds_list_destroy(reward_options);