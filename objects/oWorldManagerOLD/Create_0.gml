node_list = ds_list_create();
map_length = 7;
current_node = undefined;
node_enemy = undefined;
nodes_cleared = 0;
time = 0; // used to pulse animate next node

enum NODE_TYPE {
	COMBAT = 0,
	WORKBENCH = 1,
	SOCIAL = 2,
	SHOP = 3,
	EVENT = 4,
	BOSS = 5
}

var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

// create nodes until the node_list is the size of map_length
for (var i = 0; i < map_length; i++) {
	
	// count the node size so far, to set the ids
	var count = ds_list_size(node_list);
	var xx = gui_w / 2 + tan(count) * 30;
	var yy = gui_h - 100 - (i*130);

	
	// create a node, randomise the room type
	var node_type = NODE_TYPE.COMBAT;
	var _room = rmCombat;
	var _enemy = enemy_find_by_name(choose("Deckhand", "Thug", "Corsair Gunner"));
	switch (i) {
		case 1:
		node_type = choose_weighting(NODE_TYPE.COMBAT, 0.7, NODE_TYPE.EVENT, 0.3);
		break;
		case 2:
		node_type = choose_weighting(NODE_TYPE.COMBAT, 0.5, NODE_TYPE.EVENT, 0.5);
		break;
		case 3:
		node_type = NODE_TYPE.SHOP;
		break;
		case 4:
		node_type = choose_weighting(NODE_TYPE.COMBAT, 0.4, NODE_TYPE.EVENT, 0.6);
		break;
		case 5:
		node_type = NODE_TYPE.WORKBENCH;
		break;
		case 6:
		node_type = NODE_TYPE.BOSS;
		break;
		default:
		node_type = NODE_TYPE.COMBAT;
	}
	if node_type = NODE_TYPE.SHOP _room = rmShop;
	if node_type = NODE_TYPE.WORKBENCH _room = rmWorkbench;
	if node_type = NODE_TYPE.BOSS _enemy = enemy_find_by_name("Barnacle Titan");
	var node = create_node(string(count), node_type, xx, yy, _room, _enemy);
	
	// connect to previous nodes
	if (count > 0) {
		ds_list_add(node.connections, node_list[| i-1] );
	}
	
	// add the node to the list
	ds_list_add(node_list, node);
}