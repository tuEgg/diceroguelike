cutscenes = [
	{
		voiceover: sIntro,
		music: undefined,
		length: 19, // length in seconds
		seen: debug_skip_intro() || progress_get("intro_seen"), // plays once ever (progress.json); also skipped when run from GameMaker unless turned back on in F1 (Hotkeys tab)
		progress_key: "intro_seen", // marked in progress.json when it plays, so it never replays on a later launch
		triggers: [
			{
				variable: "room",
				value: rmMap
			}
		],
		scenes: [
			{
				image: sCutsceneIntro1,
				duration: 6,
			},
			{
				image: sBackgroundDefault,
				duration: 5,
			},
			{
				image: sCutsceneIntro1,
				duration: 4,
			},
			{
				image: sBackgroundDefault,
				duration: 4,
			},
		],
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
