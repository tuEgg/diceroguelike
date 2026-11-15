// This particle is persistent, so it can outlive the run it was spawned in
if (instance_exists(oRunManager)) {
	oRunManager.credits++;
	oRunManager.credits_scale += 0.03;
}