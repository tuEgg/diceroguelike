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
        total += max(0, list[i].weight);
    }

    var roll = random(total);
    var cumulative = 0;

    for (var i = 0; i < array_length(list); i++) {
        if (list[i].weight <= 0) continue; // a weight of zero or less can never be picked
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

function draw_gui_button(_x, _y, _base_w, _base_h, _scale_ref, _text, _color, _font, _active, _draw_rect, _layer = UI_LAYER.BASE, _hover_sound = noone, _click_sound = soClick2, _disabled_reason = "", _use_font = false, _alpha = 1) {
	
	// this function needs to be deprecated soon as its leftover from when we originally first did buttons
    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);

    var scale = _scale_ref;
    var w = _base_w * scale;
    var h = _base_h * scale;
    var draw_x = _x + ((_base_w - w) / 2);
    var draw_y = _y + ((_base_h - h) / 2);

    // Hover & click
	var hover = false;
	
	if (_active && _alpha > 0.5) { // a button still fading in can't be pressed yet
		hover = mouse_hovering(draw_x, draw_y, w, h, false, _hover_sound, _click_sound, !global.all_input_disabled, _layer, string(_x) + "," + string(_y));
	}
	
    var click = hover && mouse_check_button_pressed(mb_left);

    // Smooth hover animation
    var target_scale = hover ? 1.2 : 1.0;
    scale = lerp(scale, target_scale, 0.2);

	// a greyed-out button can say why when hovered
	if (!_active && _disabled_reason != "" && global.ui_layer <= _layer && point_in_rectangle(mx, my, draw_x, draw_y, draw_x + w, draw_y + h)) {
		queue_tooltip(mx, my, "Not now", _disabled_reason);
	}

    // --- Draw background ---
	// (UI kit, phase 2) a soft ink shadow under it, it sinks a little while held, and a disabled button is a muted
	// version of its colour with readable text rather than see-through
	if (_draw_rect == true || (_draw_rect == "hover" && hover)) {
		var _held = hover && mouse_check_button(mb_left);
		var _sink = _held ? 3 : 0;
		var _fill = _active ? _color : merge_colour(_color, make_color_rgb(70, 70, 76), 0.65);
		var _bw = floor(w * scale), _bh = floor(h * scale);
		if (_active) draw_wonky_rectangle(draw_x + w/2 + 4, draw_y + h/2 + 6, _bw, _bh, c_black, c_black, (_held ? 0.15 : 0.3) * _alpha, true, false);
		draw_wonky_rectangle(draw_x + w/2, draw_y + h/2 + _sink, _bw, _bh, _fill, c_black, _alpha, true, _active);
		draw_set_color(c_white);
		draw_set_font(_use_font ? _font : ftDefault);
		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		draw_outline_text(_text, c_black, _active ? c_white : make_color_rgb(190, 186, 176), 2, draw_x + w/2, draw_y + h/2 + _sink, scale, (_active ? 1.0 : 0.85) * _alpha, 0);
	}

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

		// a tooltip asked for at the mouse sits at a fixed place beside the thing being hovered (its right edge, top
		// aligned; draw_all_tooltips flips it to the left near the screen edge), like Slay the Spire, so it never covers
		// what you're pointing at or wanders with the mouse
		if (!variable_global_exists("tooltip_frame")) global.tooltip_frame = 0;
		var _anchor = undefined;
		var _at_mouse = abs(_x - device_mouse_x_to_gui(0)) < 2 && abs(_y - device_mouse_y_to_gui(0)) < 2;
		if (_at_mouse) {
			if (variable_global_exists("hover_rect") && is_struct(global.hover_rect) && global.hover_rect.frame == global.tooltip_frame) {
				_anchor = global.hover_rect;
				_x = _anchor.x2 + 14 * global.ui_scale;
				_y = _anchor.y1;
				// things in the top bar get their tooltip just below the bar, lined up with them
				if (_anchor.y2 <= ui_top_bar_h() + 12) {
					_x = _anchor.x1;
					_y = ui_top_bar_h() + 8;
				}
			} else {
				_x += 30 * global.ui_scale;
				_y += 34 * global.ui_scale;
			}
		}

        global.tooltip_main = {
            x: _x, y: _y, name: _name, desc: _desc,
            icon: _icon, index: _index, dice: _dice,
            anchor: _anchor // the hovered rectangle it sits beside, or undefined
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

            // a die's own tooltip lists the keywords it has; any other text is searched for keyword words
            var _about_die = is_struct(_dice) && variable_struct_exists(_dice, "keywords") && variable_struct_exists(_dice, "description") && _desc == die_description(_dice);
            if (_about_die ? die_has_keyword(_dice, key) : string_has_keyword(_desc, key)) {
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
		// the main tooltip, with its keywords stacked tight underneath (each measured exactly, so no gaps), the whole
		// stack kept on screen
		var tt = global.tooltip_main;
		var _gap = 4;
		var _main = draw_tooltip_box(0, 0, tt.name, tt.desc, tt.icon, tt.index, tt.dice, false, true);
		var _total_h = _main.h;
		var _max_w = _main.w;
		var _kw_sizes = [];
		for (var i = 0; i < array_length(global.tooltip_keywords); i++) {
			var kw = global.tooltip_keywords[i];
			var _s = draw_tooltip_box(0, 0, kw.name, kw.desc, kw.icon, kw.index, undefined, true, true);
			array_push(_kw_sizes, _s);
			_total_h += _gap + _s.h;
			_max_w = max(_max_w, _s.w);
		}

		var xx = tt.x, yy = tt.y; // beside the hovered thing (queue_tooltip)
		// no room on the right of the hovered thing: put it on its left instead
		if (xx + _max_w > display_get_gui_width() - 10 && is_struct(tt.anchor)) xx = tt.anchor.x1 - 14 * global.ui_scale - _max_w;
		if (xx + _max_w > display_get_gui_width() - 10) xx = display_get_gui_width() - _max_w - 10;
		if (yy + _total_h > display_get_gui_height() - 10) yy = display_get_gui_height() - _total_h - 10;
		xx = max(10, xx); yy = max(10, yy);

		draw_tooltip_box(xx, yy, tt.name, tt.desc, tt.icon, tt.index, tt.dice, false, false);
		var _ky = yy + _main.h + _gap;
		for (var i = 0; i < array_length(global.tooltip_keywords); i++) {
			var kw = global.tooltip_keywords[i];
			draw_tooltip_box(xx + 12, _ky, kw.name, kw.desc, kw.icon, kw.index, undefined, true, false);
			_ky += _kw_sizes[i].h + _gap;
		}
    }

    // Reset for next frame
	if (variable_global_exists("tooltip_frame")) global.tooltip_frame++;
    global.tooltip_active = false;
    global.tooltip_main = undefined;
    global.tooltip_keywords = [];
}

/// @func draw_single_tooltip(_x, _y, _name, _desc, _icon, _index, _dice)
/// @desc One tooltip box on its own, kept on screen (the debug menu uses it).
function draw_single_tooltip(_x, _y, _name, _desc, _icon, _index, _dice = undefined, _is_keyword = false, _num_keywords = 0) {
	var _s = draw_tooltip_box(0, 0, _name, _desc, _icon, _index, _dice, _is_keyword, true);
	var xx = min(_x, display_get_gui_width() - _s.w - 10);
	var yy = min(_y, display_get_gui_height() - _s.h - 10);
	draw_tooltip_box(xx, yy, _name, _desc, _icon, _index, _dice, _is_keyword, false);
}

/// @func draw_tooltip_box(_x, _y, _name, _desc, _icon, _index, _dice, _compact, _measure_only)
/// @desc Draws one tooltip box at its top-left, or only measures it. Returns { w, h }. _compact is the smaller box used
///       for keywords under a main tooltip (tighter padding, narrower text).
function draw_tooltip_box(_x, _y, _name, _desc, _icon, _index, _dice, _compact, _measure_only) {
    var padding = _compact ? 12 : 20; // clear of the inner rule
    var max_desc_w = _compact ? 260 : 300;
    var xx = _x;
    var yy = _y;

    // name
    draw_set_font(_compact ? ftDescriptions : ftDefault);
    var name_w = string_width(_name);
    var name_h = string_height(_name);

    // the longest line the description wraps to
    draw_set_font(ftDescriptions);
    var words = string_split(_desc, " ");
    var longest_line_px = 0;
    var current_line_str = "";
    for (var i = 0; i < array_length(words); i++) {
        var test_string = (current_line_str == "") ? words[i] : (current_line_str + " " + words[i]);
        if (string_width(test_string) <= max_desc_w) {
            current_line_str = test_string;
        } else {
            longest_line_px = max(longest_line_px, string_width(current_line_str));
            current_line_str = words[i];
        }
    }
    longest_line_px = max(longest_line_px, string_width(current_line_str));
    var line_sep = font_get_size(ftDescriptions) * 1.5;
    var desc_h = (_desc == "") ? 0 : string_height_ext(_desc, line_sep, max_desc_w);

    var has_core = (_dice != undefined && variable_struct_exists(_dice, "distribution") && _dice.distribution != "");
    var icon_space = (_icon != undefined || has_core) ? (_compact ? 36 : 50) : 0;
    var _width  = padding * 2 + max(name_w, longest_line_px) + icon_space;
    var _height = padding * (_compact ? 1.4 : 1.6) + name_h + desc_h + (_compact ? 4 : 10);

	if (_measure_only) return { w: _width, h: _height };

    // background
    draw_set_alpha(0.85);
    draw_set_color(c_black);
    draw_roundrect(xx - 2, yy - 2, xx + _width + 2, yy + _height + 2, false);
	// logbook style: dark ink, a cream inner rule and small diamonds at the corners (keyword boxes a lighter touch)
	var bg_col = _compact ? make_color_rgb(34, 38, 50) : make_color_rgb(26, 30, 40);
	draw_set_color((oRunManager.error_timer == 0) ? bg_col : global.color_error);
    draw_roundrect(xx, yy, xx + _width, yy + _height, false);
    draw_set_alpha(1);
	var _rule = make_color_rgb(226, 212, 176);
	var _in = _compact ? 3 : 4;
	draw_set_color(_rule);
	draw_set_alpha(_compact ? 0.35 : 0.6);
	draw_roundrect(xx + _in, yy + _in, xx + _width - _in, yy + _height - _in, true);
	if (!_compact) {
		draw_set_alpha(0.9);
		var _d = 4;
		var _cx = [xx + _in, xx + _width - _in, xx + _in, xx + _width - _in];
		var _cy = [yy + _in, yy + _in, yy + _height - _in, yy + _height - _in];
		for (var c = 0; c < 4; c++) {
			draw_triangle(_cx[c] - _d, _cy[c], _cx[c], _cy[c] - _d, _cx[c] + _d, _cy[c], false);
			draw_triangle(_cx[c] - _d, _cy[c], _cx[c], _cy[c] + _d, _cx[c] + _d, _cy[c], false);
		}
	}
	draw_set_alpha(1);

    var content_x = xx + padding;

    // icon, or the die's core and its distribution
    var icon_sprite = undefined;
    var icon_idx = 0;
    var icon_scale = _compact ? 0.75 : 1;
    if (_icon != undefined) {
        icon_sprite = _icon;
        icon_idx = _index;
    } else if (has_core) {
        icon_sprite = sCores;
        icon_idx = get_core_index(_dice);
        icon_scale = 0.75;
    }
    if (icon_sprite != undefined) {
        draw_sprite_ext(icon_sprite, icon_idx, content_x + (_compact ? 10 : 16), yy + (_height / 2), icon_scale, icon_scale, 0, c_white, 1);
        if (has_core) draw_dice_distribution(_dice, content_x + 35, yy);
        content_x += icon_space;
    }

    // name (one line; the box is already wide enough), then the description
    draw_set_font(_compact ? ftDescriptions : ftDefault);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
	draw_outline_text(_name, c_black, _compact ? global.color_intel : c_white, 2, content_x, yy + padding, 1, 1, 0);
    draw_set_font(ftDescriptions);
    if (_desc != "") draw_outline_text(colorcode_text(_desc), c_black, c_white, 1, content_x, yy + padding + name_h + 2, 1, 1, 0, max_desc_w);

	return { w: _width, h: _height };
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

/// @function mouse_hovering(_x, _y, _width, _height, _centered, _hover_sound = noone, _click_sound = soClick4, _conditions_met = true, _layer = UI_LAYER.BASE, _id = undefined)
function mouse_hovering(_x, _y, _width, _height, _centered, _hover_sound = noone, _click_sound = soClick4, _conditions_met = true, _layer = UI_LAYER.BASE, _id = undefined) {

	var _hit = mouse_hovering_check(_x, _y, _width, _height, _centered, _hover_sound, _click_sound, _conditions_met, _layer, _id);
	if (_hit) {
		global.cursor_hover_time = current_time; // the custom cursor lights up over anything interactive
		// the thing under the mouse, so a tooltip can sit beside it (queue_tooltip)
		var _x1 = _centered ? _x - _width / 2 : _x;
		var _y1 = _centered ? _y - _height / 2 : _y;
		global.hover_rect = { x1: _x1, y1: _y1, x2: _x1 + _width, y2: _y1 + _height, frame: variable_global_exists("tooltip_frame") ? global.tooltip_frame : 0 };
	}
	return _hit;
}

function mouse_hovering_check(_x, _y, _width, _height, _centered, _hover_sound = noone, _click_sound = soClick4, _conditions_met = true, _layer = UI_LAYER.BASE, _id = undefined) {
	var mx = device_mouse_x_to_gui(0);
	var my = device_mouse_y_to_gui(0);
	
	var _sound_id = _id; // used for playing sound effects between different elements
	
	if (_sound_id == undefined) {
		_sound_id = string(_x) + "," + string(_y);
	}
	
	// This disables inputs for anything when main_input_disabled is true and we aren't the oRunManager object
	if (global.all_input_disabled && id.object_index != oRunManager) {
		return false;
	}
	
	if (!_conditions_met) return false;
	
	// (the top bar may be hovered under an open bag, for its tooltips only: global.ui_peek_top_bar)
	if (global.ui_layer > _layer && !(global.ui_layer == UI_LAYER.BAG && variable_global_exists("ui_peek_top_bar") && global.ui_peek_top_bar)) return false;
	
	//draw_set_colour(c_black);
	//draw_set_alpha(0.2);
	
	if (!_centered) {
		if (mx < _x + _width && mx > _x && my < _y + _height && my > _y) {
			if (debug_mode) {
				//draw_rectangle(_x, _y, _x + _width, _y + _height, false);
				//draw_set_alpha(1.0);
			}
			global.is_hovering = _sound_id;
			global.hovering_sound = _hover_sound;
			global.clicking_sound = _click_sound;
			return true;
		}
	} else {
		if (mx < _x + _width/2 && mx > _x - _width/2 && my < _y + _height/2 && my > _y - _height/2) {
			if (debug_mode) {
				//draw_rectangle(_x - _width/2, _y - _height/2, _x + _width/2, _y + _height/2, false);
				//draw_set_alpha(1.0);
			}
			global.is_hovering = _sound_id;
			global.hovering_sound = _hover_sound;
			global.clicking_sound = _click_sound;
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

// ----------------
// -- For saving --
// ----------------
function ds_list_to_array(_list) {
    var _arr = [];
    for (var i = 0; i < ds_list_size(_list); i++) {
        array_push(_arr, _list[| i]);
    }
    return _arr;
}

function array_to_ds_list(_arr) {
    var _list = ds_list_create();
    for (var i = 0; i < array_length(_arr); i++) {
        ds_list_add(_list, _arr[i]);
    }
    return _list;
}

function deserialise_die(_data) {
    var _base = get_die_by_name(_data.dice_name);
    var _die = clone_die(_base, "");
    
    // Apply any run-specific modifications
    _die.dice_value = _data.dice_value;
	_die.distribution = _data.distribution;
	_die.min_roll_bonus = _data.min_roll_bonus;
	
	// keywords and description can change during a run (an upgrade adding Coin, say); older saves don't have them
	if (variable_struct_exists(_data, "keywords") && is_array(_data.keywords)) _die.keywords = _data.keywords;
	if (variable_struct_exists(_data, "description") && is_string(_data.description)) _die.description = _data.description;
    
    return _die;
}

function get_tool_by_name(_name) {
    if (_name == "The Hammer") return tool_hammer;
    if (_name == "The Drill") return tool_drill;
    if (_name == "The Cutters") return tool_scissors;
    return undefined;
}

function get_die_by_name(_name) {
	// dice renamed when Intel became Insight (briefly Ink); saves from before still use the old names
	switch (_name) {
		case "Intel": case "Ink": _name = "Insight"; break;
		case "Intel.": case "Ink.": _name = "Insight."; break;
		case "Inteli Die": _name = "Inkwell Die"; break;
	}

    for (var i = 0; i < ds_list_size(global.master_dice_list); i++) {
        if (global.master_dice_list[| i].name == _name) {
            return global.master_dice_list[| i];
        }
	}
	
	for (var i = 0; i < ds_list_size(global.starter_dice_list); i++) {
		if (global.starter_dice_list[| i].name == _name) {
			return global.starter_dice_list[| i];
		}
    }
	
    return undefined;
}

function get_node_by_name(_name) {
    with (oWorldManager) {
        if (_name == "Combat") return node_combat;
        if (_name == "Shop") return node_shop;
        if (_name == "Event") return node_event;
        if (_name == "Workbench") return node_workbench;
        if (_name == "Bounty") return node_bounty;
        if (_name == "Elite") return node_elite;
        if (_name == "Boss") return node_boss;
        if (_name == "Treasure") return node_treasure;
        if (_name == "Alignment Fight") return node_alignment;
    }
    return undefined;
}



// Draws our hand-drawn panels: a two-tone fill and uneven ink strokes along each edge. Drawn straight to the screen
// with triangles (no surfaces): each panel's wobble comes from its position and colour, so it holds still frame to frame.
// (The old version built a cached 8x surface per size; buttons growing on hover made new ones every frame, and they
// rendered black in the web build.)
function draw_wonky_rectangle(_x, _y, _width, _height, _fill_col, _stroke_col, _alpha, _centered, _highlight) {
	var _x1 = _centered ? _x - _width / 2 : _x;
	var _y1 = _centered ? _y - _height / 2 : _y;
	var _x2 = _x1 + _width, _y2 = _y1 + _height;

	// steady "random" stroke widths for this panel (the same each frame)
	// seeded from where the panel sits and its colour, not its size, so a button growing on hover keeps its shape
	var _seed = (round((_x1 + _x2) / 128) * 131 + round((_y1 + _y2) / 128) * 977 + (_fill_col mod 9973) * 7) mod 100000;
	var _r = function(_s, _n) { return frac(abs(sin((_s + _n * 12.9898) * 43.7585)) * 1000); };
	var _otl = 1.5 + 1.0 * _r(_seed, 1);	// half-widths of the ink at each corner
	var _otr = 3.0 + 1.5 * _r(_seed, 2);
	var _obl = 2.0 + 1.0 * _r(_seed, 3);
	var _obr = 1.5 + 1.0 * _r(_seed, 4);

	var _old_alpha = draw_get_alpha();
	draw_set_alpha(_alpha);

	// fill: two triangles, the lower-right one a touch lighter when highlighted
	var _hi = _fill_col;
	if (_highlight) _hi = make_colour_rgb(clamp(color_get_red(_fill_col) + 20, 0, 255), clamp(color_get_green(_fill_col) + 20, 0, 255), clamp(color_get_blue(_fill_col) + 20, 0, 255));
	draw_triangle_color(_x1, _y1, _x2, _y1, _x1, _y2, _fill_col, _fill_col, _fill_col, false);
	draw_triangle_color(_x1, _y2, _x2, _y1, _x2, _y2, _hi, _hi, _hi, false);

	// ink edges: each a quad that tapers from one corner's width to the next
	draw_set_color(_stroke_col);
	wonky_edge(_x1, _y1, _otl, _x2, _y1, _otr, true);	// top
	wonky_edge(_x1, _y2, _obl, _x2, _y2, _obr, true);	// bottom
	wonky_edge(_x1, _y1, _otl, _x1, _y2, _obl, false);	// left
	wonky_edge(_x2, _y1, _otr, _x2, _y2, _obr, false);	// right

	draw_set_alpha(_old_alpha);
}

/// @func wonky_edge(_ax, _ay, _aw, _bx, _by, _bw, _horizontal)
/// @desc One ink edge of a wonky panel, from point a (half-width _aw) to point b (half-width _bw).
function wonky_edge(_ax, _ay, _aw, _bx, _by, _bw, _horizontal) {
	if (_horizontal) {
		draw_triangle(_ax - _aw, _ay - _aw, _bx + _bw, _by - _bw, _bx + _bw, _by + _bw, false);
		draw_triangle(_ax - _aw, _ay - _aw, _bx + _bw, _by + _bw, _ax - _aw, _ay + _aw, false);
	} else {
		draw_triangle(_ax - _aw, _ay - _aw, _ax + _aw, _ay - _aw, _bx + _bw, _by + _bw, false);
		draw_triangle(_ax - _aw, _ay - _aw, _bx + _bw, _by + _bw, _bx - _bw, _by + _bw, false);
	}
}


// used to update x and y positions when the resolution is not 1080
function room_to_gui_x(_x) {
    return (_x - camera_get_view_x(view_camera[0])) * (display_get_gui_width() / camera_get_view_width(view_camera[0]));
}

function room_to_gui_y(_y) {
    return (_y - camera_get_view_y(view_camera[0])) * (display_get_gui_height() / camera_get_view_height(view_camera[0]));
}

function double_tap(_key) {
	if (global.double_tap_timer > 0) {
		if (keyboard_check_pressed(_key) && global.double_tap_last_key == _key) {
			return true;
		}
	}
	
	if (keyboard_check_pressed(_key)) {
		global.double_tap_timer = game_get_speed(gamespeed_fps) * 0.5; // if tapped again within a half of a second
		global.double_tap_last_key = _key;
	}
}

function start_run() {
	if (save_exists(1)) {
		oMainMenu.show_run_warning = true;
	} else {
		room_goto(rmMap);
	}
}

function lose_run() {
	show_debug_message("Player died, ending run");
	if (instance_exists(oRunManager) && oRunManager.run_over != undefined) return;

	// what did it: the enemies still standing, or the voyage itself
	var _cause = "Your hull gave out on the voyage";
	if (instance_exists(oCombat)) {
		oCombat.state = CombatState.PLAYER_DEAD;
		var _names = [];
		var _list = oCombat.room_enemies;
		if (ds_safe_exists(_list, ds_type_list)) {
			for (var i = 0; i < ds_list_size(_list); i++) {
				// a fight's enemy entry keeps its name in .data (add_enemy_to_fight)
				var _e = _list[| i];
				if (!is_struct(_e) || _e.dead || !is_struct(_e.data)) continue;
				var _name = _e.data.name;
				if (!array_contains(_names, _name)) array_push(_names, _name);
			}
		}
		if (array_length(_names) > 0) {
			_cause = "Sunk by ";
			for (var i = 0; i < array_length(_names); i++) _cause += ((i == 0) ? "" : (i == array_length(_names) - 1 ? " and " : ", ")) + _names[i];
		}
	}
	run_end(false, _cause); // deletes the save and shows the summary
}

/// @func draw_insight_icon(_icon, _x, _y, _scale, _alpha)
/// @desc Placeholder icons for the insight states, drawn with shapes until real art is made (F51), about 30 pixels tall
///       at scale 1, centred on _x, _y: "blotted" an ink spill, "faded" a dry brush, "legible" a brush loaded with
///       yellow ink (both tilted), "quill" a feather quill.
function draw_insight_icon(_icon, _x, _y, _scale, _alpha) {
	var _old_alpha = draw_get_alpha();
	var _ink = global.color_intel;
	draw_set_alpha(_alpha);

	switch (_icon) {
		case "blotted":
			// a spill: a lumpy blob with a few splashes, dark with a red edge
			var _blobs = [[0, 2, 10], [-7, -3, 6], [7, -4, 6], [6, 8, 5], [-8, 7, 4], [-13, -9, 2.5], [13, 10, 2], [2, -13, 2.5]];
			for (var _pass = 0; _pass < 2; _pass++) {
				draw_set_color((_pass == 0) ? c_red : make_color_rgb(20, 20, 35));
				for (var i = 0; i < array_length(_blobs); i++) {
					var _b = _blobs[i];
					draw_circle(_x + _b[0] * _scale, _y + _b[1] * _scale, (_b[2] + ((_pass == 0) ? 1.5 : 0)) * _scale, false);
				}
			}
		break;

		case "faded":
		case "legible":
			// a brush tilted 45 degrees, tip down-left. Legible: bristles loaded with yellow ink, a drop about to fall.
			// Faded: a dry brush, pale bristles splayed into strands with only a trace of ink.
			var _s = _scale;
			var _dry = (_icon == "faded");
			// the handle (up-right) and its metal band
			var _h1 = insight_rot(_x, _y, 0, -18, _s), _h2 = insight_rot(_x, _y, 0, -6, _s);
			draw_set_color(c_black);
			draw_line_width(_h1[0], _h1[1], _h2[0], _h2[1], max(7 * _s, 1.6));
			draw_set_color(make_color_rgb(120, 78, 44));
			draw_line_width(_h1[0], _h1[1], _h2[0], _h2[1], max(4 * _s, 1.6));
			var _f1 = insight_rot(_x, _y, 0, -7, _s), _f2 = insight_rot(_x, _y, 0, -1, _s);
			draw_set_color(c_black);
			draw_line_width(_f1[0], _f1[1], _f2[0], _f2[1], max(11 * _s, 1.6));
			draw_set_color(make_color_rgb(175, 175, 185));
			draw_line_width(_f1[0], _f1[1], _f2[0], _f2[1], max(8 * _s, 1.6));

			if (!_dry) {
				// loaded: a full, rounded belly of bristles soaked in ink, tapering to a point
				var _pts = [];
				for (var i = 0; i <= 10; i++) {
					var _t = i / 10;
					var _half = (4.5 + 2.5 * sin(_t * pi * 0.85)) * (1 - _t * _t * 0.95);
					array_push(_pts, insight_rot(_x, _y, -_half, -1 + _t * 17, _s));
				}
				for (var i = 10; i >= 0; i--) {
					var _t = i / 10;
					var _half = (4.5 + 2.5 * sin(_t * pi * 0.85)) * (1 - _t * _t * 0.95);
					array_push(_pts, insight_rot(_x, _y, _half, -1 + _t * 17, _s));
				}
				var _mid = insight_rot(_x, _y, 0, 6, _s);
				for (var _pass = 0; _pass < 2; _pass++) {
					var _g = (_pass == 0) ? 1.22 : 1;
					draw_set_color((_pass == 0) ? c_black : _ink);
					draw_primitive_begin(pr_trianglefan);
					draw_vertex(_mid[0], _mid[1]);
					for (var i = 0; i < array_length(_pts); i++) draw_vertex(_mid[0] + (_pts[i][0] - _mid[0]) * _g, _mid[1] + (_pts[i][1] - _mid[1]) * _g);
					draw_vertex(_mid[0] + (_pts[0][0] - _mid[0]) * _g, _mid[1] + (_pts[0][1] - _mid[1]) * _g);
					draw_primitive_end();
				}
				// a shine, and a drop gathering at the tip
				var _sh1 = insight_rot(_x, _y, -2, 2, _s), _sh2 = insight_rot(_x, _y, -1.5, 8, _s);
				draw_set_color(make_color_rgb(255, 255, 170));
				draw_line_width(_sh1[0], _sh1[1], _sh2[0], _sh2[1], max(1.5 * _s, 1.6));
				var _drop = insight_rot(_x, _y, 0, 20, _s);
				draw_set_color(c_black);
				draw_circle(_drop[0], _drop[1], max(3.2 * _s, 1.5), false);
				draw_set_color(_ink);
				draw_circle(_drop[0], _drop[1], max(2.2 * _s, 1.5), false);
			} else {
				// dry: separate pale strands fanning out, ragged at the ends, with a faint streak of ink
				var _strands = [-4.5, -2.5, -0.5, 1.5, 3.5, 5];
				for (var _pass = 0; _pass < 2; _pass++) {
					for (var i = 0; i < array_length(_strands); i++) {
						var _off = _strands[i];
						var _a1 = insight_rot(_x, _y, _off * 0.8, -1, _s);
						var _a2 = insight_rot(_x, _y, _off * 1.35, 13 + ((i mod 2) ? 2 : -1), _s);
						draw_set_color((_pass == 0) ? c_black : make_color_rgb(225, 214, 180));
						draw_line_width(_a1[0], _a1[1], _a2[0], _a2[1], ((_pass == 0) ? 3.4 : 1.8) * _s);
					}
				}
				var _st1 = insight_rot(_x, _y, 0.5, 4, _s), _st2 = insight_rot(_x, _y, 0.8, 11, _s);
				draw_set_color(_ink);
				draw_line_width(_st1[0], _st1[1], _st2[0], _st2[1], max(1.4 * _s, 1.6));
			}
		break;

		case "quill":
			// a feather quill leaning right: a curved vane either side of the shaft, a bare end near the nib, a dark nib
			var _s = _scale;
			var _nx = _x - 12 * _s, _ny = _y + 15 * _s;	// nib point
			var _ex = _x + 12 * _s, _ey = _y - 16 * _s;	// top of the feather
			var _len = point_distance(_nx, _ny, _ex, _ey);
			var _dir = point_direction(_nx, _ny, _ex, _ey);
			// points along the shaft with the vane's width on each side (wider on the left, curled a little)
			var _left = [], _right = [];
			for (var i = 0; i <= 10; i++) {
				var _t = 0.28 + 0.72 * (i / 10);
				var _w = sin((i / 10) * pi) * 7.5 * _s + 0.5 * _s;
				var _px = _nx + lengthdir_x(_len * _t, _dir), _py = _ny + lengthdir_y(_len * _t, _dir);
				array_push(_left, [_px + lengthdir_x(_w * 1.15, _dir + 90 + 12), _py + lengthdir_y(_w * 1.15, _dir + 90 + 12)]);
				array_push(_right, [_px + lengthdir_x(_w * 0.8, _dir - 90 + 12), _py + lengthdir_y(_w * 0.8, _dir - 90 + 12)]);
			}
			var _sx0 = _nx + lengthdir_x(_len * 0.28, _dir), _sy0 = _ny + lengthdir_y(_len * 0.28, _dir);
			for (var _pass = 0; _pass < 2; _pass++) {
				var _grow = (_pass == 0) ? 1.25 : 1;
				draw_set_color((_pass == 0) ? c_black : make_color_rgb(244, 238, 214));
				var _sides = [_left, _right];
				for (var _side = 0; _side < 2; _side++) {
					var _pts = _sides[_side];
					draw_primitive_begin(pr_trianglefan);
					var _cx = (_sx0 + _ex) / 2, _cy = (_sy0 + _ey) / 2;
					draw_vertex(_cx, _cy);
					draw_vertex(_cx + (_sx0 - _cx) * _grow, _cy + (_sy0 - _cy) * _grow);
					for (var i = 0; i < array_length(_pts); i++) draw_vertex(_cx + (_pts[i][0] - _cx) * _grow, _cy + (_pts[i][1] - _cy) * _grow);
					draw_vertex(_cx + (_ex - _cx) * _grow, _cy + (_ey - _cy) * _grow);
					draw_primitive_end();
				}
			}
			// a few barbs, the insight-yellow tip, the shaft and the nib
			draw_set_color(make_color_rgb(190, 180, 150));
			for (var i = 3; i <= 8; i += 2) {
				draw_line_width(_left[i][0] + (_left[i][0] < _x ? 0 : 0), _left[i][1], (_left[i][0] + _sx0 + (_ex - _sx0) * (i / 10)) / 2, (_left[i][1] + _sy0 + (_ey - _sy0) * (i / 10)) / 2, max(1 * _s, 1.6));
			}
			draw_set_color(_ink);
			draw_circle(_ex - lengthdir_x(3 * _s, _dir), _ey - lengthdir_y(3 * _s, _dir), max(2.6 * _s, 1.5), false);
			draw_set_color(c_black);
			draw_line_width(_nx, _ny, _ex, _ey, max(1.8 * _s, 1.6));
			draw_line_width(_nx, _ny, _sx0, _sy0, max(3.5 * _s, 1.6));
			draw_set_color(make_color_rgb(40, 32, 24));
			draw_triangle(_nx, _ny, _nx + lengthdir_x(6 * _s, _dir + 15), _ny + lengthdir_y(6 * _s, _dir + 15), _nx + lengthdir_x(6 * _s, _dir - 15), _ny + lengthdir_y(6 * _s, _dir - 15), false);
		break;
	}

	draw_set_alpha(_old_alpha);
	draw_set_color(c_white);
}

/// @func ds_safe_exists(_id, _type)
/// @desc ds_exists that is also false for undefined. The desktop build treats ds_exists(undefined) as
///       false, but the web build stops with an error, and freed lists here are set to undefined (oCombat CleanUp).
function ds_safe_exists(_id, _type) {
	if (is_undefined(_id)) return false;
	return ds_exists(_id, _type);
}

/// @func dragged_item_draw()
/// @desc oRunManager Draw GUI End: the core or potion being carried, at the mouse, above the workbench slots and every
///       window (only tooltips draw over it). The top bar draws items resting in their slots.
function dragged_item_draw() {
	if (!instance_exists(oRunManager)) return;
	with (oRunManager) {
		for (var i = 0; i < array_length(items); i++) {
			if (items[i] == undefined || !items[i].dragging) continue;
			var _angle = (items[i].type == "consumable") ? -30 : 0;
			draw_set_alpha(1);
			draw_sprite_ext(items[i].sprite, items[i].index, device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), items_hover_scale[i], items_hover_scale[i], _angle, c_white, 1.0);
		}
	}
}

// =====================================================================
// RUN STATS, PAUSE MENU, RUN SUMMARY (F05, F35)
// oRunManager holds run_stats (saved with the run), paused and run_over. The pause menu and the summary are drawn in
// oRunManager Draw GUI End, above every window.
// =====================================================================

/// @func run_stats_new()
function run_stats_new() {
	return {
		fights_won: 0,
		elites_won: 0,
		bosses_won: 0,
		damage_dealt: 0,	// to enemies, from every source on your side
		biggest_hit: 0,		// the most one die (or effect) dealt at once
		damage_taken: 0,	// in fights, after block
		dice_played: 0,
		gold_earned: 0,
	};
}

/// @func run_stat_add(_key, _amount)
function run_stat_add(_key, _amount) {
	if (!instance_exists(oRunManager) || oRunManager.run_over != undefined) return;
	oRunManager.run_stats[$ _key] += _amount;
}

/// @func run_stat_max(_key, _value)
function run_stat_max(_key, _value) {
	if (!instance_exists(oRunManager) || oRunManager.run_over != undefined) return;
	oRunManager.run_stats[$ _key] = max(oRunManager.run_stats[$ _key], _value);
}

/// @func run_end(_won, _cause)
/// @desc The voyage is over: deletes the save and shows the summary (run_summary_draw) until the player goes back to
///       the menu. _cause is the line under the title ("Sunk by Pirate Ruffian").
function run_end(_won, _cause) {
	if (!instance_exists(oRunManager)) { room_goto(rmMainMenu); return; }
	if (oRunManager.run_over != undefined) return;
	if (save_exists(1)) delete_save(1);
	with (oRunManager) {
		run_over = { won: _won, cause: _cause, alpha: 0, btn_scale: 1 };
		paused = false;
		show_bag_contents = false;
	}
	global.show_settings = false;
	global.ui_layer = UI_LAYER.POPUP;
}

/// @func pause_open()
function pause_open() {
	with (oRunManager) {
		if (paused || run_over != undefined) return;
		paused = true;
		pre_pause_ui_layer = global.ui_layer;
		pause_scales = [1, 1, 1];
	}
	global.ui_layer = UI_LAYER.SETTINGS;
}

/// @func pause_close()
function pause_close() {
	with (oRunManager) {
		if (!paused) return;
		paused = false;
		global.ui_layer = pre_pause_ui_layer;
	}
}

/// @func pause_draw()
/// @desc oRunManager Draw GUI End: Resume, Settings, Save and quit. Hidden while Settings is open on top of it.
function pause_draw() {
	if (!instance_exists(oRunManager) || !oRunManager.paused || global.show_settings) return;
	var _gw = display_get_gui_width(), _gh = display_get_gui_height();

	draw_set_alpha(0.7);
	draw_set_color(c_black);
	draw_rectangle(0, 0, _gw, _gh, false);
	draw_set_alpha(1);

	// the window: title, a rule, the buttons, the save note
	ui_panel(_gw / 2 - 260, _gh * 0.22, _gw / 2 + 260, _gh * 0.4 + 3 * 110 + 60);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_font(ftBigger);
	draw_outline_text("Paused", c_black, c_white, 3, _gw / 2, _gh * 0.29, 1, 1, 0);
	ui_divider(_gw / 2 - 180, _gw / 2 + 180, _gh * 0.345);

	var _labels = ["Resume", "Settings", "Save and quit"];
	var _bw = 320, _bh = 80;
	with (oRunManager) {
		for (var i = 0; i < 3; i++) {
			var _b = draw_gui_button(_gw / 2 - _bw / 2, _gh * 0.4 + i * (_bh + 30), _bw, _bh, pause_scales[i], _labels[i], (i == 0) ? global.ui_primary : global.ui_neutral, ftBig, true, true, UI_LAYER.SETTINGS);
			pause_scales[i] = _b.scale;
			if (!_b.click) continue;
			switch (i) {
				case 0: pause_close(); break;
				case 1:
					// Settings opens over the pause menu; closing it comes back here
					global.show_settings = true;
					global.ui_layer = UI_LAYER.SETTINGS;
					break;
				case 2:
					paused = false;
					global.ui_layer = UI_LAYER.BASE;
					room_goto(rmMainMenu);
					break;
			}
		}
	}
	draw_set_font(ftDefault);
	draw_outline_text("Your voyage is saved at the last stop you reached.", c_black, c_ltgray, 2, _gw / 2, _gh * 0.4 + 3 * (_bh + 30) + 20, 1, 1, 0);
	// the build number, inside the panel's top-right corner (panel from _gh*0.22, right edge _gw/2 + 260), clear of the
	// centred title below it and of the save note
	draw_version_tag(_gw / 2 + 260 - 22, _gh * 0.22 + 34);
}

/// @func run_summary_draw()
/// @desc oRunManager Draw GUI End: the end of a voyage, won or lost. Title, cause, how far you got and the run's stats,
///       then Back to the menu.
function run_summary_draw() {
	if (!instance_exists(oRunManager) || oRunManager.run_over == undefined) return;
	var _r = oRunManager.run_over;
	var _s = oRunManager.run_stats;
	var _gw = display_get_gui_width(), _gh = display_get_gui_height();
	_r.alpha = lerp(_r.alpha, 1, 0.08);
	var _a = _r.alpha;
	global.ui_layer = UI_LAYER.POPUP;

	draw_set_alpha(0.85 * _a);
	draw_set_color(c_black);
	draw_rectangle(0, 0, _gw, _gh, false);
	draw_set_alpha(1);

	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_font(ftBiggest);
	draw_outline_text(_r.won ? "Voyage complete" : "Lost at sea", c_black, _r.won ? c_yellow : c_white, 3, _gw / 2, _gh * 0.16, 1, _a, 0);
	draw_set_font(ftBig);
	draw_outline_text(_r.cause, c_black, c_ltgray, 2, _gw / 2, _gh * 0.25, 1, _a, 0);

	// how far you got
	var _where = "";
	if (instance_exists(oWorldManager)) {
		with (oWorldManager) _where = "Chapter " + string(chapter) + ", " + chapter_title(chapter) + "  -  spread " + string(min(spreads_cleared + 1, CHAPTER_SPREADS + 1)) + " of " + string(CHAPTER_SPREADS + 1);
	}
	draw_set_font(ftDefault);
	draw_outline_text(_where, c_black, c_white, 2, _gw / 2, _gh * 0.31, 1, _a, 0);

	// the stats, two columns
	var _fights = string(_s.fights_won);
	if (_s.elites_won > 0 || _s.bosses_won > 0) _fights += "  (" + string(_s.elites_won) + " elite, " + string(_s.bosses_won) + " boss)";
	var _rows = [
		["Fights won", _fights],
		["Damage dealt", string(_s.damage_dealt)],
		["Biggest hit", string(_s.biggest_hit)],
		["Damage taken", string(_s.damage_taken)],
		["Dice played", string(_s.dice_played)],
		["Gold earned", string(_s.gold_earned)],
		["Dice in your bag", string(ds_list_size(global.dice_bag))],
		["Keepsakes", string(ds_list_size(oRunManager.keepsakes))],
	];
	var _panel_w = 760, _row_h = 46;
	var _px = _gw / 2 - _panel_w / 2, _py = _gh * 0.37;
	var _panel_h = ceil(array_length(_rows) / 2) * _row_h + 30;
	ui_panel(_px, _py, _px + _panel_w, _py + _panel_h, _a);
	for (var i = 0; i < array_length(_rows); i++) {
		var _cx = _px + 30 + (i mod 2) * (_panel_w / 2);
		var _cy = _py + 15 + _row_h / 2 + (i div 2) * _row_h;
		draw_set_halign(fa_left);
		draw_outline_text(_rows[i][0], c_black, c_ltgray, 2, _cx, _cy, 1, _a, 0);
		draw_set_halign(fa_right);
		draw_outline_text(_rows[i][1], c_black, c_white, 2, _cx + _panel_w / 2 - 60, _cy, 1, _a, 0);
	}

	// back to the menu
	var _bw = 360, _bh = 80;
	var _b = draw_gui_button(_gw / 2 - _bw / 2, _py + _panel_h + 50, _bw, _bh, _r.btn_scale, "Back to the menu", global.ui_primary, ftBig, _a > 0.9, true, UI_LAYER.POPUP);
	_r.btn_scale = _b.scale;
	if (_b.click) {
		global.ui_layer = UI_LAYER.BASE;
		room_goto(rmMainMenu);
	}
	draw_set_halign(fa_center);
}

/// @func draw_mouse_hint(_x, _y, _button, _text)
/// @desc A small mouse with its left or right button lit, and what that button does, e.g. at the workbench while a
///       tool is in hand. _x, _y is the mouse's centre; the text follows on the right.
function draw_mouse_hint(_x, _y, _button, _text) {
	var _w = 34, _h = 48;
	var _x1 = _x - _w / 2, _y1 = _y - _h / 2;
	draw_set_alpha(1);
	draw_set_color(make_color_rgb(50, 50, 55));
	draw_roundrect_ext(_x1, _y1, _x1 + _w, _y1 + _h, 16, 16, false);
	// the lit button: the top half of one side
	draw_set_color(c_red);
	if (_button == "left") draw_roundrect_ext(_x1 + 2, _y1 + 2, _x, _y - 2, 12, 12, false);
	else draw_roundrect_ext(_x, _y1 + 2, _x1 + _w - 2, _y - 2, 12, 12, false);
	draw_set_color(c_black);
	draw_line_width(_x, _y1, _x, _y, 2);
	draw_line_width(_x1, _y, _x1 + _w, _y, 2);
	draw_roundrect_ext(_x1, _y1, _x1 + _w, _y1 + _h, 16, 16, true);
	draw_set_font(ftDefault);
	draw_set_halign(fa_left);
	draw_set_valign(fa_middle);
	draw_outline_text(_text, c_black, c_white, 2, _x + _w / 2 + 12, _y, 1, 1, 0);
	draw_set_halign(fa_center);
}

/// @func cursor_draw()
/// @desc The game's own mouse pointer (Settings > Display > Custom cursor), drawn last of all by oSettingsMenu
///       Draw GUI End: an ink-outlined parchment arrow that tips forward and gains a gold glint over anything you can
///       hover or click, and dips while the button is held. The system cursor is hidden while it's on.
function cursor_draw() {
	var _on = global.custom_cursor;
	if (_on != global.cursor_hidden) {
		window_set_cursor(_on ? cr_none : cr_default);
		global.cursor_hidden = _on;
	}
	if (!_on) return;

	var _mx = device_mouse_x_to_gui(0), _my = device_mouse_y_to_gui(0);
	var _hot = (current_time - global.cursor_hover_time) < 60;
	var _down = mouse_check_button(mb_left);
	// tips forward over anything interactive, and further while the button is held (a tap), never shrinking
	global.cursor_tilt = lerp(global.cursor_tilt, _down ? 26 : (_hot ? 12 : 0), 0.35);
	var _s = (_hot ? 1.06 : 1) * global.ui_scale;

	// the arrow's points, tip at the mouse, rotated by the tilt
	var _pts = [[0, 0], [0, 30], [8, 23], [14, 36], [20, 33], [14, 21], [24, 21]];
	var _xy = [];
	for (var i = 0; i < array_length(_pts); i++) {
		var _px = _pts[i][0] * _s, _py = _pts[i][1] * _s;
		var _d = point_direction(0, 0, _px, _py) + global.cursor_tilt;
		var _l = point_distance(0, 0, _px, _py);
		array_push(_xy, [_mx + lengthdir_x(_l, _d), _my + lengthdir_y(_l, _d)]);
	}

	// shadow, then the paper fill as a fan of triangles from the tip, then the ink edge
	draw_set_alpha(0.35);
	draw_set_color(c_black);
	for (var i = 1; i < array_length(_xy) - 1; i++) draw_triangle(_xy[0][0] + 3, _xy[0][1] + 3, _xy[i][0] + 3, _xy[i][1] + 3, _xy[i + 1][0] + 3, _xy[i + 1][1] + 3, false);
	draw_set_alpha(1);
	draw_set_color(_hot ? make_color_rgb(255, 236, 170) : make_color_rgb(240, 228, 196));
	for (var i = 1; i < array_length(_xy) - 1; i++) draw_triangle(_xy[0][0], _xy[0][1], _xy[i][0], _xy[i][1], _xy[i + 1][0], _xy[i + 1][1], false);
	draw_set_color(make_color_rgb(40, 32, 24));
	for (var i = 0; i < array_length(_xy); i++) {
		var _n = (i + 1) mod array_length(_xy);
		draw_line_width(_xy[i][0], _xy[i][1], _xy[_n][0], _xy[_n][1], 2.5 * global.ui_scale);
	}
	draw_set_color(c_white);
}

/// @func ui_top_bar_h()
/// @desc Height of the top bar (gold, health, items...). Screens dim from here down so the bar stays in full colour.
function ui_top_bar_h() {
	return sprite_get_height(sTopBar) - 4; // the bar is drawn from y -4: dim from exactly where it ends
}

/// @func ui_button_col(_state_col)
/// @desc Rooms mark a ready button with c_red (leave) or c_lime (craft) in their logic; this is the colour to draw it.
function ui_button_col(_state_col) {
	if (_state_col == c_red) return global.ui_neutral;
	if (_state_col == c_lime || _state_col == c_green) return global.ui_primary;
	return _state_col;
}

/// @func draw_tools_badge(_x, _y, _scale)
/// @desc A small round badge with a crossed hammer and wrench (drawn in code), e.g. over the ship when the workbench
///       can be visited.
function draw_tools_badge(_x, _y, _scale) {
	var _r = 18 * _scale;
	var _ink = make_color_rgb(40, 32, 24);
	draw_set_alpha(1);
	draw_set_color(_ink);
	draw_circle(_x, _y, _r + 3, false);
	draw_set_color(make_color_rgb(240, 228, 196));
	draw_circle(_x, _y, _r, false);
	draw_set_color(_ink);
	// hammer: handle and head, leaning one way
	var _a = 45;
	draw_line_width(_x - lengthdir_x(11 * _scale, _a), _y - lengthdir_y(11 * _scale, _a), _x + lengthdir_x(11 * _scale, _a), _y + lengthdir_y(11 * _scale, _a), 3 * _scale);
	var _hx = _x - lengthdir_x(10 * _scale, _a), _hy = _y - lengthdir_y(10 * _scale, _a);
	draw_line_width(_hx - lengthdir_x(6 * _scale, _a + 90), _hy - lengthdir_y(6 * _scale, _a + 90), _hx + lengthdir_x(6 * _scale, _a + 90), _hy + lengthdir_y(6 * _scale, _a + 90), 5 * _scale);
	// wrench: handle the other way, with an open ring at its end
	var _b = 135;
	draw_line_width(_x - lengthdir_x(11 * _scale, _b), _y - lengthdir_y(11 * _scale, _b), _x + lengthdir_x(9 * _scale, _b), _y + lengthdir_y(9 * _scale, _b), 3 * _scale);
	draw_circle(_x + lengthdir_x(11 * _scale, _b), _y + lengthdir_y(11 * _scale, _b), 4 * _scale, true);
	draw_set_color(c_white);
}

/// @func ui_panel(_x1, _y1, _x2, _y2, _alpha)
/// @desc A logbook window (UI kit, phase 2): dark ink, a cream rule inside the edge and diamonds at the corners, the
///       same look as the tooltips. Use it behind any window of buttons or text.
function ui_panel(_x1, _y1, _x2, _y2, _alpha = 1) {
	var _old = draw_get_alpha();
	draw_set_alpha(0.35 * _alpha);
	draw_set_color(c_black);
	draw_roundrect_ext(_x1 + 6, _y1 + 8, _x2 + 6, _y2 + 8, 18, 18, false); // shadow
	draw_set_alpha(0.94 * _alpha);
	draw_set_color(make_color_rgb(26, 30, 40));
	draw_roundrect_ext(_x1, _y1, _x2, _y2, 18, 18, false);
	var _in = 8;
	draw_set_color(make_color_rgb(226, 212, 176));
	draw_set_alpha(0.55 * _alpha);
	draw_roundrect_ext(_x1 + _in, _y1 + _in, _x2 - _in, _y2 - _in, 12, 12, true);
	draw_set_alpha(0.9 * _alpha);
	var _d = 6;
	var _cx = [_x1 + _in, _x2 - _in, _x1 + _in, _x2 - _in];
	var _cy = [_y1 + _in, _y1 + _in, _y2 - _in, _y2 - _in];
	for (var c = 0; c < 4; c++) {
		draw_triangle(_cx[c] - _d, _cy[c], _cx[c], _cy[c] - _d, _cx[c] + _d, _cy[c], false);
		draw_triangle(_cx[c] - _d, _cy[c], _cx[c], _cy[c] + _d, _cx[c] + _d, _cy[c], false);
	}
	draw_set_alpha(_old);
	draw_set_color(c_white);
}

/// @func ui_divider(_x1, _x2, _y, _alpha)
/// @desc A thin cream rule with a diamond in the middle, to split a panel into parts.
function ui_divider(_x1, _x2, _y, _alpha = 1) {
	var _mx = (_x1 + _x2) / 2;
	draw_set_color(make_color_rgb(226, 212, 176));
	draw_set_alpha(0.5 * _alpha);
	draw_line_width(_x1, _y, _mx - 10, _y, 2);
	draw_line_width(_mx + 10, _y, _x2, _y, 2);
	draw_set_alpha(0.9 * _alpha);
	draw_triangle(_mx - 6, _y, _mx, _y - 6, _mx + 6, _y, false);
	draw_triangle(_mx - 6, _y, _mx, _y + 6, _mx + 6, _y, false);
	draw_set_alpha(1);
	draw_set_color(c_white);
}

/// @func insight_rot(_x, _y, _lx, _ly, _scale)
/// @desc A point of a tilted insight icon: (_lx, _ly) in the icon's own frame (pointing down), turned 45 degrees so the
///       tip points down-left, scaled and placed at _x, _y. Returns [x, y].
function insight_rot(_x, _y, _lx, _ly, _scale) {
	var _c = 0.7071, _sn = 0.7071;
	return [_x + (_lx * _c - _ly * _sn) * _scale, _y + (_lx * _sn + _ly * _c) * _scale];
}

/// @func ui_button(_cx, _cy, _w, _h, _scale_ref, _text, _col, _active, _reason, _layer)
/// @desc The kit's standard button, centred on _cx, _cy, with big text that grows with it. _reason shows on hover
///       while it can't be pressed. Returns draw_gui_button's { hover, click, scale, ... }; keep .scale for next frame.
function ui_button(_cx, _cy, _w, _h, _scale_ref, _text, _col, _active = true, _reason = "", _layer = UI_LAYER.BASE, _alpha = 1, _font = ftBig) {
	return draw_gui_button(_cx - _w / 2, _cy - _h / 2, _w, _h, _scale_ref, _text, _col, _font, _active, true, _layer, noone, soClick2, _reason, true, _alpha);
}

/// @func draw_action_type_icon(_type, _x, _y, _scale)
/// @desc A small round badge with the symbol of an action type (attack, block, heal, insight), drawn on dice when
///       Settings > Display > Action icons on dice is on, so the types can be told apart without colour (F14).
function draw_action_type_icon(_type, _x, _y, _scale) {
	if (_type != "ATK" && _type != "BLK" && _type != "HEAL" && _type != "INTEL") return;
	var _r = 16 * _scale;
	draw_set_alpha(1);
	draw_set_color(c_black);
	draw_circle(_x, _y, _r + 2, false);
	draw_set_color(make_color_rgb(240, 228, 196));
	draw_circle(_x, _y, _r, false);
	switch (_type) {
		case "ATK": draw_sprite_ext(sIntentIcons, 0, _x, _y, 0.5 * _scale, 0.5 * _scale, 0, make_color_rgb(40, 32, 24), 1); break;
		case "BLK": draw_sprite_ext(sIntentIcons, 1, _x, _y, 0.5 * _scale, 0.5 * _scale, 0, make_color_rgb(40, 32, 24), 1); break;
		case "HEAL": draw_sprite_ext(sIntentIcons, 2, _x, _y, 0.5 * _scale, 0.5 * _scale, 0, make_color_rgb(40, 32, 24), 1); break;
		case "INTEL": draw_insight_icon("legible", _x, _y, 0.85 * _scale, 1); break;
	}
	draw_set_color(c_white);
}

/// @func draw_cog_icon(_x, _y, _r, _angle)
/// @desc The menu cog drawn in code: a parchment wheel with eight teeth and a hole, ink outlined. _r is its radius.
function draw_cog_icon(_x, _y, _r, _angle) {
	var _ink = make_color_rgb(40, 32, 24);
	var _paper = make_color_rgb(240, 228, 196);
	for (var _pass = 0; _pass < 2; _pass++) {
		var _g = (_pass == 0) ? 2.5 : 0;
		draw_set_color((_pass == 0) ? _ink : _paper);
		for (var i = 0; i < 8; i++) {
			var _a = _angle + i * 45;
			draw_line_width(_x + lengthdir_x(_r * 0.55, _a), _y + lengthdir_y(_r * 0.55, _a), _x + lengthdir_x(_r * 1.25 + _g, _a), _y + lengthdir_y(_r * 1.25 + _g, _a), _r * 0.42 + _g * 2);
		}
		draw_circle(_x, _y, _r + _g, false);
	}
	draw_set_color(_ink); // the hole in the middle
	draw_circle(_x, _y, _r * 0.42, false);
	draw_set_color(c_white);
}

/// @func draw_version_tag(_x, _y)
/// @desc The build number (GAME_VERSION) in small faint text, right- and bottom-aligned to _x, _y, so testers can say
///       which build they played.
function draw_version_tag(_x, _y) {
	draw_set_font(ftSmall);
	draw_set_halign(fa_right);
	draw_set_valign(fa_bottom);
	draw_outline_text("v" + GAME_VERSION, c_black, make_color_rgb(226, 212, 176), 2, _x, _y, 1, 0.75, 0);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
}
