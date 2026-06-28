if (room == rmMainMenu) {
	menu[0].flag = save_exists(1); // recheck for save file in case it was deleted
	if (instance_exists(oRunManager)) instance_destroy(oRunManager);
	if (instance_exists(oWorldManager)) instance_destroy(oWorldManager);
	if (instance_exists(oBountyController)) instance_destroy(oBountyController);
	
	global.ui_layer = UI_LAYER.BASE;
}