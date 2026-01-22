// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function generate_bounties(_num) {
	
	bounty = [];
	
	repeat(_num) {
		
		var random_elite_encounter = choose("Elite 1", "Elite 2", "Elite 3");
		
		if (array_length(bounty) > 0) {
			do {
				random_elite_encounter = choose("Elite 1", "Elite 2", "Elite 3");
			} until (random_elite_encounter != bounty[0].elite_encounter);
		}
		
		var random_elite = "";
		
		switch (random_elite_encounter) {
			case "Elite 1":
				random_elite = "Pirate Captain";
			break;
			
			case "Elite 2":
				random_elite = "Giant Conch";
			break;
			
			case "Elite 3":
				random_elite = "Unfinished Elite";
			break;
		}
		
		var random_condition = condition_list[| irandom(ds_list_size(condition_list) - 1)];
		
		var template = {
			enemy_name: random_elite,
			condition: random_condition,
			rewards: [],
			rewards_scale: array_create(3, 1.0),
			elite_encounter: random_elite_encounter,
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
	}
}