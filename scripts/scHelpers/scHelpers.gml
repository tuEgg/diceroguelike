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

function draw_gui_button(_x, _y, _base_w, _base_h, _scale_ref, _text, _color, _font, _active, _draw_rect) {
	
	// this function needs to be deprecated soon as its leftover from when we originally first did buttons
    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);

    var scale = _scale_ref;
    var w = _base_w * scale;
    var h = _base_h * scale;
    var draw_x = _x + ((_base_w - w) / 2);
    var draw_y = _y + ((_base_h - h) / 2);

    // Hover & click
    var hover = (mx > draw_x && mx < draw_x + w && my > draw_y && my < draw_y + h && _active);
	
	if (global.main_input_disabled) hover = false;
	
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

function is_number_string(_s) {
    return string_digits(_s) == _s;
}

function clean_word(_w) {
    return string_lower(string_trim(_w, [".", ",", "!", "?", ":", ";"]));
}

function split_trailing_punct(_token) {
    var core = _token;
    var punct = "";

    while (string_length(core) > 0) {
        var last = string_char_at(core, string_length(core));
        if (last == "." || last == "," || last == "!" || last == "?" || last == ":" || last == ";") {
            punct = last + punct;
            core = string_delete(core, string_length(core), 1);
        } else {
            break;
        }
    }

    return [core, punct];
}

function colorcode_text(_str) {

    var words = string_split(_str, " ");
    var wc = array_length(words);

    var tags = array_create(wc, "def");

    // --- Generic rule: keyword (always colour keyword; colour number too if present) ---
    for (var i = 0; i < wc; i++) {
        var parts = split_trailing_punct(words[i]);
        var core = parts[0];
        var w_clean = clean_word(core);

        for (var r = 0; r < array_length(global.COLOR_RULES); r++) {
            var rule = global.COLOR_RULES[r];

            if (rule.type == "num_keyword" && w_clean == rule.keyword) {
                tags[i] = rule.tag; // colour the keyword itself

                if (i > 0) {
                    var prev_parts = split_trailing_punct(words[i - 1]);
                    var prev_core = prev_parts[0];
                    if (is_number_string(prev_core)) {
                        tags[i - 1] = rule.tag;
                    }
                }
            }
        }
    }

    // --- Special case: HEALTH (supports "7 health" and "7 max health") ---
    for (var i = 0; i < wc; i++) {
        var parts_i = split_trailing_punct(words[i]);
        var core_i = parts_i[0];
        var w_clean = clean_word(core_i);

        if (w_clean == "health") {
            // Always tag health
            tags[i] = "health";

            // If previous word is "max", tag it
            var max_index = -1;
            if (i > 0) {
                var prev_parts = split_trailing_punct(words[i - 1]);
                var prev_core = prev_parts[0];
                if (clean_word(prev_core) == "max") {
                    tags[i - 1] = "health";
                    max_index = i - 1;
                }
            }

            // Tag the number: either before "max" if present, otherwise before "health"
            var num_index = (max_index != -1) ? (max_index - 1) : (i - 1);
            if (num_index >= 0) {
                var num_parts = split_trailing_punct(words[num_index]);
                var num_core = num_parts[0];
                if (is_number_string(num_core)) {
                    tags[num_index] = "health";
                }
            }
        }
    }

    // --- Keepsake range ("the"/"a" ... keepsake) ---
    for (var i = 0; i < wc; i++) {
        var parts_i = split_trailing_punct(words[i]);
        var core_i = parts_i[0];
        var w_clean = clean_word(core_i);

        if (w_clean == "keepsake") {
            var start = -1;

            for (var j = i - 1; j >= 0; j--) {
                var parts_j = split_trailing_punct(words[j]);
                var core_j = parts_j[0];
                var back_clean = clean_word(core_j);

                if (back_clean == "the" || back_clean == "a") {
                    start = j;
                    break;
                }
            }

            if (start != -1) {
                for (var t = start + 1; t <= i; t++) tags[t] = "keepsake";
            } else {
                tags[i] = "keepsake";
            }
        }
    }

    // --- Rebuild: punctuation always [def], and no leading space ---
    var out = "";
    var current_tag = ""; // Start empty to force the first tag to write

    for (var i = 0; i < wc; i++) {
        var parts = split_trailing_punct(words[i]);
        var core = parts[0];
        var punct = parts[1];

        // 1. Handle the Core Word Tag
        if (tags[i] != current_tag) {
            out += "[" + tags[i] + "]";
            current_tag = tags[i];
        }

        // 2. Add the word (and space if not first)
        if (i != 0) out += " ";
        out += core;

        // 3. Handle Punctuation (always switches back to def)
        if (punct != "") {
            if (current_tag != "def") {
                out += "[def]";
                current_tag = "def";
            }
            out += punct;
        }
    }

    if (current_tag != "def") out += "[def]";
    return out;
}


/// @function draw_outline_text(_string, _outline_col, _fill_col, _outline_width, _x, _y, _scale, _alpha, _angle, _max_length)
function draw_outline_text(_string, _outline_col, _fill_col, _outline_width, _x, _y, _scale, _alpha, _angle = 0, _max_length = -1) {
	var colored = false;
	
	if (string_pos("[", _string) > 0) colored = true;
	
	if (colored) {
		// Take the input string and turn it into an array 
		var input_string_array = string_split_ext(_string, ["[", "]"], true);
		
		var output_string_array = [];
		var colors_array = [];
		
		var xx = _x;
		var yy = _y;
		
		// Assin that array to an array of string parts and an array of color parts
		for (var i = 0; i < array_length(input_string_array); i++) {
			
			if (i mod 2 == 1) {
				array_push(output_string_array, input_string_array[i]);
			} else {
				var col = _fill_col;
				switch (input_string_array[i]) {
					case "gold":		case "coin":							col = c_yellow;					break;
					case "stowaway":						col = c_aqua;					break;
					case "keepsake":											col = c_orange;					break;
					case "followthrough":										col = c_red;					break;
					case "luck":	case "favourite":	case "health":			col = c_lime;					break;
					case "dice":		case "exclusive":						col = c_teal;					break;
					case "ltgray":												col = c_ltgray;					break;
					case "sticky":												col = c_ltgray;					break;
					case "multitype":											col = c_silver;					break;
					case "alignment":											col = make_colour_rgb(230, 50, 230)	break;
					case "block":												col = global.color_block;		break;
					case "heal":												col = global.color_heal;		break;
					case "attack":												col = global.color_attack;		break;
					case "intel":												col = global.color_intel;		break;
					case "subtext":												col = c_gray;					break;
					default:													col = _fill_col;
				}
				array_push(colors_array, col);
			}
		}
		
		var line_h = font_get_size(draw_get_font()) * 1.5;
		var x0 = _x;
		var x1 = _x + _max_length;

		for (var i = 0; i < array_length(output_string_array); i++) {
		    var col = colors_array[i];
		    var chunk = output_string_array[i];

		    // Split chunk into words
		    var words = string_split(chunk, " ");
		    var wc = array_length(words);

		    for (var w = 0; w < wc; w++) {
		        var word = words[w];

		        // Re-add the space after each word except the last
		        var piece = (w < wc - 1) ? (word + " ") : word;

		        // Width of this piece
		        var pw = string_width(piece) * _scale;

		        // If this piece doesn't fit and we're not at line start, wrap
		        if (xx + pw > x1 && xx > x0) {
		            xx = x0;
		            yy += line_h;
		        }

		        // Draw outline
		        draw_set_alpha(_alpha * 0.6);
		        draw_set_color(_outline_col);
		        for (var ox = -_outline_width; ox <= _outline_width; ox++) {
		            for (var oy = -_outline_width; oy <= _outline_width; oy++) {
		                if (ox != 0 || oy != 0) {
		                    draw_text_transformed(xx + ox, yy + oy, piece, _scale, _scale, _angle);
		                }
		            }
		        }

		        // Draw main
		        draw_set_alpha(_alpha);
		        draw_set_color(col);
		        draw_text_transformed(xx, yy, piece, _scale, _scale, _angle);

		        // Advance cursor
		        xx += pw;
		    }
		}

	} else {
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
    if (!global.tooltip_active) {
        global.tooltip_active = true;

        global.tooltip_main = {
            x: _x, y: _y, name: _name, desc: _desc,
            icon: _icon, index: _index, dice: _dice
        };

        global.tooltip_keywords = [];

        // 1. Measure the Main Tooltip height to find where the first keyword starts
        draw_set_font(ftDefault);
        var _h_name = string_height(_name);
        draw_set_font(ftDescriptions);
        var _h_desc = string_height_ext(_desc, -1, 300);
        var current_ky = _h_name + _h_desc + 65; // 30 is base padding/gap

        var key_array = variable_struct_get_names(global.keywords);

        for (var k = 0; k < array_length(key_array); k++) {
            var key = key_array[k];

            if (string_has_keyword(_desc, key)) {
                var data = global.keywords[$ key];

                array_push(global.tooltip_keywords, {
                    x: _x + 10,
                    y: _y + current_ky,
                    name: key,
                    desc: data.desc,
                    icon: sKeywordIcons,
                    index: data.index
                });

                // 2. Measure THIS keyword's height to find where the NEXT one starts
                // This ensures they never overlap regardless of description length
                draw_set_font(ftDefault);
                var _kw_name_h = string_height(key);
                draw_set_font(ftDescriptions);
                var _kw_desc_h = string_height_ext(data.desc, -1, 200);
                
                current_ky += (_kw_name_h + _kw_desc_h + 25); // 25 is the gap between tooltips
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
        draw_single_tooltip(tt.x, tt.y, tt.name, tt.desc, tt.icon, tt.index, tt.dice, false);

        //--------------------------
        // Draw keyword tooltips under it
        //--------------------------
        for (var i = 0; i < array_length(global.tooltip_keywords); i++) {
            var kw = global.tooltip_keywords[i];
            draw_single_tooltip(kw.x + 5, kw.y + 10, kw.name, kw.desc, kw.icon, kw.index, undefined, true);
        }
    }

    // Reset for next frame
    global.tooltip_active = false;
    global.tooltip_main = undefined;
    global.tooltip_keywords = [];
}

function draw_single_tooltip(_x, _y, _name, _desc, _icon, _index, _dice = undefined, _is_keyword = false) {
    var padding = 15;
    var xx = _x;
    var yy = _y;

    if (_y == mouse_y) {
        xx = _x + 15;
        yy = _y + 30;
    }

    // --- 1. MEASURE NAME ---
    draw_set_font(ftDefault);
    var name_w = string_width(_name);
    var name_h = string_height(_name);

    // --- 2. THE "LONGEST LINE" APPROACH ---
    draw_set_font(ftDescriptions);
    var max_desc_w = 300;
    
    var words = string_split(_desc, " ");
    var longest_line_px = 0;
    var current_line_str = "";

    for (var i = 0; i < array_length(words); i++) {
        var word = words[i];
        // Create a temporary string to see if the next word fits
        var test_string = (current_line_str == "") ? word : (current_line_str + " " + word);
        
        if (string_width(test_string) <= max_desc_w) {
            // It fits, so this is our new current line
            current_line_str = test_string;
        } else {
            // It doesn't fit! The current_line_str (before the new word) is a finished line.
            longest_line_px = max(longest_line_px, string_width(current_line_str));
            // Start the next line with the word that didn't fit
            current_line_str = word;
        }
    }
    // Check the very last line after the loop finishes
    longest_line_px = max(longest_line_px, string_width(current_line_str));

    // Use the pixel-perfect width we just found
    var actual_desc_w = longest_line_px;

    // Use standard GML height measurement (matches your line-break logic)
    var line_sep = font_get_size(ftDescriptions) * 1.5;
    var desc_h = string_height_ext(_desc, line_sep, max_desc_w);

    // --- 3. DYNAMIC BOX SIZING ---
    var icon_space = (_icon != undefined || (_dice != undefined && _dice.distribution != "")) ? 50 : 0;
    var dist_h = (_dice != undefined && variable_struct_exists(_dice, "distribution") && _dice.distribution != "") ? 25 : 0;

    var _width  = padding * 2 + max(name_w, actual_desc_w) + icon_space;
    var _height = padding * 1.6 + name_h + desc_h + 10;

    // Screen Clamping
    if (xx + _width > room_width) xx = room_width - _width - 10;
    if (yy + _height > room_height) yy = room_height - _height - 10;

    // --- 4. DRAW BACKGROUND ---
    draw_set_alpha(0.8);
    draw_set_color(c_black);
    draw_roundrect(xx - 2, yy - 2, xx + _width + 2, yy + _height + 2, false);
	
	var bg_col = _is_keyword ? make_color_rgb(20, 40, 70) : global.color_bg;
	if (oRunManager.error_timer == 0) {
		draw_set_color(bg_col);
	} else {
		draw_set_color(global.color_error);
	}
    draw_roundrect(xx, yy, xx + _width, yy + _height, false);
    draw_set_alpha(1);

    var content_x = xx + padding;

    // --- 5. DRAW ICON / CORE / DISTRIBUTION ---
    var icon_sprite = undefined;
    var icon_idx = 0;
    var icon_scale = 1;

    if (_icon != undefined) {
        icon_sprite = _icon;
        icon_idx = _index;
    } else if (_dice != undefined && variable_struct_exists(_dice, "distribution") && _dice.distribution != "") {
        icon_sprite = sCores;
        icon_idx = get_core_index(_dice);
        icon_scale = 0.75;
    }

    if (icon_sprite != undefined) {
        draw_sprite_ext(icon_sprite, icon_idx, content_x + 16, yy + (_height/2), icon_scale, icon_scale, 0, c_white, 1);
        if (_dice != undefined && variable_struct_exists(_dice, "distribution") && _dice.distribution != "") {
             draw_dice_distribution(_dice, content_x + 35, yy);
        }
        content_x += icon_space;
    }

    // --- 6. DRAW NAME ---
    draw_set_font(ftDefault);
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
	draw_outline_text(_name, c_black, c_white, 2, content_x, yy + padding, 1, 1, 0, max_desc_w);

    // --- 7. DRAW DESCRIPTION ---
    var colored_desc = colorcode_text(_desc);
    draw_set_font(ftDescriptions); 
    draw_outline_text(colored_desc, c_black, c_white, 1, content_x, yy + padding + name_h + 2, 1, 1, 0, max_desc_w);
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

/// @function mouse_hovering(_x, _y, _width, _height, _centered)
function mouse_hovering(_x, _y, _width, _height, _centered) {
	var mx = device_mouse_x_to_gui(0);
	var my = device_mouse_y_to_gui(0);
	
	// This disables inputs for anything when main_input_disabled is true and we aren't the oRunManager object
	if (global.main_input_disabled && id.object_index != oRunManager) {
		return false;
	}
	
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

function get_random_distribution() {
	return choose("weighted", "loaded", "edge", "binary", "bell", "dome", "odd", "even", "dual", "tower");
}

function get_core_index(_dice) {
	var core_index = -1;
	
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
	
	return core_index;
}