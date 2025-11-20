pages_turned = 0; // how many pages in the captains logbook have we cleared
time = 0; // used to pulse animate next node
page_previous = undefined;

enum PAGE_TYPE {
	COMBAT = 0,
	WORKBENCH = 1,
	SOCIAL = 2,
	SHOP = 3,
	EVENT = 4,
	BOSS = 5
}

room_enemy = undefined;

pages_shown = ds_list_create();
page_scale = ds_list_create();

page_combat = {
	type: PAGE_TYPE.COMBAT,
	enemy: enemy_find_by_name("Thug"),
	subimg: 1,
	text: "Brawl a dude",
	linked_room: rmCombat
};

page_shop = {
	type: PAGE_TYPE.SHOP,
	enemy: enemy_find_by_name("Thug"),
	subimg: 0,
	text: "Trade at port",
	linked_room: rmShop
};

page_workbench = {
	type: PAGE_TYPE.WORKBENCH,
	enemy: enemy_find_by_name("Thug"),
	subimg: 2,
	text: "Use the workbench",
	linked_room: rmWorkbench
};

page_boss = {
	type: PAGE_TYPE.BOSS,
	enemy: enemy_find_by_name("Barnacle Titan"),
	subimg: 1,
	text: "Fight the boss",
	linked_room: rmCombat
};

ds_list_add(pages_shown, page_combat);
