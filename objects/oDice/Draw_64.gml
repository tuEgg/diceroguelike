draw_set_alpha(1);
draw_set_color(c_white);

attack_type_colours = {
    "ATK":  c_red,
    "BLK":  c_aqua,
    "HEAL": c_lime,
	"INTEL": make_colour_rgb(210, 210, 0),
};

// --- Split the incoming type string
var parts = string_split(possible_type, " ");
var total = array_length(parts);

// --- Collect valid colours
var colours = [];
var count = 0;

for (var i = 0; i < total; i++) {
    var token = string_upper(parts[i]);

    if (variable_struct_exists(attack_type_colours, token)) {
        array_push(colours, attack_type_colours[$ token]);
        count++;
    }
}

// --- Fallbacks and Pulsing Blends --------------------------------------

var blended;

if (count == 0) {
    blended = c_white;
}
else if (count == 1) {
    blended = colours[0];
}
else {
    // 2+ colours: pulse through all of them in a loop

    // Pulse speed (tweak to taste)
    var spd = 0.006;

    // Normalized sine wave from 0..1
    var t = (sin(current_time * spd) + 1) * 0.5;

    // Index selection: smoothly moves between colour slots
    // t spreads across (count-1) intervals
    var pos = t * (count - 1);

    var index_a = floor(pos);
    var index_b = min(index_a + 1, count - 1);

    var local_t = pos - index_a;

    // Blend between those two colours only
    blended = merge_colour(colours[index_a], colours[index_b], local_t);
}

image_blend = blended;

draw_sprite_ext(
    sprite_index,
    image_index,
    x,
    y,
    scale,
    scale,
    image_angle,
    image_blend,
    image_alpha
);

draw_set_font(ftDefault);
draw_set_halign(fa_center);
draw_set_valign(fa_top);
draw_outline_text(struct.name, c_black, c_white, 2, x, y + sprite_height/2 + 3, scale, image_alpha, 0);

// --- Draw effect keyword icons ---
draw_dice_keywords(struct, x, y, 1);

if (debug_mode) {
    draw_set_color(c_black);
	draw_set_font(ftDefault);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_alpha(1.0);
}

if mouse_hovering(x, y, sprite_width, sprite_height, true) {
	queue_tooltip(mouse_x, mouse_y, string(struct.name), string(struct.description), undefined, 0, struct);
	
	if (debug_mode) && (keyboard_check(vk_alt)) {
		var xx = 0;
		for (var i = 0; i < ds_list_size(struct.statistics.roll_history); i++) {
			xx = i * 20;
			draw_set_font(ftDefault);
			draw_outline_text(string(struct.statistics.roll_history[| i]), c_black, c_white, 2, x + xx, y - 100, 1, 1.0, 0);
		}
	}
}