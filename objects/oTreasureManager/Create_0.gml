exit_scale = 1.0;

chest_open = false;
chest_scale = 1.0;
keepsake_y = 100;
keepsake_alpha = 0;

keepsake_reward = ds_list_create();

// a treasure node picked its keepsake as it was entered (see enter_node), so Continue shows the same one
var _node = oWorldManager.current_node;
var _remembered = undefined;
if (_node != undefined && variable_struct_exists(_node, "treasure_keepsake") && is_string(_node.treasure_keepsake) && _node.treasure_keepsake != "") {
	_remembered = get_keepsake_by_id(_node.treasure_keepsake);
}

if (_remembered != undefined) {
	ds_list_add(keepsake_reward, clone_keepsake(_remembered));
} else {
	generate_keepsake_rewards(keepsake_reward, global.rollable_keepsake_list, 1);
}