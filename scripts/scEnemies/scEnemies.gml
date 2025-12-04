// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function enemy_create(_name, _max_hp, _bounty, _moves_array, _move_order)
{
    var e = {
        name: _name,
        max_hp: _max_hp,
        current_hp: _max_hp,
        bounty: _bounty,
        moves: ds_list_create(),
		move_order: _move_order
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
	// TIER 1 — HUMAN ADVERSARIES
	// -------------------------------

	var deckhand_moves = [
	    { dice_amount: 1, dice_value: 6, action_type: "ATK", bonus_amount: 3, move_name: "Slash" }, // Slash
	    { dice_amount: 1, dice_value: 4, action_type: "BLK", bonus_amount: 4, move_name: "Duck" }  // Duck
	];
	var deckhand = enemy_create("Deckhand", 29, 15, deckhand_moves, "random");
	ds_list_add(global.enemy_list, deckhand);


	var thug_moves = [
	    { dice_amount: 2, dice_value: 4, action_type: "ATK", bonus_amount: 5, move_name: "Heavy Swing" }, // Heavy Swing
	    { dice_amount: 1, dice_value: 3, action_type: "DEBUFF", bonus_amount: 0, move_name: "Mock", debuff: debuff_mock }, // Mock
	    { dice_amount: 1, dice_value: 4, action_type: "BLK", bonus_amount: 4, move_name: "Parry" }  // Duck
	];
	var thug = enemy_create("Thug", 36, 17, thug_moves, "random");
	ds_list_add(global.enemy_list, thug);


	var gunner_moves = [
	    { dice_amount: 3, dice_value: 6, action_type: "BLK", bonus_amount: 0, move_name: "Aim" }, // Aim
	    { dice_amount: 3, dice_value: 4, action_type: "ATK", bonus_amount: 6, move_name: "Volley Fire" }, // Volley Fire
	    { dice_amount: 0, dice_value: 0, action_type: "NONE", bonus_amount: 0, move_name: "Reload" } // Reload
	];
	var gunner = enemy_create("Corsair Gunner", 30, 19, gunner_moves, "order");
	ds_list_add(global.enemy_list, gunner);


	var captain_moves = [
	    { dice_amount: 1, dice_value: 4, action_type: "BUFF", bonus_amount: 2 }, // Command
	    { dice_amount: 1, dice_value: 6, action_type: "BLK", bonus_amount: 3 }, // Parry
	    { dice_amount: 2, dice_value: 4, action_type: "ATK", bonus_amount: 3 } // Pistol Shot
	];
	var captain = enemy_create("Buccaneer Captain", 35, 24, captain_moves, "random");
	ds_list_add(global.enemy_list, captain);


	// -------------------------------
	// TIER 2 — SUPERNATURAL SAILORS
	// -------------------------------

	var mariner_moves = [
	    { dice_amount: 1, dice_value: 6, action_type: "ATK", bonus_amount: 2, move_name: "Salt Wound" }, // Salt Wound
	    { dice_amount: 1, dice_value: 4, action_type: "BLK", bonus_amount: 2, move_name: "Barnacle Shield" } // Barnacle Shield
	];
	var mariner = enemy_create("Cursed Mariner", 30, 15, mariner_moves, "random");
	ds_list_add(global.enemy_list, mariner);


	var thrall_moves = [
	    { dice_amount: 1, dice_value: 4, action_type: "DEBUFF", bonus_amount: 0, move_name: "Lure" }, // Lure
	    { dice_amount: 2, dice_value: 4, action_type: "ATK", bonus_amount: 2, move_name: "Rend" } // Rend
	];
	var thrall = enemy_create("Siren's Thrall", 32, 18, thrall_moves, "random");
	ds_list_add(global.enemy_list, thrall);


	var drowned_moves = [
	    { dice_amount: 2, dice_value: 4, action_type: "ATK", bonus_amount: 3, move_name: "Flooded Shot" }, // Flooded Shot
	    { dice_amount: 1, dice_value: 6, action_type: "DEATH", bonus_amount: 6, move_name: "Self-Destruct" } // Self-Destruct on death
	];
	var drowned = enemy_create("Drowned Gunner", 35, 25, drowned_moves, "random");
	ds_list_add(global.enemy_list, drowned);


	// -------------------------------
	// TIER 3 — SEA MONSTROSITIES
	// -------------------------------

	var titan_moves = [
	    { dice_amount: 2, dice_value: 6, action_type: "ATK", bonus_amount: 4, move_name: "Crushing Slam" }, // Crushing Slam
	    { dice_amount: 2, dice_value: 8, action_type: "BLK", bonus_amount: 5, move_name: "Harden Shell" }, // Harden Shell
	    { dice_amount: 1, dice_value: 6, action_type: "DEBUFF", bonus_amount: 0, move_name: "Barnacle Bind", debuff: debuff_bind } // Mock
	];
	var titan = enemy_create("Barnacle Titan", 125, 151, titan_moves, "random");
	ds_list_add(global.enemy_list, titan);


	var leviathan_moves = [
	    { dice_amount: 3, dice_value: 6, action_type: "MULTI_ATK", bonus_amount: 2, move_name: "Tail Lash" }, // Tail Lash
	    { dice_amount: 2, dice_value: 8, action_type: "ATK", bonus_amount: 5, move_name: "Tidal Crush" }, // Tidal Crush
	    // Multi-hit tail and wave attacks; floods action queue (temporarily blocks one slot).
	];
	var leviathan = enemy_create("Leviathan Spawn", 140, 40, leviathan_moves, "random");
	ds_list_add(global.enemy_list, leviathan);


	var maw_moves = [
	    { dice_amount: 3, dice_value: 8, action_type: "ATK", bonus_amount: 6, move_name: "Swallow Whole" }, // Swallow Whole
	    { dice_amount: 2, dice_value: 6, action_type: "MIRROR", bonus_amount: 0, move_name: "Echo the Depths" }, // Echo the Depths
	    { dice_amount: 1, dice_value: 10, action_type: "DEBUFF", bonus_amount: 0, move_name: "Drown Hope" } // Drown Hope
	];
	var maw = enemy_create("The Maw of the Deep", 130, 100, maw_moves, "random");
	ds_list_add(global.enemy_list, maw);
}