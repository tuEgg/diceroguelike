/// @function array_contains(_array, _value)
/// @returns {bool} true if value found in array
function array_contains(_array, _value) {
    for (var i = 0; i < array_length(_array); i++) {
        if (_array[i] == _value) return true;
    }
    return false;
}

/// @function choose_weighting(...)
/// @description Returns one of the given values based on their relative weights.
/// Example:
/// node_type = choose_weighting("combat", 0.8, "event", 0.2);
///
/// You can add as many as you want:
/// reward = choose_weighting("credits", 0.6, "relic", 0.3, "heal", 0.1);

function choose_weighting() {
    var arg_count = argument_count;

    if (arg_count < 2 || arg_count mod 2 != 0) {
        show_debug_message("⚠️ choose_weighting: must have even number of arguments (value, weight pairs)");
        return undefined;
    }

    var total_weight = 0;
    for (var i = 1; i < arg_count; i += 2) {
        total_weight += argument[i];
    }

    var roll = random(total_weight);
    var cumulative = 0;

    for (var i = 0; i < arg_count; i += 2) {
        var val = argument[i];
        var weight = argument[i + 1];
        cumulative += weight;
        if (roll <= cumulative) return val;
    }

    // fallback (should never happen)
    return argument[0];
}

/// @function draw_gui_button(_x, _y, _base_w, _base_h, _scale_ref, _text, _color, _font, _active, _draw_rext)
/// @desc Draws a hoverable, animated GUI button. Returns a struct: {hover, click, scale, x, y, w, h}
///
/// @param _x          The X position (top-left)
/// @param _y          The Y position
/// @param _base_w     The base width
/// @param _base_h     The base height
/// @param _scale_ref  The current scale value (pass a variable you update each frame)
/// @param _text       The text to draw
/// @param _color      The main color
/// @param _font       The font
/// @param _active     Whether the button is active (true/false)
/// @param _draw_rect  Whether to draw the rectangle behind (true/false)
///
/// @returns { hover: bool, click: bool, scale: real, x: real, y: real, w: real, h: real }

function draw_gui_button(_x, _y, _base_w, _base_h, _scale_ref, _text, _color, _font, _active, _draw_rect)
{
    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);

    var scale = _scale_ref;
    var w = _base_w * scale;
    var h = _base_h * scale;
    var draw_x = _x + ((_base_w - w) / 2);
    var draw_y = _y + ((_base_h - h) / 2);

    // Hover & click
    var hover = (mx > draw_x && mx < draw_x + w && my > draw_y && my < draw_y + h && _active);
    var click = hover && mouse_check_button_pressed(mb_left);

    // Smooth hover animation
    var target_scale = hover ? 1.2 : 1.0;
    scale = lerp(scale, target_scale, 0.2);

    // --- Draw background ---
	if (_draw_rect) {
	    draw_set_alpha(_active ? 1.0 : 0.25);
	    draw_set_color(_color);
	    draw_rectangle(draw_x, draw_y, draw_x + w, draw_y + h, false);
	}

    // --- Draw text ---
    draw_set_alpha(_active ? 1.0 : 0.4);
    draw_set_font(_font);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_white);
    draw_text(draw_x + w / 2, draw_y + h / 2, _text);
    draw_set_alpha(1);

    return {
        hover: hover,
        click: click,
        scale: scale,
        x: draw_x,
        y: draw_y,
        w: w,
        h: h
    };
}

/// @function draw_outline_text(_string, _outline_col, _fill_col, _outline_width, _x, _y, _scale, _alpha, _angle)
function draw_outline_text(_string, _outline_col, _fill_col, _outline_width, _x, _y, _scale, _alpha, _angle = 0) {
	
	// Outline
    draw_set_alpha(_alpha * 0.6);
    draw_set_color(_outline_col);
    for (var ox = -_outline_width; ox <= _outline_width; ox++) {
        for (var oy = -_outline_width; oy <= _outline_width; oy++) {
            if (ox != 0 || oy != 0)
                draw_text_transformed(_x + ox, _y + oy, _string, _scale, _scale, _angle);
        }
    }

    // Main text
    draw_set_alpha(_alpha);
    draw_set_color(_fill_col);
    draw_text_transformed(_x, _y, _string, _scale, _scale, _angle);

    draw_set_alpha(1);
}

function runmanager_trigger_keepsakes(_event, _data)
{
    for (var i = 0; i < ds_list_size(oRunManager.keepsakes); i++)
    {
        var ks = oRunManager.keepsakes[| i];
        if (is_undefined(ks.trigger)) continue;

        // allow keepsakes to mutate _data
        ks.trigger(_event, _data);
    }
}

function queue_tooltip(_x, _y, _name, _desc, _icon, _index, _dice) {

    // If no main tooltip exists yet, set this one as the main tooltip
    if (!global.tooltip_active) {

        global.tooltip_active = true;

        global.tooltip_main = {
            x: _x,
            y: _y,
            name: _name,
            desc: _desc,
            icon: _icon,
            index: _index,
			dice: _dice
        };

        // Clear previous keyword tooltips
        global.tooltip_keywords = [];

        // Parse description for keywords and immediately queue keyword tooltips
        var key_array = variable_struct_get_names(global.keywords);

        var ky = 92; // offset below main tooltip

        for (var k = 0; k < array_length(key_array); k++) {
            var key = key_array[k];

            if (string_has_keyword(_desc, key)) {

                var data = global.keywords[$ key];

                array_push(global.tooltip_keywords, {
                    x: _x + 10,
                    y: _y + ky,
                    name: key,
                    desc: data.desc,
                    icon: sKeywordIcons,
                    index: data.index
                });

                ky += 72;
            }
        }
    }
}

function draw_all_tooltips() {

    if (global.tooltip_active) {

        //--------------------------
        // Draw main tooltip
        //--------------------------
        var tt = global.tooltip_main;
        draw_single_tooltip(tt.x, tt.y, tt.name, tt.desc, tt.icon, tt.index, tt.dice);

        //--------------------------
        // Draw keyword tooltips under it
        //--------------------------
        for (var i = 0; i < array_length(global.tooltip_keywords); i++) {
            var kw = global.tooltip_keywords[i];
            draw_single_tooltip(kw.x, kw.y, kw.name, kw.desc, kw.icon, kw.index);
        }
    }

    // Reset for next frame
    global.tooltip_active = false;
    global.tooltip_main = undefined;
    global.tooltip_keywords = [];
}

function draw_single_tooltip(_x, _y, _name, _desc, _icon, _index, _dice = undefined) {
    
    var padding = 15;
    var xx = _x;
    var yy = _y;

    // Offset tooltip if hovering directly on the mouse
    if (_y == mouse_y) {
        yy = _y + 20;
    }

    // -------------------------------------------------------
    // MEASURE NAME + DESCRIPTION
    // -------------------------------------------------------
    draw_set_font(ftDefault);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    var name_w = string_width(_name);
    var name_h = string_height(_name);

    draw_set_font(ftSmall);
    var desc_w = string_width(_desc);
    var desc_h = string_height(_desc);

    // -------------------------------------------------------
    // BASE WIDTH / HEIGHT
    // -------------------------------------------------------
    var _width  = padding * 2 + max(name_w, desc_w);
    var _height = padding * 2 + name_h + desc_h;

    // Add icon room if present
    var icon_w = 0;
    if (_icon != undefined) {
        icon_w = sprite_get_width(_icon) + padding + padding;
        _width += icon_w;
    }

    // -------------------------------------------------------
    // DISTRIBUTION BARS
    // -------------------------------------------------------
	if (_dice != undefined) {
		draw_dice_distribution(_dice, xx, yy);
	}

    // -------------------------------------------------------
    // BACKGROUND
    // -------------------------------------------------------
    var col = make_color_rgb(20, 50, 80);
    draw_set_alpha(1);

    draw_sprite_ext(
        sHoverBG, 0,
        xx, yy,
        _width / sprite_get_width(sHoverBG),
        _height / sprite_get_height(sHoverBG),
        0, col, 1
    );

    // -------------------------------------------------------
    // ICON
    // -------------------------------------------------------
    if (_icon != undefined) {
        draw_sprite_ext(
            _icon, _index,
            xx + sprite_get_width(_icon)/2 + padding,
            yy + padding + 5 + sprite_get_height(_icon)/2,
            1, 1, 0, c_white, 1
        );
        xx += sprite_get_width(_icon) + padding;
    }

    // -------------------------------------------------------
    // NAME
    // -------------------------------------------------------
    draw_set_color(c_white);
    draw_set_font(ftDefault);
    draw_text(xx + padding, yy + padding, string(_name));

    // -------------------------------------------------------
    // DESCRIPTION (with keyword colour parsing)
    // -------------------------------------------------------
    draw_set_font(ftSmall);

    var parsed = parse_text_with_keywords(_desc);
    var cursor_x = xx + padding;
    var cursor_y = yy + padding + name_h;

    for (var i = 0; i < array_length(parsed); i++) {
        draw_set_colour(parsed[i].colour);
        draw_text(cursor_x, cursor_y, parsed[i].text);
        cursor_x += string_width(parsed[i].text);
    }

    // IMPORTANT:
    // No recursive keyword tooltips here.
    // Keyword tooltips are queued externally.
}

/// @func string_has_keyword(str, keyword)
/// @desc Returns true if `keyword` appears inside `str` (case-insensitive)
function string_has_keyword(str, keyword) {
    if (is_undefined(str) || is_undefined(keyword)) return false;

    var haystack = string_upper(str);
    var needle   = string_upper(keyword);

    // string_pos returns 0 if not found, 1+ if found
    return (string_pos(needle, haystack) > 0);
}

/// @func get_keywords_in_string(str)
/// @returns array of keyword names appearing in the string
function get_keywords_in_string(str) {
    var list = [];
    var key_array = variable_struct_get_names(global.keywords);

    var upper_str = string_upper(str);

    for (var k = 0; k < array_length(key_array); k++) {
        var key = key_array[k];
        var upper_key = string_upper(key);

        if (string_pos(upper_key, upper_str) > 0) {
            array_push(list, key);
        }
    }

    return list;
}


/// @function mouse_hovering(_x, _y, _width, _height, _centered)
function mouse_hovering(_x, _y, _width, _height, _centered) {
	var mx = device_mouse_x(0);
	var my = device_mouse_y(0);
	
	if (!_centered) {
		if (mx < _x + _width && mx > _x && my < _y + _height && my > _y) return true;
	} else {
		if (mx < _x + _width/2 && mx > _x - _width/2 && my < _y + _height/2 && my > _y - _height/2) return true;
	}
}

function parse_text(str) {
    var out = [];
    var current_colour = c_white;
    var buffer = "";

    var i = 1;
    var len = string_length(str);

    while (i <= len) {
        var ch = string_char_at(str, i);

        // Detect start of a tag
        if (ch == "[") {

            // Find the closing bracket - correct 2-argument string_pos
            var close_index = string_pos("]", string_copy(str, i, len - i + 1));

            if (close_index > 0) {
                // close_index is relative to the substring, so convert to absolute
                close_index = i + close_index - 1;

                // Flush buffered text before changing colour
                if (buffer != "") {
                    array_push(out, {
                        text: buffer,
                        colour: current_colour
                    });
                    buffer = "";
                }

                // Extract tag name
                var tag = string_copy(str, i + 1, close_index - i - 1);

                // Move index past the tag
                i = close_index;

                // Apply colour logic
                switch (tag) {
                    case "red": current_colour = c_red; break;
                    case "/red": current_colour = c_white; break;

                    case "yellow": current_colour = c_yellow; break;
                    case "/yellow": current_colour = c_white; break;

                    case "blue": current_colour = c_blue; break;
                    case "/blue": current_colour = c_white; break;

                    // Add your own tags here
                }
            }
            else {
                // no closing tag -> treat as normal character
                buffer += ch;
            }
        }
        else {
            buffer += ch;
        }

        i++;
    }

    // Add final buffer
    if (buffer != "") {
        array_push(out, {
            text: buffer,
            colour: current_colour
        });
    }

    return out;
}

/// @function parse_text_with_keywords(str, keywords)
/// @param str        The original string
///
/// Returns: array of { text: string, colour: colour }

function parse_text_with_keywords(str) {
	var keywords = global.keywords;

    // -----------------------------------------------
    // STEP 1 - Automatic Keyword Tagging
    // -----------------------------------------------

    // For each keyword, insert colour tags into str
	var key_array = variable_struct_get_names(keywords);
	var count = array_length(key_array);

	for (var k = 0; k < count; k++) {
	    var key = key_array[k];

	    // BEFORE: var colour = keywords[$ key];
	    // NOW: extract the .colour field from the struct
	    var colour = keywords[$ key].colour;

	    // Convert the colour to a tag name we can refer back to
	    var colour_tag = "__tag_" + string(colour);

	    var open_tag  = "[" + colour_tag + "]";
	    var close_tag = "[/" + colour_tag + "]";

	    str = string_replace_all(str, key, open_tag + key + close_tag);
	}


    // -----------------------------------------------
    // STEP 2 - Parse BBCode-Style Tags
    // -----------------------------------------------

    var out = [];
    var current_colour = c_white;
    var buffer = "";

    var i = 1;
    var len = string_length(str);

    while (i <= len) {
        var ch = string_char_at(str, i);

        if (ch == "[") {

            // Find closing bracket using correct 2-arg string_pos
            var remaining = string_copy(str, i, len - i + 1);
            var temp_pos = string_pos("]", remaining);

            if (temp_pos > 0) {
                var close_index = i + temp_pos - 1;

                // Flush buffer before changing colour
                if (buffer != "") {
                    array_push(out, { text: buffer, colour: current_colour });
                    buffer = "";
                }

                // Extract tag
                var tag = string_copy(str, i + 1, close_index - i - 1);

                // Move parser forward
                i = close_index;

                // -----------------------------------------------
                // TAG HANDLING
                // -----------------------------------------------

                if (string_starts_with(tag, "__tag_")) {
                    // Opening tag: "__tag_<number>"
                    var col_value = real(string_replace(tag, "__tag_", ""));
                    current_colour = col_value;

                } else if (string_starts_with(tag, "/__tag_")) {
                    // Closing tag
                    current_colour = c_white;

                } else {
                    // You can add manual tags like [red] if you want
                    switch(tag) {
                        case "red": current_colour = c_red; break;
                        case "/red": current_colour = c_white; break;
                    }
                }

            } else {
                buffer += ch;
            }
        }
        else {
            buffer += ch;
        }

        i++;
    }

    // Push trailing buffer
    if (buffer != "") {
        array_push(out, { text: buffer, colour: current_colour });
    }

    return out;
}