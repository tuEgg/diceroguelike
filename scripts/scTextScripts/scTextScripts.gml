/// draw_colored_text(x, y, text)
function draw_colored_text(_x, _y, _str) {
    var words = string_split(_str, " ");
    var draw_x = _x;
    var spacing = 4; // space between words

    for (var i = 0; i < array_length(words); i++) {
        var w = words[i];
        var lw = string_lower(w); // lowercase for matching

        // --- Keyword color rules ---
        if (string_pos("damage", lw) > 0 || string_pos("takes", lw) > 0) {
            draw_set_color(c_red);
        } 
        else if (string_pos("heal", lw) > 0) {
            draw_set_color(c_lime);
        } 
        else if (string_pos("block", lw) > 0 || string_pos("defend", lw) > 0 || string_pos("BLK", lw) > 0) {
            draw_set_color(c_aqua);
        } 
        else if (string_pos("attack", lw) > 0 || string_pos("atk", lw) > 0) {
            draw_set_color(make_color_rgb(255, 180, 0)); // gold/orange
        } 
        else {
            draw_set_color(c_white);
        }

        draw_text(draw_x, _y, w);
        draw_x += string_width(w) + spacing;
    }
}
