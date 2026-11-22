// a mote of alignment (gain_alignment): bursts out, then streams up to the compass marker, leaving a glowing trail.
// gain_alignment sets delay (frames before it shows), negative (+1 merciful / -1 ruthless) and col.
delay = 1;
negative = 1;
col = c_white;
order = 0; // its place in the stream: later motes chime higher (or lower, losing alignment)
var _dir = random(360);
var _spd = random_range(5, 10);
vx = lengthdir_x(_spd, _dir); // the first burst outwards
vy = lengthdir_y(_spd, _dir);
t = 0;                        // frames since it showed
size = random_range(5, 7.5);
trail = [];                   // where it has been, for the trail
spin = random(360);
phase = random(100);         // where its curl starts, so the motes in a stream curl differently
