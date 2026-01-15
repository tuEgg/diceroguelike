// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function generate_bounties(_num) {
	
	bounty = [];
	
	repeat(_num) {
		var elite_list = ds_list_create();
		
		for (var e = 0; e < ds_list_size(global.enemy_list); e++) {
			if (global.enemy_list[| e].elite) {
				ds_list_add(elite_list, global.enemy_list[| e]);
			}
		}
		
		var random_elite = elite_list[| irandom(ds_list_size(elite_list) - 1)];
		var random_condition = condition_list[| irandom(ds_list_size(condition_list) - 1)];
		
		var template = {
			enemy_name: random_elite.name,
			condition: random_condition,
			rewards: [],
			rewards_scale: array_create(3, 1.0),
			elite_encounter: "Elite 1",
			complete: false,
		}

		var reward_item = ds_list_create();
		var reward_keepsake = ds_list_create();
		var reward_dice = ds_list_create();
		generate_item_rewards(reward_item, global.master_item_list, 1, "core", "rare");
		generate_keepsake_rewards(reward_keepsake, global.rollable_keepsake_list, 1);
		generate_dice_rewards(reward_dice, global.master_dice_list, 1);
				
		array_push(template.rewards, reward_item[| 0]);
		array_push(template.rewards, reward_keepsake[| 0]);
		array_push(template.rewards, reward_dice[| 0]);
		
		array_push(bounty, template);
				
		ds_list_destroy(reward_item);
		ds_list_destroy(reward_keepsake);
		ds_list_destroy(reward_dice);
		ds_list_destroy(elite_list);
	}
}