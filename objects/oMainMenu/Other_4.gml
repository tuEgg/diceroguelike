if (room == rmMainMenu) {
	if (instance_exists(oRunManager)) instance_destroy(oRunManager);
	if (instance_exists(oWorldManager)) instance_destroy(oWorldManager);
	if (instance_exists(oBountyController)) instance_destroy(oBountyController);
}