/// @function create_node(_id, _type, _pos_x, _pos_y, _room, _enemy)
function create_node(_id, _type, _pos_x, _pos_y, _room, _enemy) {
    return {
        node_id: _id,                    // unique identifier (e.g. "dan_01")
        node_type: _type,                // "combat", "shop", "event", etc.
        pos_x: _pos_x,                   // map position for drawing
        pos_y: _pos_y,
        connections: ds_list_create(),   // connected node IDs
        visited: false,                  // player visited?
        cleared: false,                  // encounter completed?
		scale: 1.0,						 // used for HUD scale
        data: undefined,                  // optional encounter-specific data (enemy set, rewards, etc.)
		room_link: _room,
		enemy: _enemy,
    };
}

/// @function node_find_by_id(_id)
function node_find_by_id(_id) {
    for (var i = 0; i < ds_list_size(node_list); i++) {
        var n = node_list[| i];
        if (n.node_id == _id) return n;
    }
    return undefined;
}

/// @function enemy_find_by_name(_name)
function enemy_find_by_name(_name) {
    for (var i = 0; i < ds_list_size(global.enemy_list); i++) {
        var n = global.enemy_list[| i];
        if (n.name == _name) return n;
    }
    return undefined;
}

function start_fight(_page) {
	_page.enemy = enemy_find_by_name("Deckhand"); // Should be Deckhand 
	if (_page.type == NODE_TYPE.COMBAT) { 
		if (pages_turned >= 1 && pages_turned <= 2) {
			_page.enemy = enemy_find_by_name(choose("Thug", "Deckhand"));
		}
		if (pages_turned >= 3 && pages_turned <= 4) {
			_page.enemy = enemy_find_by_name(choose("Thug", "Corsair Gunner", "Deckhand"));
		}
		if (pages_turned >= 5 && pages_turned <= 4) {
			_page.enemy = enemy_find_by_name(choose("Thug", "Corsair Gunner"));
		}
	} else if (_page.type == NODE_TYPE.BOSS) {
		_page.enemy = enemy_find_by_name("Barnacle Titan");
	}
	room_enemy = _page.enemy;
	room_goto(_page.linked_room);
}