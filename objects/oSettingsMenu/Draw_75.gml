// the game's own mouse pointer on the main menu; during a run oRunManager draws it, last of all (its Draw GUI End)
if (!instance_exists(oRunManager)) {
	room_wipe_draw(); // the room's opening ink wash (F65)
	cursor_draw();
}
