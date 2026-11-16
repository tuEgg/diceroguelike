// used for loading game
if (global.loading_game) {
	load_game(1);
	global.loading_game = false;
} else {
	// a new run starts by choosing one die and core pair (F04), before drafting pages
	new_run_offering = true;
	global.ui_layer = UI_LAYER.POPUP;
}