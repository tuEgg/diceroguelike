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
				random_elite = "Pirate Captain"; // Elite 3 is currently the same fight as Elite 1 (see get_combat_enemies)
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

function get_condition_by_id(_id) {
    for (var i = 0; i < ds_list_size(oBountyController.condition_list); i++) {
        if (oBountyController.condition_list[| i]._id == _id) {
            return oBountyController.condition_list[| i];
        }
    }
    return undefined;
}

// Save
function serialise_bounty(_bounty) {
    var _saved_rewards = [
        // a reward already handed over is undefined, and saved as ""
        { type: "item", name: (_bounty.rewards[0] != undefined) ? _bounty.rewards[0].name : "" },
        { type: "keepsake", name: (_bounty.rewards[1] != undefined) ? _bounty.rewards[1]._id : "" },
        { type: "die", name: (_bounty.rewards[2] != undefined) ? _bounty.rewards[2].name : "" },
    ];
    return {
        enemy_name: _bounty.enemy_name,
        condition_id: _bounty.condition._id,
        rewards: _saved_rewards,
        elite_encounter: _bounty.elite_encounter,
        complete: _bounty.complete,
    };
}

function deserialise_bounty(_data) {
    var _rewards = [];
    for (var i = 0; i < array_length(_data.rewards); i++) {
        var _r = _data.rewards[i];
        if (_r.name == "") { array_push(_rewards, undefined); continue; } // already handed over
        switch (_r.type) {
            case "item": array_push(_rewards, clone_item(get_item_by_name(_r.name))); break;
            case "keepsake": array_push(_rewards, get_keepsake_by_id(_r.name)); break;
            case "die": array_push(_rewards, clone_die(get_die_by_name(_r.name), "")); break;
        }
    }
    return {
        enemy_name: _data.enemy_name,
        condition: get_condition_by_id(_data.condition_id),
        rewards: _rewards,
        rewards_scale: array_create(3, 1.0),
        elite_encounter: _data.elite_encounter,
        complete: _data.complete,
    };
}

/// @desc The bounty board's contracts and potion, for the save file, so Continue shows the same board.
function serialise_bounty_board() {
	if (!instance_exists(oBountyController)) return "";
	
	var _saved = { bounties: [], potion: "", potion_taken: false };
	with (oBountyController) {
		for (var i = 0; i < array_length(bounty); i++) {
			array_push(_saved.bounties, serialise_bounty(bounty[i]));
		}
		if (potion != undefined) {
			_saved.potion = potion.name;
			_saved.potion_taken = potion.taken;
		}
	}
	return _saved;
}

/// @desc Put back the bounty board saved by serialise_bounty_board.
function deserialise_bounty_board(_saved) {
	if (!is_struct(_saved) || !instance_exists(oBountyController)) return;
	
	with (oBountyController) {
		bounty = [];
		for (var i = 0; i < array_length(_saved.bounties); i++) {
			array_push(bounty, deserialise_bounty(_saved.bounties[i]));
		}
		
		var _item = get_item_by_name(_saved.potion);
		if (_item != undefined) {
			potion = clone_item(_item);
			potion.taken = _saved.potion_taken;
		}
	}
}
