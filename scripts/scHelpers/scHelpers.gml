/// @function array_contains(_array, _value)
/// @returns {bool} true if value found in array
function array_contains(_array, _value) {
    for (var i = 0; i < array_length(_array); i++) {
        if (_array[i] == _value) return true;
    }
    return false;
}

/// @function choose_weighting(...)

function choose_weighting_list(list) {
    var total = 0;

    // sum weights
    for (var i = 0; i < array_length(list); i++) {
        total += list[i].weight;
    }

    var roll = random(total);
    var cumulative = 0;

    for (var i = 0; i < array_length(list); i++) {
        cumulative += list[i].weight;
        if (roll <= cumulative) return list[i].value;
    }

    return list[0].value; // fallback
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

/// @function draw_outline_text(_string, _outline_col, _fill_col, _outline_width, _x, _y, _scale, _alpha, _angle, _max_length)
function draw_outline_text(_string, _outline_col, _fill_col, _outline_width, _x, _y, _scale, _alpha, _angle = 0, _max_length = -1) {
	// Outline
    draw_set_alpha(_alpha * 0.6);
    draw_set_color(_outline_col);
    for (var ox = -_outline_width; ox <= _outline_width; ox++) {
        for (var oy = -_outline_width; oy <= _outline_width; oy++) {
            if (ox != 0 || oy != 0) {
				if (_max_length == -1) {
					draw_text_transformed(_x + ox, _y + oy, _string, _scale, _scale, _angle);
				} else {
					draw_text_ext_transformed(_x + ox, _y + oy, _string, font_get_size(draw_get_font()) * 1.2, _max_length, _scale, _scale, _angle);
				}
			}
        }
    }

    // Main text
    draw_set_alpha(_alpha);
    draw_set_color(_fill_col);
	if (_max_length == -1) {
		draw_text_transformed(_x, _y, _string, _scale, _scale, _angle);
	} else {
		draw_text_ext_transformed(_x, _y, _string, font_get_size(draw_get_font()) * 1.2, _max_length, _scale, _scale, _angle);
	}

    draw_set_alpha(1);
}

function runmanager_trigger_keepsakes(_event, _data) {
    for (var i = 0; i < ds_list_size(oRunManager.keepsakes); i++)
    {
        var ks = oRunManager.keepsakes[| i];
        if (is_undefined(ks.trigger)) continue;

        // allow keepsakes to mutate _data
        ks.trigger(_event, _data);
    }
}

function trigger_bounty(_event, _data) {
	if (oRunManager.active_bounty != undefined && oWorldManager.current_node_type == NODE_TYPE.ELITE) {
	    var bounty = oRunManager.active_bounty;
	
	    if (is_undefined(bounty.condition.trigger)) return;

	    // allow bounty conditions to mutate _data
	    bounty.condition.trigger(_event, _data);
	}
}

function queue_tooltip(_x, _y, _name, _desc, _icon = undefined, _index = 0, _dice = undefined) {

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
            draw_single_tooltip(kw.x + 10, kw.y + 20, kw.name, kw.desc, kw.icon, kw.index);
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
		xx = _x + 15;
        yy = _y + 30;
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
	
	var gap_x;
	var gap_y;
	
	if (xx + _width > room_width) {
		gap_x = room_width - (xx + _width);
		xx += gap_x;
	}
	
	if (yy + _height > room_height) {
		gap_y = room_height - (yy + _height);
		yy += gap_y;
	}

    // Add icon room if present
    var icon_w = 0;
    if (_icon != undefined) {
        icon_w = sprite_get_width(_icon) + padding + padding;
        _width += icon_w;
    } else if (_dice != undefined) {
		if (_dice.distribution != "") {
			icon_w = sprite_get_width(sCores);
			_width += icon_w;
		}
	}

    // -------------------------------------------------------
    // DISTRIBUTION BARS
    // -------------------------------------------------------
	if (_dice != undefined) {
		if (_dice.distribution != "") {
			draw_dice_distribution(_dice, xx + 50, yy + 7);
		}
	}

    // -------------------------------------------------------
    // BACKGROUND
    // -------------------------------------------------------
    var col = make_color_rgb(20, 50, 80);
    draw_set_alpha(1);
	draw_set_color(c_black);
	var thickness = 3;
	draw_rectangle(xx - thickness, yy - thickness, xx + _width + thickness, yy + _height + thickness, false);
	draw_set_color(col);
	draw_rectangle(xx, yy, xx+_width, yy+_height, false);

    //draw_sprite_ext(
    //    sHoverBG, 0,
    //    xx, yy,
    //    _width / sprite_get_width(sHoverBG),
    //    _height / sprite_get_height(sHoverBG),
    //    0, col, 1
    //);

    // -------------------------------------------------------
    // ICON
    // -------------------------------------------------------
    if (_icon != undefined) {
		var yyy = yy + padding + 5 + sprite_get_height(_icon)/2;
		if (_icon == sMapIcon) {
			yyy -= sprite_get_height(_icon)/5;
		}
        draw_sprite_ext(
            _icon, _index,
            xx + sprite_get_width(_icon)/2 + padding,
            yyy,
            1, 1, 0, c_white, 1
        );
        xx += sprite_get_width(_icon) + padding;
    } else if (_dice != undefined) {
		// Draw core icon
		if (_dice.distribution != "") {
			var core_index = 0;
			switch (_dice.distribution) {
				case "weighted":	core_index = 0;		break;
				case "loaded":		core_index = 1;		break;
				case "edge":		core_index = 2;		break;
				case "binary":		core_index = 3;		break;
				case "bell":		core_index = 4;		break;
				case "dome":		core_index = 5;		break;
				case "odd":			core_index = 6;		break;
				case "even":		core_index = 7;		break;
				case "dual":		core_index = 8;		break;
				case "tower":		core_index = 9;		break;
			}
			draw_sprite_ext(
	            sCores, core_index,
	            xx + sprite_get_width(sCores)/2 + padding - 5,
	            yy + padding - 20 + sprite_get_height(sCores)/2,
	            0.75, 0.75, 0, c_white, 1
	        );
	        xx += sprite_get_width(sCores)*0.75 + padding;
		}
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

    // --- NORMALISE INPUTS ---
    var haystack = str;
    var needle   = string_upper(keyword);

    // --- 1. EXTRACT PREFIX BEFORE FIRST COLON ---
    var colon_pos = string_pos(":", haystack);
    if (colon_pos > 0) {
        haystack = string_copy(haystack, 1, colon_pos - 1);
    } 
    else 
    {
        // --- 2. NO COLON: REMOVE FINAL SENTENCE IF MULTIPLE ---
        var parts = string_split(haystack, ".");
        var count = array_length(parts);

        // Trim trailing empty parts from final period
        while (count > 0 && string_length(string_trim(parts[count - 1])) == 0) {
            count -= 1;
        }

        if (count > 1) {
            var prefix = "";
            for (var i = 0; i < count - 1; i++) {
                var p = string_trim(parts[i]);
                if (string_length(p) > 0) {
                    if (prefix != "") prefix += ". ";
                    prefix += p;
                }
            }
            haystack = prefix;
        }
    }

    // --- NORMALISE FOR SEARCH ---
    haystack = string_upper(haystack);

    // --- FINAL CHECK ---
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

        if ((string_pos(upper_key, upper_str) > 0) && upper_key != "COIN" && upper_key != "MULTITYPE") {
            array_push(list, key);
        }
    }

    return list;
}


/// @function mouse_hovering(_x, _y, _width, _height, _centered)
function mouse_hovering(_x, _y, _width, _height, _centered) {
	var mx = device_mouse_x_to_gui(0);
	var my = device_mouse_y_to_gui(0);
	
	//draw_set_colour(c_black);
	//draw_set_alpha(0.2);
	
	if (!_centered) {
		if (mx < _x + _width && mx > _x && my < _y + _height && my > _y) {
			if (debug_mode) {
				//draw_rectangle(_x, _y, _x + _width, _y + _height, false);
				//draw_set_alpha(1.0);
			}
			return true;
		}
	} else {
		if (mx < _x + _width/2 && mx > _x - _width/2 && my < _y + _height/2 && my > _y - _height/2) {
			if (debug_mode) {
				//draw_rectangle(_x - _width/2, _y - _height/2, _x + _width/2, _y + _height/2, false);
				//draw_set_alpha(1.0);
			}
			return true;
		}
	}
	
	return false;
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

function throw_error(_error_msg, _error_desc) {
	oRunManager.error_timer = 90;
	oRunManager.error_message = _error_msg;
	oRunManager.error_description = _error_desc;
}

/// @function draw_arc_thick_deg(x, y, r_inner, r_outer, start_deg, end_deg, steps)
/// @desc Draw a filled thick arc (donut slice) using degrees
function draw_arc_thick_deg(_x, _y, _r_inner, _r_outer, _start_deg, _end_deg, _steps)
{
    if (_steps <= 0) return;

    // Normalize to 0..360
    _start_deg = (_start_deg mod 360 + 360) mod 360;
    _end_deg   = (_end_deg   mod 360 + 360) mod 360;

    // Wraparound support: 300 -> 45 draws through 360
    if (_end_deg <= _start_deg) _end_deg += 360;

    var step = (_end_deg - _start_deg) / _steps;

    draw_primitive_begin(pr_trianglelist);

    for (var i = 0; i < _steps; i++)
    {
        var a0 = _start_deg + step * i;
        var a1 = _start_deg + step * (i + 1);

        var cos0 = dcos(a0);
        var sin0 = dsin(a0);
        var cos1 = dcos(a1);
        var sin1 = dsin(a1);

        // Outer arc points
        var ox0 = _x + cos0 * _r_outer;
        var oy0 = _y + sin0 * _r_outer;
        var ox1 = _x + cos1 * _r_outer;
        var oy1 = _y + sin1 * _r_outer;

        // Inner arc points
        var ix0 = _x + cos0 * _r_inner;
        var iy0 = _y + sin0 * _r_inner;
        var ix1 = _x + cos1 * _r_inner;
        var iy1 = _y + sin1 * _r_inner;

        // Quad between radii, split into two triangles
        // Tri 1: outer0 -> outer1 -> inner0
        draw_vertex(ox0, oy0);
        draw_vertex(ox1, oy1);
        draw_vertex(ix0, iy0);

        // Tri 2: inner0 -> outer1 -> inner1
        draw_vertex(ix0, iy0);
        draw_vertex(ox1, oy1);
        draw_vertex(ix1, iy1);
    }

    draw_primitive_end();
}

	/// @function draw_arc_thick_deg_gradient(x, y, r_inner, r_outer, start_deg, end_deg, steps, col_start, col_end, alpha)
function draw_arc_thick_deg_gradient(
    _x, _y,
    _r_inner, _r_outer,
    _start_deg, _end_deg,
    _steps,
    _col_start, _col_end,
    _alpha
)
{
    if (_steps <= 0) return;

    // Normalize to 0..360
    _start_deg = (_start_deg mod 360 + 360) mod 360;
    _end_deg   = (_end_deg   mod 360 + 360) mod 360;

    if (_end_deg <= _start_deg) _end_deg += 360;

    var total = _end_deg - _start_deg;
    var step  = total / _steps;

    draw_primitive_begin(pr_trianglelist);

    for (var i = 0; i < _steps; i++)
    {
        var a0 = _start_deg + step * i;
        var a1 = _start_deg + step * (i + 1);

        var t0 = i / _steps;
        var t1 = (i + 1) / _steps;

        var c0 = merge_colour(_col_start, _col_end, t0);
        var c1 = merge_colour(_col_start, _col_end, t1);

        var cos0 = dcos(a0);
        var sin0 = dsin(a0);
        var cos1 = dcos(a1);
        var sin1 = dsin(a1);

        // Outer
        var ox0 = _x + cos0 * _r_outer;
        var oy0 = _y + sin0 * _r_outer;
        var ox1 = _x + cos1 * _r_outer;
        var oy1 = _y + sin1 * _r_outer;

        // Inner
        var ix0 = _x + cos0 * _r_inner;
        var iy0 = _y + sin0 * _r_inner;
        var ix1 = _x + cos1 * _r_inner;
        var iy1 = _y + sin1 * _r_inner;

        // Triangle 1
        draw_vertex_color(ox0, oy0, c0, _alpha);
        draw_vertex_color(ox1, oy1, c1, _alpha);
        draw_vertex_color(ix0, iy0, c0, _alpha);

        // Triangle 2
        draw_vertex_color(ix0, iy0, c0, _alpha);
        draw_vertex_color(ox1, oy1, c1, _alpha);
        draw_vertex_color(ix1, iy1, c1, _alpha);
    }

    draw_primitive_end();
}

