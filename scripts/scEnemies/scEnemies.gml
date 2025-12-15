// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function enemy_create(_name, _max_hp, _bounty, _moves_array, _move_order, _elite = false, _passive = undefined)
{
    var e = {
        name: _name,
        max_hp: _max_hp,
        current_hp: _max_hp,
        bounty: _bounty,
        moves: ds_list_create(),
		move_order: _move_order,
		elite: _elite,
		passive: _passive
    };
    
    // Copy all moves into its list
    for (var i = 0; i < array_length(_moves_array); i++) {
		ds_list_add(e.moves, _moves_array[i]);
    }
    
    return e;
}

function enemy_definitions() {
	// Create a global enemy list to hold all types
	global.enemy_list = ds_list_create();

	// -------------------------------
	// VOYAGE 1 ENEMIES
	// -------------------------------

	var pirate_ruffian_moves = [
	    { dice_amount: 1, dice_value: 8, action_type: "ATK", bonus_amount: 1, move_name: "Pointed Cutlass" },
	    { dice_amount: 2, dice_value: 2, action_type: "BLK", bonus_amount: 3, move_name: "Block" },
	];
	var pirate_ruffian = enemy_create("Pirate Ruffian", 21, 7, pirate_ruffian_moves, "pseudo_random");
	ds_list_add(global.enemy_list, pirate_ruffian);
	
	var parrot_moves = [
	    { dice_amount: 3, dice_value: 2, action_type: "MIMIC", bonus_amount: 1, move_name: "Mimic" },
	    { dice_amount: 3, dice_value: 2, action_type: "MIMIC", bonus_amount: 1, move_name: "Mimic" },
	];
	var parrot = enemy_create("Parrot", 10, 5, parrot_moves, "pseudo_random");
	ds_list_add(global.enemy_list, parrot);
	
	var peg_leg_moves = [
	    { dice_amount: 1, dice_value: 1, action_type: "NONE", bonus_amount: 0, move_name: "Stretching" },
	    { dice_amount: 1, dice_value: 1, action_type: "NONE", bonus_amount: 0, move_name: "Removing Leg" },
	    { dice_amount: 5, dice_value: 4, action_type: "ATK", bonus_amount: 2, move_name: "Throwing Leg" },
	    { dice_amount: 1, dice_value: 2, action_type: "EXIT", bonus_amount: 2, move_name: "Running Away" },
	];
	var peg_leg = enemy_create("Peg-leg", 30, 20, peg_leg_moves, "ordered");
	ds_list_add(global.enemy_list, peg_leg);

	var seagull_moves = [
	    { dice_amount: 2, dice_value: 2, action_type: "ATK", bonus_amount: 1, move_name: "Peck" },
	    { dice_amount: 1, dice_value: 2, action_type: "BLK", bonus_amount: 2, move_name: "Evade" },
	];
	var seagull = enemy_create("Seagull", 8, 8, seagull_moves, "pseudo_random");
	ds_list_add(global.enemy_list, seagull);
	
	var baby_kraken_moves = [
	    { dice_amount: 2, dice_value: 2, action_type: "ATK", bonus_amount: 4, move_name: "Tentacle Whip" },
	    { dice_amount: 3, dice_value: 2, action_type: "BLK", bonus_amount: 0, move_name: "Coil" },
	    { dice_amount: 1, dice_value: 1, action_type: "DEBUFF", bonus_amount: 0, move_name: "Bind", debuff: debuff_bind, amount: 1, duration: 1 },
	];
	var baby_kraken = enemy_create("Baby Kraken", 26, 16, baby_kraken_moves, "pseudo_random");
	ds_list_add(global.enemy_list, baby_kraken);
	
	var deckhand_moves = [
	    { dice_amount: 1, dice_value: 6, action_type: "ATK", bonus_amount: 3, move_name: "Slash" }, // Slash
	    { dice_amount: 1, dice_value: 4, action_type: "BLK", bonus_amount: 4, move_name: "Duck" }  // Duck
	];
	var deckhand = enemy_create("Deckhand", 29, 15, deckhand_moves, "pseudo_random");
	ds_list_add(global.enemy_list, deckhand);

	var thug_moves = [
	    { dice_amount: 2, dice_value: 4, action_type: "ATK", bonus_amount: 5, move_name: "Heavy Swing" }, // Heavy Swing
	    { dice_amount: 1, dice_value: 1, action_type: "DEBUFF", bonus_amount: 0, move_name: "Mock", debuff: debuff_mock, amount: 1, duration: 1 }, // Mock
	    { dice_amount: 1, dice_value: 4, action_type: "BLK", bonus_amount: 4, move_name: "Parry" }  // Duck
	];
	var thug = enemy_create("Thug", 36, 17, thug_moves, "pseudo_random");
	ds_list_add(global.enemy_list, thug);
	
	var pufferfish_moves = [
	    { dice_amount: 3, dice_value: 4, action_type: "ATK", bonus_amount: 5, move_name: "Eject Spines", weight: 50 }, // Heavy Swing
	    { dice_amount: 1, dice_value: 1, action_type: "BUFF", bonus_amount: 0, move_name: "Spines", weight: 0, use_trigger: "FIRST", debuff: buff_spines, amount: 1, duration: 1 }, // Mock
	    { dice_amount: 2, dice_value: 4, action_type: "BLK", bonus_amount: 2, move_name: "Inflate", weight: 50 }  // Duck
	];
	var pufferfish = enemy_create("Pufferfish", 36, 17, pufferfish_moves, "weighted");
	ds_list_add(global.enemy_list, pufferfish);

	var gunner_moves = [
	    { dice_amount: 2, dice_value: 4, action_type: "BLK", bonus_amount: 5, move_name: "Take Aim" }, // Aim
	    { dice_amount: 3, dice_value: 4, action_type: "ATK", bonus_amount: 6, move_name: "Volley Fire" }, // Volley Fire
	    { dice_amount: 0, dice_value: 0, action_type: "NONE", bonus_amount: 0, move_name: "Reload" } // Reload
	];
	var gunner = enemy_create("Corsair Gunner", 55, 19, gunner_moves, "ordered");
	ds_list_add(global.enemy_list, gunner);

	var turtle_moves = [
	    { dice_amount: 5, dice_value: 2, action_type: "BLK", bonus_amount: -1, move_name: "Withdraw" }, // Aim
	    { dice_amount: 8, dice_value: 2, action_type: "ATK", bonus_amount: -4, move_name: "Claw" }, // Volley Fire
	    { dice_amount: 2, dice_value: 4, action_type: "BLK/ATK", bonus_amount: 1, move_name: "Rapid Spin" }, // Volley Fire
	];
	var turtle = enemy_create("Turtle", 48, 18, turtle_moves, "pseudo_random", false, passive_turtle_shell);
	ds_list_add(global.enemy_list, turtle);
	
	var barrel_of_fish_moves = [
	    { dice_amount: 1, dice_value: 1, action_type: "DEBUFF", bonus_amount: 0, move_name: "Rot", debuff: debuff_rot, weight: 25, amount: 1, duration: 1  },
	    { dice_amount: 2, dice_value: 2, action_type: "HEAL", bonus_amount: 4, move_name: "Feeding Frenzy", weight: 25, target: "other" },
	    { dice_amount: 3, dice_value: 2, action_type: "ATK", bonus_amount: 1, move_name: "Snap", weight: 50 }
	];
	var barrel_of_fish = enemy_create("Barrel o' Fish", 15, 10, barrel_of_fish_moves, "weighted");
	ds_list_add(global.enemy_list, barrel_of_fish);
	
	var driftnet_fish_moves = [
	    { dice_amount: 1, dice_value: 1, action_type: "BUFF", bonus_amount: 0, move_name: "Shiny Scales", debuff: buff_shiny_scales, amount: 1, duration: 1, weight: 0 },
	    { dice_amount: 2, dice_value: 2, action_type: "ATK", bonus_amount: 4, move_name: "Snap", weight: 75 },
	    { dice_amount: 2, dice_value: 2, action_type: "DEBUFF", bonus_amount: 1, move_name: "Overwhelm", debuff: debuff_overwhelm, weight: 25, amount: 3, duration: 1 }
	];
	var driftnet_fish = enemy_create("Driftnet Fish", 18, 10, driftnet_fish_moves, "weighted");
	ds_list_add(global.enemy_list, driftnet_fish);
	
	var pirate_captain_moves = [
	    { dice_amount: 1, dice_value: 1, action_type: "BUFF", bonus_amount: 0, move_name: "Command", debuff: buff_might, weight: 20, use_trigger: "FIRST", target: "other", amount: 1, duration: 2 }, // Command
	    { dice_amount: 3, dice_value: 4, action_type: "ATK", bonus_amount: 6, move_name: "Pistol Shot", weight: 40 }, // Take Cover
	    { dice_amount: 3, dice_value: 2, action_type: "BLK", bonus_amount: 8, move_name: "Take Cover", weight: 40 }, // Pistol Shot
	    { dice_amount: 1, dice_value: 1, action_type: "SUMMON", bonus_amount: 0, move_name: "Open Barrel", weight: 0, summon: "Barrel o' Fish", use_trigger: "HEALTH 50" } // Pistol Shot
	];
	var pirate_captain = enemy_create("Pirate Captain", 70, 45, pirate_captain_moves, "weighted", true);
	ds_list_add(global.enemy_list, pirate_captain);


	// -------------------------------
	// TIER 3 — SEA MONSTROSITIES
	// -------------------------------

	var titan_moves = [
	    { dice_amount: 2, dice_value: 6, action_type: "ATK", bonus_amount: 4, move_name: "Crushing Slam" }, // Crushing Slam
	    { dice_amount: 2, dice_value: 8, action_type: "BLK", bonus_amount: 5, move_name: "Harden Shell" }, // Harden Shell
	    { dice_amount: 1, dice_value: 6, action_type: "DEBUFF", bonus_amount: 0, move_name: "Barnacle Bind", debuff: debuff_bind } // Mock
	];
	var titan = enemy_create("Barnacle Titan", 125, 151, titan_moves, "pseudo_random");
	ds_list_add(global.enemy_list, titan);
}