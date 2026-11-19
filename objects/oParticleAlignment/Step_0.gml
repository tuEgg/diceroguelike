// waiting its turn in the ripple
if (delay > 0) {
	delay--;
	exit;
}
t++;
spin += 9;

// the marker it's heading for (it moves as other motes land)
var _tgt = alignment_target();
var _tx = _tgt[0], _ty = _tgt[1];
var _dist = point_distance(x, y, _tx, _ty);

// a short burst that slows, then a pull home that grows stronger (and a little curl, so the stream isn't a straight line)
vx *= 0.9;
vy *= 0.9;
if (t > 8) {
	var _dir = point_direction(x, y, _tx, _ty) + 25 * sin(t / 6 + phase) * clamp(_dist / 400, 0, 1);
	var _pull = min(2.6, 0.3 + (t - 8) * 0.06);
	vx += lengthdir_x(_pull, _dir);
	vy += lengthdir_y(_pull, _dir);
	var _sp = point_distance(0, 0, vx, vy);
	if (_sp > 18) { vx *= 18 / _sp; vy *= 18 / _sp; }
}

array_push(trail, [x, y]);
if (array_length(trail) > 12) array_delete(trail, 0, 1);
x += vx;
y += vy;

// home: a little flash at the marker, which swells (oRunManager alignment_scale); Destroy moves the compass a step
if (t > 8 && _dist < max(16, point_distance(0, 0, vx, vy))) {
	particle_emit(_tx, _ty, "burst", col, 4);
	with (oRunManager) alignment_scale = max(alignment_scale, 1.35);
	instance_destroy();
}
// never lost: if it somehow wanders, it arrives anyway
if (t > game_get_speed(gamespeed_fps) * 4) instance_destroy();
