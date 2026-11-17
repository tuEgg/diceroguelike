cutscenes = [
	{
		voiceover: undefined, // silent for now (was sIntro); Jared will add a new sound later
		music: undefined,
		length: 13, // length in seconds
		seen: debug_skip_intro() || progress_get("intro_seen"), // plays once ever (progress.json, Settings > Gameplay > Intro next run replays it); never in a debug run (F6)
		progress_key: "intro_seen", // marked in progress.json when it plays, so it never replays on a later launch
		triggers: [
			{
				variable: "room",
				value: rmMap
			}
		],
		// text on black, each line fading in after the one before (Draw GUI End); replaced the picture scenes
		lines: [
			"Like any good sailing story, this one begins with a book.",
			"Pages that tell of adventures from a bygone era.",
			"A captain that once sailed this ship.",
			"And how he changed its course, forever.",
		],
		line_start: 0.8,	// seconds before the first line
		line_gap: 2.2,		// seconds between one line starting and the next
		line_fade: 1.2,		// seconds each line takes to fade in
		scenes: [],
	}
];

cutscene_index = -1; // used to track which cutscene is currently active
scene_index = 0; // used to track which scene within that cutscene we are currently displaying the image for

enum CUTSCENE_STATE {
	STARTED,
	PLAYING,
	FINISHED
}

cutscene_state = CUTSCENE_STATE.FINISHED;
cutscene_timer = 0;
skip_timer = 0; // hold escape to skip cutscenes
skip_alpha = 0;
