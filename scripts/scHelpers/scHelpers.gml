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
	// UI rework: a button in one of the kit's colours is drawn as the paper-and-ink kit button (ui_button), so every
	// menu, setting and note button matches; other colours (fight rewards, the old quill menu) keep this look
	if (_draw_rect == true && variable_global_exists("ui_col") && (_color == global.ui_primary || _color == global.ui_neutral || _color == global.ui_danger || _color == global.ui_quiet)) {
		var _kit = ui_button(_x + _base_w / 2, _y + _base_h / 2, _base_w, _base_h, _scale_ref, _text, _color, _active, _disabled_reason, _layer, _alpha, _use_font ? _font : ftDefault, _click_sound);
		_kit.x = _x; _kit.y = _y; _kit.w = _base_w; _kit.h = _base_h;
		return _kit;
	}
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
					case "block":												col = global.text_block;		break; // readable on dark surfaces
					case "heal":												col = global.text_heal;			break;
					case "attack":												col = global.text_attack;		break;
					case "intel":												col = global.text_intel;		break; // ink, readable on dark
					case "subtext":												col = c_gray;					break;
					default:													col = _fill_col;
				}
				if (variable_global_exists("ui_on_paper") && global.ui_on_paper) col = ui_text_on_paper(col); // on paper: the dark versions
				array_push(colors_array, col);
			}
		}
		
		// B82: lay the words out into lines first (wrapping at _max_length, breaking at "\n"; no limit when it's -1), then
		// draw each line where the caller's halign and valign put it. It used to draw word by word at the caller's halign
		// (centred text came out scrambled) and, with no _max_length, put every word on its own line.
		var line_h = font_get_size(draw_get_font()) * 1.5 * _scale;
		var _limit = (_max_length > 0) ? _max_length : infinity;
		var _space_w = string_width(" ") * _scale;
		var _lines = [[]];      // each line: an array of { t, c, w }, words without their spaces
		var _line_w = [0];      // each line's width, spaces between its words included
		var _li = 0;
		var _glue = false;      // the next word joins the last one with no space (the colour changed mid-word)
		for (var i = 0; i < array_length(output_string_array); i++) {
			var col = colors_array[i];
			var chunk = output_string_array[i];
			var _paras = string_split(chunk, "\n");
			for (var pa = 0; pa < array_length(_paras); pa++) {
				if (pa > 0) { array_push(_lines, []); array_push(_line_w, 0); _li++; _glue = false; } // a forced break
				var words = string_split(_paras[pa], " ");
				var wc = array_length(words);
				for (var w = 0; w < wc; w++) {
					var word = words[w];
					if (word == "") { _glue = false; continue; } // a space (at either end of the chunk, or doubled)
					var pw = string_width(word) * _scale;
					var _n_on = array_length(_lines[_li]);
					var _add = (_n_on > 0 && !_glue) ? _space_w : 0;
					// doesn't fit: a new line (never for the first word on a line)
					if (_n_on > 0 && _line_w[_li] + _add + pw > _limit) {
						array_push(_lines, []); array_push(_line_w, 0); _li++;
						_add = 0;
					}
					array_push(_lines[_li], { t: word, c: col, w: pw, gap: _add });
					_line_w[_li] += _add + pw;
					_glue = (w == wc - 1); // a chunk's last word touches the next chunk unless a space follows
				}
			}
		}

		// where the block goes: halign by each line's own width (centred on _x, or ending at it); valign by its height
		var _ha = draw_get_halign(), _va = draw_get_valign();
		var _nl = array_length(_lines);
		var _block_h = (_nl - 1) * line_h + string_height("M") * _scale;
		var _top = (_va == fa_middle) ? _y - _block_h / 2 : ((_va == fa_bottom) ? _y - _block_h : _y);
		draw_set_halign(fa_left);
		draw_set_valign(fa_top);
		for (var l = 0; l < _nl; l++) {
			var _lx = (_ha == fa_center) ? _x - _line_w[l] / 2 : ((_ha == fa_right) ? _x - _line_w[l] : _x);
			var _ly = _top + l * line_h;
			var _words = _lines[l];
			for (var w = 0; w < array_length(_words); w++) {
				var _wd = _words[w];
				_lx += _wd.gap;
				// outline, then the word in its colour
				draw_set_alpha(_alpha * 0.6);
				draw_set_color(_outline_col);
				for (var ox = -_outline_width; ox <= _outline_width; ox++) {
					for (var oy = -_outline_width; oy <= _outline_width; oy++) {
						if (ox != 0 || oy != 0) draw_text_transformed(_lx + ox, _ly + oy, _wd.t, _scale, _scale, _angle);
					}
				}
				draw_set_alpha(_alpha);
				draw_set_color(_wd.c);
				draw_text_transformed(_lx, _ly, _wd.t, _scale, _scale, _angle);
				_lx += _wd.w;
			}
		}
		draw_set_halign(_ha); // the caller's alignment back
		draw_set_valign(_va);
		draw_set_alpha(1);

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

/// @desc _cost (0: none) and _cost_kind ("insight" or "gold"): what doing this spends, shown as a "-3" badge on the
///       tooltip's top right corner (yellow for insight, gold for gold).
///       _hint: { button: "left"/"right", text, col }, a small mouse icon and words sitting just above the box's top right.
function queue_tooltip(_x, _y, _name, _desc, _icon = undefined, _index = 0, _dice = undefined, _cost = 0, _cost_kind = "ink", _hint = undefined) {
    if (!global.tooltip_active) {
        global.tooltip_active = true;
        var _caller_font = draw_get_font(); // measuring below sets fonts; the caller gets theirs back (B82)

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
            anchor: _anchor, // the hovered rectangle it sits beside, or undefined
            cost: _cost, cost_kind: _cost_kind, // what it spends (tooltip_cost_badge)
            hint: _hint, // a mouse hint above the top right (draw_mouse_hint)
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
        draw_set_font(_caller_font);
    }
}
function draw_all_tooltips() {

	// a die being dragged over the discard pile: no tooltips, so it's clear what letting go does (its own label says)
	var _over_discard = false;
	if (room == rmCombat) with (oDice) if (over_discard) _over_discard = true;

    if (global.tooltip_active && !_over_discard) {
		// the main tooltip, with its keywords stacked tight underneath (each measured exactly, so no gaps), the whole
		// stack kept on screen
		var tt = global.tooltip_main;
		var _gap = 4;
		if (is_struct(tt) && variable_struct_exists(tt, "die_tip")) { draw_die_tip(tt); tt = undefined; } // a die's compact tip (queue_die_tip)
	}
	if (global.tooltip_active && !_over_discard && is_struct(global.tooltip_main) && !variable_struct_exists(global.tooltip_main, "die_tip")) {
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
		if (variable_struct_exists(tt, "cost") && tt.cost > 0) tooltip_cost_badge(xx + _main.w, yy, tt.cost, tt.cost_kind);
		// a mouse hint just above the box, its right end lined up with the box's (at 0.6 the mouse is 20px wide)
		if (variable_struct_exists(tt, "hint") && is_struct(tt.hint)) {
			draw_set_font(ftDefault);
			var _hw = 20 + 7 + string_width(tt.hint.text);
			draw_mouse_hint(xx + _main.w - _hw + 10, yy - 22, tt.hint.button, tt.hint.text, 0.6, tt.hint.col, tt.hint.col);
		}
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

/// @func glossary_terms(_text)
/// @desc The keywords, buffs and debuffs a piece of text names (whole words, any case), each once: an array of
///       { name, desc, key } (key is the keyword for draw_keyword_icon, "" for a buff or debuff). A name inside a
///       longer one also found ("Bind" in "Barnacle Bind") is left out. F137: explain them wherever they're seen.
function glossary_terms(_text) {
	var _out = [];
	if (!is_string(_text) || _text == "") return _out;
	// letters only, so "[sticky]", "Sticky." and "Sticky:" all read as the word
	var _up = string_upper(_text), _clean = " ";
	for (var i = 1; i <= string_length(_up); i++) {
		var _c = string_char_at(_up, i);
		_clean += (_c >= "A" && _c <= "Z") ? _c : " ";
	}
	_clean += " ";
	var _found = [];
	var _keys = variable_struct_get_names(global.keywords);
	for (var k = 0; k < array_length(_keys); k++) {
		if (_keys[k] == "Loose") continue; // retired
		array_push(_found, { name: _keys[k], desc: global.keywords[$ _keys[k]].desc, key: _keys[k] });
	}
	if (variable_global_exists("status_glossary")) {
		for (var s = 0; s < array_length(global.status_glossary); s++) {
			var _b = global.status_glossary[s];
			array_push(_found, { name: _b.name, desc: _b.desc, key: "" });
		}
	}
	for (var f = 0; f < array_length(_found); f++) {
		var _t = _found[f];
		if (string_pos(" " + string_upper(_t.name) + " ", _clean) == 0) continue;
		var _dupe = false;
		for (var o = 0; o < array_length(_out); o++) if (string_pos(string_upper(_t.name), string_upper(_out[o].name)) > 0) _dupe = true;
		if (!_dupe) array_push(_out, _t);
	}
	// drop any already kept that sit inside a longer one found after them
	var _kept = [];
	for (var o = 0; o < array_length(_out); o++) {
		var _inside = false;
		for (var p = 0; p < array_length(_out); p++) if (p != o && string_length(_out[p].name) > string_length(_out[o].name) && string_pos(string_upper(_out[o].name), string_upper(_out[p].name)) > 0) _inside = true;
		if (!_inside) array_push(_kept, _out[o]);
	}
	return _kept;
}

/// @func die_glossary(_die)
/// @desc The terms a die tip explains: its own keywords first, then anything else its effect names (Might, Mock...).
function die_glossary(_die) {
	var _out = [];
	if (variable_struct_exists(_die, "keywords")) {
		for (var i = 0; i < array_length(_die.keywords); i++) {
			var _k = _die.keywords[i];
			if (_k == "Loose" || !variable_struct_exists(global.keywords, _k)) continue;
			array_push(_out, { name: _k, desc: global.keywords[$ _k].desc, key: _k });
		}
	}
	var _more = glossary_terms(die_description(_die));
	for (var m = 0; m < array_length(_more); m++) {
		var _have = false;
		for (var o = 0; o < array_length(_out); o++) if (_out[o].name == _more[m].name) _have = true;
		if (!_have) array_push(_out, _more[m]);
	}
	return _out;
}

/// @func queue_glossary_tooltip(_text)
/// @desc Explains the keywords, buffs and debuffs a hovered piece of text names (an event's choice): the first as the
///       tooltip, the rest as keyword boxes under it. Nothing when it names none, or something else took the tooltip.
function queue_glossary_tooltip(_text) {
	if (global.tooltip_active) return;
	var _terms = glossary_terms(_text);
	if (array_length(_terms) == 0) return;
	var _k0 = _terms[0].key;
	queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), _terms[0].name, _terms[0].desc, (_k0 != "") ? sKeywordIcons : undefined, (_k0 != "") ? global.keywords[$ _k0].index : 0);
	global.tooltip_keywords = [];
	for (var i = 1; i < array_length(_terms); i++) {
		var _icon = (_terms[i].key != "") ? sKeywordIcons : undefined;
		var _index = (_terms[i].key != "") ? global.keywords[$ _terms[i].key].index : 0;
		array_push(global.tooltip_keywords, { name: _terms[i].name, desc: _terms[i].desc, icon: _icon, index: _index });
	}
}

/// @func die_tip_sub(_die)
/// @desc What a die tip says beside the name: "rolled 4" once it has rolled this turn, otherwise its range ("1-6").
///       A rolled die whose range isn't 1 to its size adds it: "rolled 4 (2-6)" (Jared, 2026-11-20; cards show it on a tag).
function die_tip_sub(_die) {
	var _out = get_dice_output(_die, -1, -1, true, "player"); // read only
	var _range = string(_out.min_roll) + "-" + string(_out.max_roll);
	if (room == rmCombat && die_has_faces(_die)) return "rolled " + string(die_face_total(_die)) + (die_range_changed(_die, _out) ? " (" + _range + ")" : "");
	return _range;
}

/// @func queue_die_tip(_die, _cx, _bottom, [_sub], [_extra], [_cost], [_cost_kind])
/// @desc A die's compact tip (every die you hover: in hand, in slots, on cards, shelves and rewards): drawn by draw_all_tooltips centred on _cx with its pointer at
///       _bottom (just above the die), never below it, so it never covers the hand. Name, _sub ("rolled 4" or "1-6"), a
///       mini chart of a fitted core (draw_dist_mini), and the effect; _extra a muted last line (a hint), _cost a "-N"
///       tag on its corner. No keyword boxes: those are on the die's icons.
///       Takes the tooltip slot like queue_tooltip (the first asked for in a frame wins).
function queue_die_tip(_die, _cx, _bottom, _sub = undefined, _extra = "", _cost = 0, _cost_kind = "gold") {
	if (global.tooltip_active) return;
	if (is_undefined(_sub)) _sub = die_tip_sub(_die);
	global.tooltip_active = true;
	global.tooltip_main = { die_tip: true, dice: _die, cx: _cx, bottom: _bottom, sub: _sub, extra: _extra, cost: _cost, cost_kind: _cost_kind };
	global.tooltip_keywords = [];
}

/// @func draw_dist_mini(_die, _x, _bottom, _h)
/// @desc A tiny bar chart of a die's distribution (its core): 5px bars, the tallest _h high, standing on _bottom from
///       _x. Returns its width. Nothing (0) for a die with no core.
function draw_dist_mini(_die, _x, _bottom, _h) {
	if (!is_struct(_die) || _die.distribution == "") return 0;
	var _out = get_dice_output(_die, undefined, -1, true, "player");
	var _dist = [];
	define_dice_distributions(_die.distribution, _out.min_roll, _out.max_roll, _dist);
	var _n = array_length(_dist);
	if (_n == 0) return 0;
	var _top = 0;
	for (var i = 0; i < _n; i++) _top = max(_top, _dist[i]);
	if (_top <= 0) _top = 1;
	for (var i = 0; i < _n; i++) {
		var _bh = (_dist[i] > 0) ? max(2, _h * _dist[i] / _top) : 1;
		draw_set_color((_dist[i] > 0) ? make_color_rgb(242, 210, 74) : make_color_rgb(90, 90, 100));
		draw_rectangle(_x + i * 7, _bottom - _bh, _x + i * 7 + 4, _bottom, false);
	}
	draw_set_color(c_white);
	return _n * 7 - 2;
}

/// @func draw_die_tip(_tt)
/// @desc Draws a compact die tip (queue_die_tip): the logbook tooltip box above the die with a pointer down to it,
///       kept on screen sideways.
function draw_die_tip(_tt) {
	var _d = _tt.dice;
	var _pad = 14, _max_w = 260;
	draw_set_font(ftDefault);
	var _name_w = string_width(_d.name);
	var _name_h = string_height(_d.name);
	draw_set_font(ftDescriptions);
	var _sub_w = string_width(_tt.sub);
	var _desc = die_description(_d);
	var _line = font_get_size(ftDescriptions) * 1.5;
	var _desc_w = min(_max_w, string_width(_desc));
	var _desc_h = string_height_ext(_desc, _line, _max_w);
	var _extra = variable_struct_exists(_tt, "extra") ? _tt.extra : "";
	var _extra_h = (_extra != "") ? 6 + string_height_ext(_extra, _line, _max_w) : 0;
	// its keywords, buffs and debuffs, a line each under the effect (F137): "Sticky: stays in its slot..."
	var _terms = die_glossary(_d);
	var _term_txt = [], _term_h = [], _terms_h = 0;
	for (var i = 0; i < array_length(_terms); i++) {
		var _tx = _terms[i].name + ": " + _terms[i].desc;
		array_push(_term_txt, _tx);
		var _th = max(24, string_height_ext(_tx, _line, _max_w - 26));
		array_push(_term_h, _th);
		_terms_h += 6 + _th;
		_desc_w = max(_desc_w, min(_max_w, 26 + string_width(_tx)));
	}
	if (_terms_h > 0) _terms_h += 4; // and a rule above them
	if (_extra != "") _desc_w = max(_desc_w, min(_max_w, string_width(_extra)));
	var _mini_w = (_d.distribution != "") ? _d.dice_value * 7 : 0; // about draw_dist_mini's width
	var _w = _pad * 2 + max(_name_w + 8 + _sub_w + (_mini_w > 0 ? 10 + _mini_w : 0), _desc_w);
	var _h = _pad * 2 + _name_h + 4 + _desc_h + _terms_h + _extra_h;
	var _x1 = clamp(_tt.cx - _w / 2, 10, display_get_gui_width() - _w - 10);
	var _y2 = _tt.bottom - 10; // room for the pointer
	var _y1 = max(ui_top_bar_h() + 6, _y2 - _h);
	_y2 = _y1 + _h;

	// the box, like the tooltips: dark ink, a cream rule; a pointer down to the die
	var _bg = (oRunManager.error_timer == 0) ? make_color_rgb(26, 30, 40) : global.color_error;
	var _rule = make_color_rgb(226, 212, 176);
	var _px = clamp(_tt.cx, _x1 + 16, _x1 + _w - 16);
	draw_set_alpha(0.92);
	draw_set_color(c_black);
	draw_roundrect(_x1 - 2, _y1 - 2, _x1 + _w + 2, _y2 + 2, false);
	draw_triangle(_px - 10, _y2, _px + 10, _y2, _px, _y2 + 12, false);
	draw_set_color(_bg);
	draw_roundrect(_x1, _y1, _x1 + _w, _y2, false);
	draw_triangle(_px - 8, _y2 - 1, _px + 8, _y2 - 1, _px, _y2 + 9, false);
	draw_set_alpha(0.6);
	draw_set_color(_rule);
	draw_roundrect(_x1 + 4, _y1 + 4, _x1 + _w - 4, _y2 - 4, true);
	draw_set_alpha(1);

	// the name, what it rolled, the mini chart; then the effect
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_font(ftDefault);
	draw_outline_text(_d.name, c_black, c_white, 2, _x1 + _pad, _y1 + _pad, 1, 1, 0);
	draw_set_font(ftDescriptions);
	var _sx = _x1 + _pad + _name_w + 8;
	draw_outline_text(_tt.sub, c_black, make_color_rgb(185, 169, 136), 1, _sx, _y1 + _pad + 3, 1, 1, 0);
	if (_mini_w > 0) draw_dist_mini(_d, _sx + _sub_w + 10, _y1 + _pad + _name_h - 3, 16);
	draw_outline_text(colorcode_text(_desc), c_black, c_white, 1, _x1 + _pad, _y1 + _pad + _name_h + 4, 1, 1, 0, _max_w);
	var _ty = _y1 + _pad + _name_h + 4 + _desc_h;
	if (_terms_h > 0) {
		draw_set_alpha(0.35);
		draw_set_color(_rule);
		draw_line(_x1 + _pad, _ty + 5, _x1 + _w - _pad, _ty + 5);
		draw_set_alpha(1);
		_ty += 4;
		for (var i = 0; i < array_length(_terms); i++) {
			_ty += 6;
			if (_terms[i].key != "") draw_keyword_icon(_terms[i].key, _x1 + _pad + 10, _ty + 11, 0.7);
			else { draw_set_color(_rule); draw_circle(_x1 + _pad + 10, _ty + 11, 4, false); } // a buff or debuff: a plain bullet
			draw_outline_text(_term_txt[i], c_black, make_color_rgb(205, 192, 160), 1, _x1 + _pad + 26, _ty, 1, 1, 0, _max_w - 26);
			_ty += _term_h[i];
		}
	}
	if (_extra != "") draw_outline_text(_extra, c_black, make_color_rgb(185, 169, 136), 1, _x1 + _pad, _ty + 6, 1, 1, 0, _max_w);
	if (variable_struct_exists(_tt, "cost") && _tt.cost > 0) tooltip_cost_badge(_x1 + _w, _y1, _tt.cost, _tt.cost_kind);
	draw_set_color(c_white);
}

/// @func tooltip_cost_badge(_x, _y, _amount, _kind)
/// @desc What a tooltip's action spends, as a small tag centred on its top right corner: "-3" in yellow with an eye-ish
///       dot for insight, or "-50" in gold with a coin for gold.
function tooltip_cost_badge(_x, _y, _amount, _kind) {
	var _col = (_kind == "gold") ? make_color_rgb(240, 190, 60) : global.text_intel;
	var _txt = "-" + string(_amount);
	draw_set_font(ftDefault);
	var _w = string_width(_txt) + 40, _h = 30;
	var _x1 = _x - _w + 12, _y1 = _y - _h / 2; // hangs off the corner a little
	draw_set_color(c_black);
	draw_roundrect_ext(_x1 - 2, _y1 - 2, _x1 + _w + 2, _y1 + _h + 2, 14, 14, false);
	draw_set_color(make_color_rgb(20, 22, 30));
	draw_roundrect_ext(_x1, _y1, _x1 + _w, _y1 + _h, 12, 12, false);
	draw_set_color(_col);
	draw_roundrect_ext(_x1, _y1, _x1 + _w, _y1 + _h, 12, 12, true);
	// the currency: a coin, or an ink pip (as under the inkwell)
	var _ix = _x1 + 15, _iy = _y1 + _h / 2;
	draw_set_color(c_black);
	draw_circle(_ix, _iy, 8, false);
	draw_set_color(_col);
	draw_circle(_ix, _iy, 6, false);
	if (_kind != "gold") { draw_set_color(global.color_intel); draw_circle(_ix, _iy, 4.5, false); } // the pip's ink
	draw_set_halign(fa_left);
	draw_set_valign(fa_middle);
	draw_outline_text(_txt, c_black, _col, 2, _ix + 12, _iy, 1, 1, 0);
	draw_set_color(c_white);
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

    // the description in paragraphs: a line break ("\n", or "\n\n") starts a new one, a little apart. The coloured
    // text drawing lays words out one by one and doesn't know about line breaks, so each paragraph is drawn on its own.
    draw_set_font(ftDescriptions);
    var _paras = [];
    var _raw = string_split(_desc, "\n");
    for (var p = 0; p < array_length(_raw); p++) if (string_trim(_raw[p]) != "") array_push(_paras, string_trim(_raw[p]));
    var line_sep = font_get_size(ftDescriptions) * 1.5;
    var para_gap = line_sep * 0.5;

    // the longest line the description wraps to, and its height
    var longest_line_px = 0;
    var desc_h = 0;
    for (var p = 0; p < array_length(_paras); p++) {
	    var words = string_split(_paras[p], " ");
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
	    desc_h += string_height_ext(_paras[p], line_sep, max_desc_w) + ((p > 0) ? para_gap : 0);
    }

    var has_core = (_dice != undefined && variable_struct_exists(_dice, "distribution") && _dice.distribution != "");
    var icon_space = (_icon != undefined) ? (_compact ? 36 : 50) : 0; // a core's icon sits beside its bars at the foot instead
    var _width  = padding * 2 + max(name_w, longest_line_px) + icon_space;
    var _height = padding * (_compact ? 1.4 : 1.6) + name_h + desc_h + (_compact ? 4 : 10);
    // a core's distribution sits inside the box, under the words, with the core's icon just left of it
    var _dist_h = has_core ? 55 + 8 : 0; // draw_dice_distribution at scale 1 is 55 tall
    if (has_core) {
	    _width = max(_width, padding * 2 + icon_space + 44 + _dice.dice_value * 17 + 10);
	    _height += _dist_h;
    }

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

    // icon (a die's core is drawn at the foot, beside its distribution)
    var icon_sprite = undefined;
    var icon_idx = 0;
    var icon_scale = _compact ? 0.75 : 1;
    if (_icon != undefined) {
        icon_sprite = _icon;
        icon_idx = _index;
    }
    if (icon_sprite != undefined) {
        var _kw = (icon_sprite == sKeywordIcons) ? keyword_from_index(icon_idx) : "";
        if (_kw != "") draw_keyword_icon(_kw, content_x + (_compact ? 10 : 16), yy + (_height / 2), icon_scale * 0.9, 1); // drawn in code (draw_keyword_icon)
        else draw_sprite_ext(icon_sprite, icon_idx, content_x + (_compact ? 10 : 16), yy + (_height / 2), icon_scale, icon_scale, 0, c_white, 1);
        content_x += icon_space;
    }

    // name (one line; the box is already wide enough), then the description
    draw_set_font(_compact ? ftDescriptions : ftDefault);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
	draw_outline_text(_name, c_black, _compact ? global.color_gold : c_white, 2, content_x, yy + padding, 1, 1, 0);
    draw_set_font(ftDescriptions);
    var _py = yy + padding + name_h + 2;
    for (var p = 0; p < array_length(_paras); p++) {
	    draw_set_font(ftDescriptions);
	    draw_outline_text(colorcode_text(_paras[p]), c_black, c_white, 1, content_x, _py, 1, 1, 0, max_desc_w);
	    draw_set_font(ftDescriptions);
	    _py += string_height_ext(_paras[p], line_sep, max_desc_w) + para_gap;
    }

	if (has_core) {
		var _dist_bottom = yy + _height - padding * 0.7;
		draw_sprite_ext(sCores, get_core_index(_dice), content_x + 16, _dist_bottom - 28, 0.75, 0.75, 0, c_white, 1);
		draw_dice_distribution(_dice, content_x + 44, _dist_bottom, false, 1);
	}

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
			if (_hover_sound != noone) { global.is_hovering = _sound_id; global.hovering_sound = _hover_sound; } // silent things don't take the hover (repeat sounds, 2026-11-21)
			global.clicking_sound = _click_sound;
			return true;
		}
	} else {
		if (mx < _x + _width/2 && mx > _x - _width/2 && my < _y + _height/2 && my > _y - _height/2) {
			if (debug_mode) {
				//draw_rectangle(_x - _width/2, _y - _height/2, _x + _width/2, _y + _height/2, false);
				//draw_set_alpha(1.0);
			}
			if (_hover_sound != noone) { global.is_hovering = _sound_id; global.hovering_sound = _hover_sound; } // silent things don't take the hover (repeat sounds, 2026-11-21)
			global.clicking_sound = _click_sound;
			return true;
		}
	}
	
	return false;
}

function throw_error(_error_msg, _error_desc) {
	if (oRunManager.error_timer < 60 || oRunManager.error_message != _error_msg) sfx_play(soQuill, AUDIO_GROUP.UI, 0.08, 0.35); // a quick quill scratch (Jared, 2026-11-23: try it)
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
	return choose("weighted", "loaded", "edge", "binary", "bell", "dome", "compass", "lodestone", "dual", "tower");
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
		case "odd":			core_index = 6;		break; // a die cored before the alignment pair keeps its shape
		case "even":		core_index = 7;		break;
		case "compass":		core_index = 6;		break;
		case "lodestone":	core_index = 7;		break;
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
	// dice renamed: Intel, then Insight, now Ink (2026-11-22); saves from before still use the old names
	switch (_name) {
		case "Intel": case "Insight": _name = "Ink"; break;
		case "Intel.": case "Insight.": _name = "Ink."; break;
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
	var _cause = "Your hull gave out";
	if (instance_exists(oCombat)) {
		oCombat.state = CombatState.PLAYER_DEAD;
		oCombat.player_death_t = current_time; // the ship keels over and sinks (oCombat Draw GUI)
		screen_shake(16);
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
///       yellow ink (both tilted), "inked" that with a blot, "underlined" that over a stroke, "quill" a feather quill.
function draw_insight_icon(_icon, _x, _y, _scale, _alpha) {
	var _old_alpha = draw_get_alpha();
	var _ink = global.color_intel;
	draw_set_alpha(_alpha);

	// Inked: the loaded brush with a fresh blot beside it. Underlined: the loaded brush over a stroke of ink.
	if (_icon == "inked" || _icon == "underlined") {
		draw_set_color(c_black);
		if (_icon == "inked") {
			draw_circle(_x + 11 * _scale, _y + 12 * _scale, 5 * _scale, false);
			draw_set_color(_ink);
			draw_circle(_x + 11 * _scale, _y + 12 * _scale, 3.6 * _scale, false);
		} else {
			draw_line_width(_x - 15 * _scale, _y + 17 * _scale, _x + 15 * _scale, _y + 15 * _scale, max(5 * _scale, 2));
			draw_set_color(_ink);
			draw_line_width(_x - 14 * _scale, _y + 17 * _scale, _x + 14 * _scale, _y + 15 * _scale, max(3 * _scale, 1.4));
		}
		_icon = "legible";
	}

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
	draw_outline_text("Saved at your last stop.", c_black, c_ltgray, 2, _gw / 2, _gh * 0.4 + 3 * (_bh + 30) + 20, 1, 1, 0);
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
function draw_mouse_hint(_x, _y, _button, _text, _scale = 1, _lit = c_red, _text_col = c_white) {
	var _w = 34 * _scale, _h = 48 * _scale;
	var _x1 = _x - _w / 2, _y1 = _y - _h / 2;
	draw_set_alpha(1);
	draw_set_color(make_color_rgb(50, 50, 55));
	draw_roundrect_ext(_x1, _y1, _x1 + _w, _y1 + _h, 16 * _scale, 16 * _scale, false);
	// the lit button: the top half of one side
	draw_set_color(_lit);
	if (_button == "left") draw_roundrect_ext(_x1 + 2, _y1 + 2, _x, _y - 2, 12 * _scale, 12 * _scale, false);
	else draw_roundrect_ext(_x, _y1 + 2, _x1 + _w - 2, _y - 2, 12 * _scale, 12 * _scale, false);
	draw_set_color(c_black);
	draw_line_width(_x, _y1, _x, _y, 2);
	draw_line_width(_x1, _y, _x1 + _w, _y, 2);
	draw_roundrect_ext(_x1, _y1, _x1 + _w, _y1 + _h, 16 * _scale, 16 * _scale, true);
	draw_set_font(ftDefault);
	draw_set_halign(fa_left);
	draw_set_valign(fa_middle);
	draw_outline_text(_text, c_black, _text_col, 2, _x + _w / 2 + 12 * _scale, _y, 1, 1, 0);
	draw_set_halign(fa_center);
}

/// @func cursor_draw()
/// @desc The game's own mouse pointer (Settings > Display > Custom cursor), drawn last of all by oSettingsMenu
///       Draw GUI End: an ink-outlined parchment arrow that tips forward and gains a gold glint over anything you can
///       hover or click, and dips while the button is held. The system cursor is hidden while it's on.
function cursor_draw() {
	var _on = global.custom_cursor;
	// the log: the cursor is a quill (draw_quill), its nib at the mouse, except over something you can click or drag
	// (quill_over), where it's the normal one (Jared, 2026-11-22). Drawing keeps the quill.
	var _quill = instance_exists(oCombat) && oCombat.insight_view && !global.show_settings && (!oCombat.quill_over || oCombat.ink_drawing);
	var _hide = _on || _quill;
	if (_hide != global.cursor_hidden) {
		window_set_cursor(_hide ? cr_none : cr_default);
		global.cursor_hidden = _hide;
	}
	var _mx = device_mouse_x_to_gui(0), _my = device_mouse_y_to_gui(0);
	if (_quill) {
		// the quill, its nib at the mouse, leaning up and right (its ink outline reads on the dark); it dips when you click
		var _qd = mouse_check_button(mb_left) ? 44 : 52;
		draw_quill(_mx, _my, 58 * global.ui_scale, _qd);
		return;
	}
	if (!_on) return;

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

/// @func ui_button(_cx, _cy, _w, _h, _scale_ref, _text, _col, _active, _reason, _layer, _alpha, _font)
/// @desc The kit's standard button, centred on _cx, _cy, in paper and ink (UI rework). _col picks its kind:
///       global.ui_primary a bright paper label in a brass frame (the commit action), global.ui_danger dark red with
///       paper words, global.ui_quiet slate with a cream rule (skippable), anything else plain paper with an ink edge.
///       Hover lifts and grows it a little; inactive, it fades and _reason shows on hover.
///       Returns { hover, click, scale }; keep .scale for next frame.
function ui_button(_cx, _cy, _w, _h, _scale_ref, _text, _col, _active = true, _reason = "", _layer = UI_LAYER.BASE, _alpha = 1, _font = ftBig, _click_sound = soClick2) {
	// a button still fading in can't be pressed yet; nothing can while a cutscene has input switched off
	var _hover = (_alpha > 0.5) && mouse_hovering(_cx - _w / 2, _cy - _h / 2, _w, _h, false, soSlotHover, _active ? _click_sound : noone, !global.all_input_disabled, _layer, "button:" + string(round(_cx)) + "," + string(round(_cy)) + _text); // a steady id: its size can change
	var _scale = lerp(_scale_ref, (_hover && _active) ? 1.06 : 1, 0.25);
	var _pressed = _hover && _active && mouse_check_button(mb_left);
	var _w2 = _w * _scale / 2, _h2 = _h * _scale / 2;
	var _lift = _pressed ? -2 : ((_hover && _active) ? 3 : 0);
	var _x1 = _cx - _w2, _y1 = _cy - _h2 - _lift, _x2 = _cx + _w2, _y2 = _cy + _h2 - _lift;
	var _a = (_active ? 1 : 0.5) * _alpha;

	var _fill = global.ui_col.paper, _text_col = global.ui_col.ink, _edge = global.ui_col.ink, _frame = -1;
	if (_col == global.ui_primary) { _fill = global.ui_col.paper_hi; _frame = global.ui_col.brass; }
	else if (_col == global.ui_danger) { _fill = global.ui_col.danger; _text_col = global.ui_col.paper_hi; }
	else if (_col == global.ui_quiet) { _fill = global.ui_col.slate; _text_col = global.ui_col.rule; _edge = make_color_rgb(110, 100, 84); }

	// shadow, ink edge (a brass frame for the primary), the fill
	draw_set_alpha(0.4 * _a);
	draw_set_color(c_black);
	draw_roundrect_ext(_x1 + 3, _y1 + 7 + _lift, _x2 + 3, _y2 + 7 + _lift, 12, 12, false);
	draw_set_alpha(_a);
	draw_set_color(_edge);
	draw_roundrect_ext(_x1 - 2, _y1 - 2, _x2 + 2, _y2 + 2, 12, 12, false);
	var _inset = 0;
	if (_frame != -1) {
		draw_set_color(_frame);
		draw_roundrect_ext(_x1, _y1, _x2, _y2, 11, 11, false);
		draw_set_color(_edge);
		draw_roundrect_ext(_x1 + 5, _y1 + 5, _x2 - 5, _y2 - 5, 8, 8, false);
		_inset = 7;
	}
	draw_set_color(_fill);
	draw_roundrect_ext(_x1 + _inset, _y1 + _inset, _x2 - _inset, _y2 - _inset, 10, 10, false);

	// the words, shrunk to fit
	draw_set_font(_font);
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_color(_text_col);
	var _ts = min(1, (_w * _scale - 24 - _inset * 2) / max(1, string_width(_text)));
	draw_text_transformed(_cx, _cy - _lift, _text, _ts, _ts, 0);
	draw_set_alpha(1);
	draw_set_color(c_white);

	if (_hover && !_active && _reason != "") queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), _text, _reason);
	return { hover: _hover, click: _hover && _active && mouse_check_button_pressed(mb_left), scale: _scale };
}

/// @func draw_action_type_icon(_type, _x, _y, _scale)
/// @desc A small round badge with the symbol of an action type (attack, block, heal, insight), drawn on dice when
///       Settings > Display > Action icons on dice is on, so the types can be told apart without colour (F14).
function draw_action_type_icon(_type, _x, _y, _scale, _alpha = 1) {
	if (_type != "ATK" && _type != "BLK" && _type != "HEAL" && _type != "INTEL") return;
	var _r = 16 * _scale;
	draw_set_alpha(_alpha);
	draw_set_color(c_black);
	draw_circle(_x, _y, _r + 2, false);
	draw_set_color(make_color_rgb(240, 228, 196));
	draw_circle(_x, _y, _r, false);
	ui_glyph(_type, _x, _y, _r * 1.35, global.ui_col.ink, _alpha); // the logbook glyphs (scUI)
	draw_set_alpha(1);
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

/// @func room_wipe_draw()
/// @desc Room transition (F65): when a room starts, dark ink covers the screen and sweeps off to the right over about
///       0.4 s, its edge a row of ink blots. Drawn just under the cursor (oRunManager Draw GUI End in a run,
///       oSettingsMenu otherwise), so it covers everything else. Quick, so it never slows play.
function room_wipe_draw() {
	if (!variable_global_exists("room_wipe_start")) return;
	var _p = (current_time - global.room_wipe_start) / 420;
	if (_p < 0 || _p >= 1) return;
	var _gw = display_get_gui_width(), _gh = display_get_gui_height();
	var _e = _p * _p * (3 - 2 * _p); // ease in and out
	var _edge = -120 + _e * (_gw + 240); // the ink's left edge, moving right
	draw_set_alpha(1);
	draw_set_color(make_color_rgb(18, 22, 32));
	draw_rectangle(_edge, 0, _gw, _gh, false);
	// a ragged edge: blots of different sizes down the front of the wash
	for (var _y = -20; _y <= _gh + 40; _y += 54) {
		var _r = 36 + 22 * sin(_y * 0.037) + 10 * sin(_y * 0.11);
		draw_circle(_edge + 8 * sin(_y * 0.05), _y, _r, false);
	}
	draw_set_color(c_white);
}

// =====================================================================
// BAG VIEW: sort and filter (oRunManager Draw GUI End draws the bag)
// =====================================================================

/// @func bag_view_list(_list)
/// @desc The dice to show from a bag or pile: only the chosen type (oRunManager.bag_filter: "All", "ATK", "BLK", "HEAL",
///       "INTEL", "None"), sorted by oRunManager.bag_sort (0 bag order, 1 type, 2 size, 3 rarity, 4 name). An array.
function bag_view_list(_list) {
	var _out = [];
	if (!ds_safe_exists(_list, ds_type_list)) return _out;
	var _f = oRunManager.bag_filter;
	for (var i = 0; i < ds_list_size(_list); i++) {
		var _d = _list[| i];
		if (_f == "All" || (_f == "None" && _d.action_type == "None") || (_f != "None" && string_pos(_f, _d.possible_type) > 0)) array_push(_out, _d);
	}
	global.bag_sort_key = oRunManager.bag_sort;
	if (global.bag_sort_key > 0) {
		array_sort(_out, function(_a, _b) {
			if (global.bag_sort_key != 4) {
				var _ra = bag_sort_value(_a, global.bag_sort_key), _rb = bag_sort_value(_b, global.bag_sort_key);
				if (_ra != _rb) return (_ra < _rb) ? -1 : 1;
			}
			return text_compare(_a.name, _b.name); // by name, or ties by name
		});
	}
	return _out;
}

/// @func bag_sort_value(_die, _key)
/// @desc What a die sorts by: its type, its size (biggest first), its rarity (rarest first) or its name.
function bag_sort_value(_die, _key) {
	switch (_key) {
		case 1:
			switch (_die.action_type) { case "ATK": return 0; case "BLK": return 1; case "HEAL": return 2; case "INTEL": return 3; case "None": return 4; }
			return 9;
		case 2: return -_die.dice_value;
		case 3: return (_die.rarity == "rare") ? 0 : ((_die.rarity == "uncommon") ? 1 : 2);
	}
	return 0;
}

/// @func bag_controls_draw(_list, _pad)
/// @desc Above the bag panel, right of the title: a count, a Sort button that cycles, and a filter button per type with
///       how many of that type there are.
function bag_controls_draw(_list, _pad) {
	if (!ds_safe_exists(_list, ds_type_list)) return;
	var _gw = display_get_gui_width();
	var _y = _pad - 34; // the title row, above the panel
	var _types = [["All", "All"], ["ATK", "Attack"], ["BLK", "Block"], ["HEAL", "Heal"], ["INTEL", "Ink"], ["None", "Generic"]];
	var _sorts = ["Bag order", "Type", "Size", "Rarity", "Name"];
	var _w = 118, _h = 40, _gap = 8;
	// right to left: the filters, then Sort
	var _x = _gw - _pad - _w / 2;
	for (var i = array_length(_types) - 1; i >= 0; i--) {
		var _code = _types[i][0];
		var _n = 0;
		for (var d = 0; d < ds_list_size(_list); d++) {
			var _die = _list[| d];
			if (_code == "All" || (_code == "None" && _die.action_type == "None") || (_code != "None" && string_pos(_code, _die.possible_type) > 0)) _n++;
		}
		var _on = (oRunManager.bag_filter == _code);
		var _b = ui_button(_x, _y, _w, _h, oRunManager.bag_btn_scales[i], _types[i][1] + " " + string(_n), _on ? global.ui_primary : global.ui_neutral, true, "", UI_LAYER.BAG, 1, ftDefault);
		oRunManager.bag_btn_scales[i] = _b.scale;
		if (_b.click) { oRunManager.bag_filter = _code; oRunManager.scroll_y = 0; }
		_x -= _w + _gap;
	}
	// Sort sits left of the filters: its right edge 30 px before the last filter's left edge, 170 wide (clear of a long
	// picker title on the left, which reaches about x 770)
	var _sort_w = 170;
	var _sort_cx = (_x + _w / 2 + _gap) - 30 - _sort_w / 2; // = 1002 - 30 - 85 = 887 at 1920 wide
	var _sort = ui_button(_sort_cx, _y, _sort_w, _h, oRunManager.bag_btn_scales[6], "Sort: " + _sorts[oRunManager.bag_sort], global.ui_neutral, true, "", UI_LAYER.BAG, 1, ftDefault);
	oRunManager.bag_btn_scales[6] = _sort.scale;
	if (_sort.hover) queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Sort", "Bag order, type, size, rarity or name.");
	if (_sort.click) { oRunManager.bag_sort = (oRunManager.bag_sort + 1) mod array_length(_sorts); oRunManager.scroll_y = 0; }
}

/// @func text_compare(_a, _b)
/// @desc Compare two strings alphabetically, ignoring case: -1, 0 or 1 (for sorting by name).
function text_compare(_a, _b) {
	_a = string_lower(_a); _b = string_lower(_b);
	var _n = min(string_length(_a), string_length(_b));
	for (var i = 1; i <= _n; i++) {
		var _ca = ord(string_char_at(_a, i)), _cb = ord(string_char_at(_b, i));
		if (_ca != _cb) return (_ca < _cb) ? -1 : 1;
	}
	if (string_length(_a) == string_length(_b)) return 0;
	return (string_length(_a) < string_length(_b)) ? -1 : 1;
}

/// @func bag_type_label(_possible_type)
/// @desc A die's types in words for its card: "Attack", "Attack / Insight", "Generic", "Any".
function bag_type_label(_possible_type) {
	var _parts = string_split(_possible_type, " ");
	var _out = "";
	for (var i = 0; i < array_length(_parts); i++) {
		var _w = "";
		switch (_parts[i]) {
			case "ATK": _w = "Attack"; break;
			case "BLK": _w = "Block"; break;
			case "HEAL": _w = "Heal"; break;
			case "INTEL": _w = "Ink"; break;
			case "All": _w = "Any"; break;
			case "None": _w = "Generic"; break;
		}
		if (_w != "") _out += ((_out == "") ? "" : " / ") + _w;
	}
	return _out;
}

/// @func draw_header_band(_x1, _y1, _x2, _h, _r, _cols)
/// @desc A card's header band, rounded at the top and square along its bottom, in its type colour darkened so white
///       text reads. A multitype die's (die_colours, 2+) is split diagonally like its die: the first colour on the left,
///       the next from a slanted edge past the middle.
function draw_header_band(_x1, _y1, _x2, _h, _r, _cols, _darken = 0.5) {
	var _y2 = _y1 + _h;
	draw_set_color(merge_colour(_cols[0], c_black, _darken));
	draw_roundrect_ext(_x1, _y1, _x2, _y2, _r, _r, false);
	draw_rectangle(_x1, _y2 - _r, _x2, _y2, false);
	var _n = array_length(_cols);
	if (_n < 2) return;
	var _w = _x2 - _x1, _slant = _h * 0.5;
	for (var b = 1; b < _n; b++) {
		var _mx = (_n == 2) ? _x1 + _w * 0.62 : _x1 + _w * b / _n; // two: the name keeps the left
		draw_set_color(merge_colour(_cols[b], c_black, _darken));
		draw_primitive_begin(pr_trianglestrip);
		draw_vertex(_mx + _slant, _y1); draw_vertex(_x2 - _r, _y1);
		draw_vertex(_mx - _slant, _y2); draw_vertex(_x2 - _r, _y2);
		draw_primitive_end();
		draw_roundrect_ext(_x2 - _r * 2, _y1, _x2, _y2, _r, _r, false);
		draw_rectangle(_x2 - _r * 2, _y2 - _r, _x2, _y2, false);
	}
}

/// @func keyword_from_index(_index)
/// @desc The dice keyword with this sKeywordIcons index, or "" (Might and Balance are buffs: they keep their sprite).
function keyword_from_index(_index) {
	var _names = ["Stowaway", "Favourite", "Coin", "Multitype", "Followthrough", "Exclusive", "Loose", "Sticky"];
	return (_index >= 0 && _index < array_length(_names)) ? _names[_index] : "";
}

/// @func draw_keyword_icon(_key, _x, _y, _scale, _alpha)
/// @desc A dice keyword's icon, drawn in code in the logbook's style: a parchment roundel ringed in the keyword's colour
///       with an ink glyph (about 30 px across at scale 1, centred on _x, _y). Stowaway a barrel (it hides in the hold),
///       Followthrough a wake of chevrons, Exclusive a pennant (it claims the slot), Sticky a drip of tar, Loose an
///       open shackle, Favourite a star, Coin a coin, Multitype a split diamond.
function draw_keyword_icon(_key, _x, _y, _scale = 1, _alpha = 1) {
	var _s = _scale;
	var _ink = make_color_rgb(42, 29, 18);
	var _paper = make_color_rgb(236, 222, 186);
	var _ring = variable_struct_exists(global.keywords, _key) ? global.keywords[$ _key].colour : c_white;
	draw_set_alpha(_alpha);
	draw_set_color(_ink);
	draw_circle(_x, _y, 15 * _s, false);
	draw_set_color(merge_colour(_ring, _ink, 0.25));
	draw_circle(_x, _y, 13.5 * _s, false);
	draw_set_color(_paper);
	draw_circle(_x, _y, 11 * _s, false);
	draw_set_color(_ink);
	var _w = max(1, 1.8 * _s);
	switch (_key) {
		case "Stowaway": // a barrel: a fat body, two hoops, staves
			draw_roundrect_ext(_x - 6 * _s, _y - 7.5 * _s, _x + 6 * _s, _y + 7.5 * _s, 5 * _s, 5 * _s, false);
			draw_set_color(_paper);
			draw_roundrect_ext(_x - 4.2 * _s, _y - 5.8 * _s, _x + 4.2 * _s, _y + 5.8 * _s, 4 * _s, 4 * _s, false);
			draw_set_color(_ink);
			draw_line_width(_x - 5.5 * _s, _y - 3 * _s, _x + 5.5 * _s, _y - 3 * _s, _w);
			draw_line_width(_x - 5.5 * _s, _y + 3 * _s, _x + 5.5 * _s, _y + 3 * _s, _w);
			draw_line_width(_x, _y - 6 * _s, _x, _y + 6 * _s, _w * 0.7);
			break;
		case "Followthrough": // a wake: two chevrons pointing on
			for (var c = 0; c < 2; c++) {
				var _cx = _x - 3.5 * _s + c * 6 * _s;
				draw_line_width(_cx - 3 * _s, _y - 5.5 * _s, _cx + 2.5 * _s, _y, _w * 1.2);
				draw_line_width(_cx + 2.5 * _s, _y, _cx - 3 * _s, _y + 5.5 * _s, _w * 1.2);
			}
			break;
		case "Exclusive": // a pennant on a pole: it claims the slot
			draw_line_width(_x - 4.5 * _s, _y - 8 * _s, _x - 4.5 * _s, _y + 8 * _s, _w);
			draw_triangle(_x - 4 * _s, _y - 8 * _s, _x + 7 * _s, _y - 4.5 * _s, _x - 4 * _s, _y - 1 * _s, false);
			break;
		case "Sticky": // a drip of tar
			draw_circle(_x, _y + 2.5 * _s, 5 * _s, false);
			draw_triangle(_x - 4.3 * _s, _y + 0.5 * _s, _x + 4.3 * _s, _y + 0.5 * _s, _x, _y - 8 * _s, false);
			draw_set_color(_paper);
			draw_circle(_x - 1.8 * _s, _y + 1.5 * _s, 1.3 * _s, false); // a glint
			break;
		case "Loose": // an open shackle
			draw_arc_thick_deg(_x, _y - 1 * _s, 3.5 * _s, 5.5 * _s, 180, 360, 12);
			draw_line_width(_x - 4.5 * _s, _y - 1 * _s, _x - 4.5 * _s, _y + 7 * _s, _w);
			draw_line_width(_x + 4.5 * _s, _y - 1 * _s, _x + 4.5 * _s, _y + 2 * _s, _w);
			break;
		case "Favourite": // a star
			draw_primitive_begin(pr_trianglefan);
			draw_vertex(_x, _y);
			for (var p = 0; p <= 10; p++) {
				var _r = ((p mod 2) == 0 ? 8 : 3.5) * _s;
				draw_vertex(_x + lengthdir_x(_r, 90 + p * 36), _y + lengthdir_y(_r, 90 + p * 36));
			}
			draw_primitive_end();
			break;
		case "Coin": // a coin
			draw_circle(_x, _y, 7 * _s, false);
			draw_set_color(_paper);
			draw_circle(_x, _y, 4.8 * _s, true);
			break;
		case "Multitype": // a diamond split down the diagonal
			draw_triangle(_x, _y - 8 * _s, _x - 8 * _s, _y, _x, _y + 8 * _s, false);
			draw_set_color(merge_colour(_ink, _paper, 0.55));
			draw_triangle(_x, _y - 8 * _s, _x + 8 * _s, _y, _x, _y + 8 * _s, false);
			break;
	}
	draw_set_alpha(1);
	draw_set_color(c_white);
}

/// @func rarity_colour(_rarity)
/// @desc A rarity's gem colour: grey common, teal uncommon, violet rare (starters have no gem).
function rarity_colour(_rarity) {
	switch (_rarity) {
		case "uncommon": return make_color_rgb(90, 200, 175);
		case "rare":     return make_color_rgb(200, 120, 225);
	}
	return make_color_rgb(170, 170, 185);
}

/// @func draw_rarity_gem(_x, _y, _rarity, _scale, _alpha)
/// @desc A die's rarity as a small diamond gem centred on _x, _y (about 16 x 20 at scale 1). Nothing for starters.
///       Rarity is always shown as a gem, never as a word.
function draw_rarity_gem(_x, _y, _rarity, _scale = 1, _alpha = 1) {
	if (_rarity == "starter") return;
	var _s = _scale;
	draw_set_alpha(_alpha);
	draw_set_color(c_black);
	draw_primitive_begin(pr_trianglefan);
	draw_vertex(_x, _y - 10 * _s); draw_vertex(_x + 8 * _s, _y); draw_vertex(_x, _y + 10 * _s); draw_vertex(_x - 8 * _s, _y);
	draw_primitive_end();
	draw_set_color(rarity_colour(_rarity));
	draw_primitive_begin(pr_trianglefan);
	draw_vertex(_x, _y - 7 * _s); draw_vertex(_x + 5.5 * _s, _y); draw_vertex(_x, _y + 7 * _s); draw_vertex(_x - 5.5 * _s, _y);
	draw_primitive_end();
	// a glint on the upper left facet
	draw_set_color(c_white);
	draw_set_alpha(0.55 * _alpha);
	draw_primitive_begin(pr_trianglelist);
	draw_vertex(_x, _y - 5 * _s); draw_vertex(_x - 3.5 * _s, _y); draw_vertex(_x - 0.5 * _s, _y - 0.5 * _s);
	draw_primitive_end();
	draw_set_alpha(1);
	draw_set_color(c_white);
}

/// @func die_stats_line(_d, _out)
/// @desc "d6 Block, 1-6": a die's size, types and range (from get_dice_output), for tooltips on its picture.
function die_stats_line(_d, _out) {
	return "d" + string(_d.dice_value) + " " + bag_type_label(_d.possible_type) + ", " + string(_out.min_roll) + "-" + string(_out.max_roll);
}

/// @func card_keywords(_die)
/// @desc The keywords a card shows as icons under its die (F137): the die's own, but not retired Loose.
function card_keywords(_die) {
	var _out = [];
	if (!variable_struct_exists(_die, "keywords")) return _out;
	for (var i = 0; i < array_length(_die.keywords); i++) {
		var _k = _die.keywords[i];
		if (_k != "Loose" && variable_struct_exists(global.keywords, _k)) array_push(_out, _k);
	}
	return _out;
}

/// @func die_range_changed(_d, _out)
/// @desc Does this die roll something other than 1 to its size (a raised minimum, a capped maximum)? Cards show it.
function die_range_changed(_d, _out) {
	return _out.min_roll != 1 || _out.max_roll != _d.dice_value;
}

/// @func card_hero_draw(_d, _out, _x1, _x2, _y1, _dy, _r, _alpha, _interactive, _layer, [_rule], [_kw_scale])
/// @desc The top of a dice card (bag cards and the quartermaster's, layout C, F156): a thin ink-edged rule across the
///       card at _dy in the die's pigment (two halves for a multitype die), the die on it (radius _r) with its action
///       glyph bottom left, its range on a small tag bottom right when it isn't 1 to its size ("2-6"), the rarity gem top
///       right, and its keyword icons on the rule either side (hover one to read it, when _interactive). _out is its
///       read-only get_dice_output.
///       _rule false: no rule (a reward card, whose die sits on the paper's top edge instead); _kw_scale: keyword icon size.
function card_hero_draw(_d, _out, _x1, _x2, _y1, _dy, _r, _alpha, _interactive, _layer, _rule = true, _kw_scale = 0.9) {
	var _cx = (_x1 + _x2) / 2;
	var _cols = die_colours(_d.possible_type);
	draw_set_alpha(_alpha);
	if (_rule) {
		draw_set_color(global.ui_col.ink);
		draw_line_width(_x1 + 4, _dy, _x2 - 4, _dy, 5);
		draw_set_color(_cols[0]);
		draw_line_width(_x1 + 5, _dy, (array_length(_cols) > 1) ? _cx : _x2 - 5, _dy, 3);
		if (array_length(_cols) > 1) {
			draw_set_color(_cols[1]);
			draw_line_width(_cx, _dy, _x2 - 5, _dy, 3);
		}
	}
	draw_rarity_gem(_x2 - 20, _y1 + 20, _d.rarity, 1, _alpha);

	draw_die(_cx, _dy, _r, _d.dice_value, -1, _cols, 0, _alpha, _d);
	var _k = _r / 36;
	if (global.action_icons) draw_action_type_icon(_d.action_type, _cx - 31 * _k, _dy + 31 * _k, 0.75 * _k, _alpha);

	// a changed range (a raised minimum: "2-6"), small, on a paper tag at the die's foot (Jared, 2026-11-20)
	if (die_range_changed(_d, _out)) {
		var _txt = string(_out.min_roll) + "-" + string(_out.max_roll);
		draw_set_font(ftDescriptions);
		var _tw = string_width(_txt) + 12, _th = 24;
		var _tx = _cx + 33 * _k, _ty = _dy + 31 * _k;
		draw_set_alpha(_alpha);
		draw_set_color(global.ui_col.ink);
		draw_roundrect_ext(_tx - _tw / 2 - 2, _ty - _th / 2 - 2, _tx + _tw / 2 + 2, _ty + _th / 2 + 2, 8, 8, false);
		draw_set_color(global.ui_col.paper_hi);
		draw_roundrect_ext(_tx - _tw / 2, _ty - _th / 2, _tx + _tw / 2, _ty + _th / 2, 6, 6, false);
		draw_set_color(global.ui_col.ink);
		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		draw_text(_tx, _ty + 1, _txt);
		if (_interactive && mouse_hovering(_tx, _ty, _tw, _th, true, noone, noone, true, _layer)) {
			queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), "Rolls " + _txt, "This die rolls " + string(_out.min_roll) + " to " + string(_out.max_roll) + " instead of 1 to " + string(_d.dice_value) + ".");
		}
	}

	// its keywords as icons on the rule, alternately left and right of the die, each explained on hover (F137); asked
	// for before the die's tip so they win
	var _kws = card_keywords(_d);
	for (var k = 0; k < array_length(_kws); k++) {
		var _side = (k mod 2 == 0) ? -1 : 1;
		var _kx = _cx + _side * (_r + 26 * _kw_scale / 0.9 + (k div 2) * 32 * _kw_scale / 0.9), _ky = _dy;
		draw_keyword_icon(_kws[k], _kx, _ky, _kw_scale, _alpha);
		if (_interactive && mouse_hovering(_kx, _ky, 29 * _kw_scale, 29 * _kw_scale, true, noone, noone, true, _layer)) {
			queue_tooltip(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), _kws[k], global.keywords[$ _kws[k]].desc, sKeywordIcons, global.keywords[$ _kws[k]].index);
		}
	}
	draw_set_alpha(1);
}

/// @func bag_card_layout(_d, _w)
/// @desc Where things go on a bag card (layout C, Jared 2026-11-20), measured from its text: the die centred at the top
///       on a rule across the card, its name under it, then the description, then a fitted core's distribution across the
///       full width. h is the height it needs.
function bag_card_layout(_d, _w) {
	var _die_y = 54;                  // the die's centre, from the card's top
	var _name_y = _die_y + 52;        // the name's top
	draw_set_font(ftBig);
	var _name_h = string_height_ext(_d.name, -1, _w - 28);
	var _text_x = 16;
	var _text_w = _w - _text_x * 2;
	var _text_y = _name_y + _name_h + 8;
	draw_set_font(ftDefault); // the effect at 16 px: more words a line (Molly)
	var _line = font_get_size(ftDefault) * 1.5; // the line height coloured text wraps at (draw_outline_text)
	var _desc_h = string_height_ext(die_description(_d), _line, _text_w);
	var _info_bottom = _text_y + _desc_h + 14;
	var _bars_h = (_d.distribution != "") ? (5 + 30 + 5 + 15) + 12 : 0; // draw_dice_distribution at scale 1, and a gap
	return { die_y: _die_y, name_y: _name_y, text_x: _text_x, text_w: _text_w, text_y: _text_y, bars_bottom: _info_bottom + _bars_h, h: _info_bottom + _bars_h };
}

/// @func draw_bag_card(_d, _cx, _cy, _w, _h, _alpha, _hover, _selected)
/// @desc A die's card in the bag view, the dice picker and fight rewards, centred on _cx, _cy (bag_card_layout), layout C
///       of docs/mockups/dice-card-layout.html (F156):
///       - the die drawn in code, centred at the top, on a thin rule across the card in its colour (split for
///         multitype); its keyword icons sit on the rule either side of it (hover one to read it); its rarity gem top right
///       - its name under the die, centred
///       - what it does, in ink ("d6 Block, 1-6" only on hovering the die)
///       - a fitted core: its distribution across the card's full width (the core isn't described)
///       Lifts with a brass edge when hovered; a green edge and tick when picked.
function draw_bag_card(_d, _cx, _cy, _w, _h, _alpha, _hover, _selected, _style = "reward") {
	var _lay = bag_card_layout(_d, _w);
	var _x1 = _cx - _w / 2, _y1 = _cy - _h / 2 - (_hover ? 5 : 0);
	var _x2 = _x1 + _w, _y2 = _y1 + _h;
	// "reward" (Jared, 2026-11-21; first on fight rewards, then every dice card: bag, picker, rewards): no rule; the paper
	// starts where the rule was, so the die sits over its top edge, with its keyword icons a little bigger on the same line.
	// "rule" keeps the old look (the rule across the paper), if it's ever wanted again.
	var _reward = (_style != "rule");
	var _pt = _reward ? _y1 + _lay.die_y : _y1; // the paper's top
	if (_hover || _selected) {
		draw_set_alpha(_alpha);
		draw_set_color(_selected ? global.color_heal : global.ui_col.brass);
		draw_roundrect_ext(_x1 - 6, _pt - 6, _x2 + 6, _y2 + 6, 14, 14, false);
		draw_set_alpha(1);
	}
	ui_paper(_x1, _pt, _x2, _y2, (variable_struct_exists(_d, "uid") ? _d.uid : 1) * 3 + 1, global.ui_col.paper, _alpha);

	// the die on its rule (or the paper's edge), the gem, a changed range, the keywords (card_hero_draw)
	var _dx = _cx, _dy = _y1 + _lay.die_y;
	var _out = get_dice_output(_d, -1, -1, true, "player"); // read only: viewing the bag must never trigger keepsakes
	card_hero_draw(_d, _out, _x1, _x2, _reward ? _pt + 6 : _y1, _dy, 36, _alpha, _hover && _alpha > 0.5, max(global.ui_layer, UI_LAYER.BAG), !_reward, _reward ? 1.1 : 0.9); // hoverable on whatever layer shows it (the bag, a reward popup)

	// its name under it, then what it does, in ink
	draw_set_alpha(_alpha);
	draw_set_font(ftBig);
	draw_set_halign(fa_center);
	draw_set_valign(fa_top);
	draw_set_color(global.ui_col.ink);
	draw_text_ext(_cx, _y1 + _lay.name_y, _d.name, -1, _w - 28);
	draw_set_font(ftDefault);
	draw_set_halign(fa_center); // centred under the name (coloured text follows halign since B82)
	ui_paper_text(colorcode_text(die_description(_d)), _cx, _y1 + _lay.text_y, _lay.text_w, _alpha);
	draw_set_halign(fa_left);


	// its size, type and range on hovering the die
	if (_hover && mouse_hovering(_dx, _dy, 80, 80, true, noone, noone, true, max(global.ui_layer, UI_LAYER.BAG))) queue_die_tip(_d, _dx, _dy - 40, die_stats_line(_d, _out));

	// a fitted core: how it shapes this die's faces, across the card's full width under its words
	if (_d.distribution != "") {
		draw_set_alpha(_alpha);
		draw_dice_distribution(_d, _cx, _y1 + _lay.bars_bottom - 12, true, 1, true, _w - 28);
	}

	// picked (dice picker): a green tick stamped on the corner
	if (_selected) {
		var _kx = _x2 - 6, _ky = _y2 - 6;
		draw_set_color(global.ui_col.ink);
		draw_circle(_kx, _ky, 17, false);
		draw_set_color(global.color_heal);
		draw_circle(_kx, _ky, 14, false);
		draw_set_color(global.ui_col.paper_hi);
		draw_line_width(_kx - 7, _ky, _kx - 1, _ky + 6, 3.5);
		draw_line_width(_kx - 1, _ky + 6, _kx + 8, _ky - 6, 3.5);
	}

	draw_set_alpha(1);
	draw_set_color(c_white);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
}

/// @func reward_flip_state(_t, _i)
/// @desc Where fight reward card _i is in its reveal (F145), _t frames after the dice rewards showed: face down until
///       its turn (a short wait, then one every 14 frames), then 8 frames squashing shut, then face up.
///       Returns { face_up, squash (0-1, the back's width), turned_now (the frame it turns), since (frames face up),
///       pop (0-1, a little lift as it lands), fade_in (0-1) }.
function reward_flip_state(_t, _i) {
	var _start = 16 + _i * 14, _shut = 8;
	var _since = _t - (_start + _shut);
	if (_since < 0) return { face_up: false, squash: clamp(1 - (_t - _start) / _shut, 0.02, 1), turned_now: false, since: -1, pop: 0, fade_in: 0 };
	return { face_up: true, squash: 1, turned_now: (_since == 0), since: _since, pop: max(0, 1 - _since / 10), fade_in: min(1, 0.35 + _since / 8) };
}

/// @func reward_card_back(_cx, _cy, _w, _h, _seed)
/// @desc A reward card face down: dark slate in a brass frame with a compass star, squashed to _w as it flips.
function reward_card_back(_cx, _cy, _w, _h, _seed) {
	var _x1 = _cx - _w / 2, _x2 = _cx + _w / 2, _y1 = _cy - _h / 2, _y2 = _cy + _h / 2;
	var _bob = sin(current_time / 260 + _seed) * 3;
	_y1 += _bob; _y2 += _bob;
	draw_set_color(global.ui_col.ink);
	draw_roundrect_ext(_x1 - 3, _y1 - 3, _x2 + 3, _y2 + 3, 14, 14, false);
	draw_set_color(global.ui_col.brass);
	draw_roundrect_ext(_x1, _y1, _x2, _y2, 12, 12, false);
	draw_set_color(global.ui_col.slate);
	draw_roundrect_ext(_x1 + 6, _y1 + 6, _x2 - 6, _y2 - 6, 9, 9, false);
	// the compass star, squashed with the card
	var _sx = _w / 320, _my = (_y1 + _y2) / 2, _r = 46;
	draw_set_color(global.ui_col.brass);
	for (var a = 0; a < 4; a++) {
		var _ang = a * 90 + 90;
		draw_triangle(_cx + lengthdir_x(_r, _ang) * _sx, _my + lengthdir_y(_r, _ang), _cx + lengthdir_x(9, _ang + 90) * _sx, _my + lengthdir_y(9, _ang + 90), _cx + lengthdir_x(9, _ang - 90) * _sx, _my + lengthdir_y(9, _ang - 90), false);
	}
	draw_set_color(global.ui_col.slate);
	draw_circle(_cx, _my, 5 * max(0.3, _sx), false);
	draw_set_color(c_white);
}

/// @func reward_rarity_flash(_rarity, _cx, _cy, _w, _h, _since, _alpha)
/// @desc As a reward card turns face up (F145): a glow in its rarity's colour that blooms and fades (bigger and longer for
///       rarer cards; a rare one also throws rays), then a small rarity label under the card stays.
function reward_rarity_flash(_rarity, _cx, _cy, _w, _h, _since, _alpha = 1) {
	var _col = rarity_colour(_rarity);
	var _power = (_rarity == "rare") ? 1 : ((_rarity == "uncommon") ? 0.6 : 0.25);
	var _len = 18 + 22 * _power;
	if (_since >= 0 && _since < _len) {
		var _k = _since / _len;
		var _grow = 10 + 40 * _power * _k;
		draw_set_alpha((1 - _k) * 0.7 * _power + 0.1 * (1 - _k));
		draw_set_color(_col);
		draw_roundrect_ext(_cx - _w / 2 - _grow, _cy - _h / 2 - _grow, _cx + _w / 2 + _grow, _cy + _h / 2 + _grow, 24, 24, false);
		if (_rarity == "rare") {
			draw_set_alpha((1 - _k) * 0.6);
			for (var a = 0; a < 12; a++) {
				var _ang = a * 30 + _since * 2;
				var _r1 = _h * 0.55 + 20 * _k, _r2 = _r1 + 60 + 80 * _k;
				draw_line_width(_cx + lengthdir_x(_r1, _ang), _cy + lengthdir_y(_r1, _ang), _cx + lengthdir_x(_r2, _ang), _cy + lengthdir_y(_r2, _ang), 4);
			}
		}
		draw_set_alpha(1);
	}
	// its rarity, named under the card (starter dice never come as rewards)
	if (_rarity != "starter") {
		draw_set_font(ftDefault);
		draw_set_halign(fa_center);
		draw_set_valign(fa_top);
		var _txt = string_upper(string_char_at(_rarity, 1)) + string_copy(_rarity, 2, string_length(_rarity) - 1);
		draw_outline_text(_txt, global.ui_col.ink, _col, 2, _cx, _cy + _h / 2 + 12, 1, _alpha * min(1, max(0, _since) / 10), 0);
	}
	draw_set_color(c_white);
}

// =====================================================================
// THE QUARTERMASTER'S OFFER (the start of a run: one die, fitted with a core)
// =====================================================================

/// @func offering_draw()
/// @desc oRunManager Draw GUI: a logbook page with three offer cards (offering_card_draw). Click a card to choose it,
///       then the button takes it: the die goes into your bag with its core already fitted.
function offering_draw() {
	var _gw = display_get_gui_width(), _gh = display_get_gui_height();
	var _ink = make_color_rgb(42, 29, 18);
	var _paper = make_color_rgb(231, 214, 176);

	// the map behind, dimmed; the top bar stays in full colour
	draw_set_alpha(0.8);
	draw_set_color(c_black);
	draw_rectangle(0, ui_top_bar_h(), _gw, _gh, false);
	draw_set_alpha(1);

	// the cards are as tall as the tallest one needs (offering_card_layout); the page fits round them
	var _cw = 400, _gap = 40;
	var _n = array_length(oRunManager.offering);
	var _ch = 0;
	for (var r = 0; r < _n; r++) _ch = max(_ch, offering_card_layout(oRunManager.offering[r], _cw).h);

	// the page: heading 140, the cards, then the bag and button row
	var _pw = 1400, _ph = 140 + _ch + 150;
	var _px = (_gw - _pw) / 2, _py = ui_top_bar_h() + (_gh - ui_top_bar_h() - _ph) / 2;
	// a dark slate window like every other one (bag view, settings, pause), with the paper cards on it: paper is for
	// things in the world, and the first-voyage notes (paper) now stand out against it (Jared, 2026-11-21)
	ui_panel(_px, _py, _px + _pw, _py + _ph);

	// the heading
	draw_set_halign(fa_center);
	draw_set_valign(fa_middle);
	draw_set_font(ftBigger);
	draw_set_color(global.ui_col.paper_hi);
	draw_text(_gw / 2, _py + 56, "The quartermaster's offer");
	draw_set_font(ftDefault);
	draw_set_color(global.ui_col.rule);
	draw_text(_gw / 2, _py + 96, "Take one die with a core. A core changes which faces it rolls most.");

	// the cards
	var _cx0 = _gw / 2 - ((_n - 1) * (_cw + _gap)) / 2;
	var _ctop = _py + 140;
	for (var r = 0; r < _n; r++) {
		var _off = oRunManager.offering[r];
		var _cx = _cx0 + r * (_cw + _gap);
		var _hover = mouse_hovering(_cx - _cw / 2, _ctop, _cw, _ch, false, soPaper5, soClick4, true, UI_LAYER.POPUP); // the slots' paper (Jared, 2026-11-23)
		var _chosen = (oRunManager.offer_selected == r);
		_off.lift = lerp(_off.lift, _chosen ? 12 : (_hover ? 6 : 0), 0.25);
		offering_card_draw(_off, _cx, _ctop - _off.lift, _cw, _ch, _hover, _chosen);
		if (_hover && mouse_check_button_pressed(mb_left)) oRunManager.offer_selected = r;
	}

	// the foot of the page: your bag (and what joins it), and the button
	var _fy = _py + _ph - 66;
	draw_set_font(ftDefault);
	draw_set_halign(fa_left);
	draw_set_valign(fa_middle);
	draw_set_color(global.ui_col.paper_hi);
	var _bx = _px + 50;
	draw_text(_bx, _fy, "Your bag:");
	_ink = global.ui_col.rule; // the bag strip's dice are outlined light, on the dark window
	// one die every 40px: a d4's triangle is about 33px across here, so they never touch. Hover one to see what it is.
	_bx += string_width("Your bag:") + 34; // the first die's centre
	for (var d = 0; d < ds_list_size(global.dice_bag); d++) {
		offering_bag_icon(global.dice_bag[| d], _bx, _fy, _ink);
		_bx += 40;
	}
	var _sel = oRunManager.offer_selected;
	if (_sel >= 0) {
		// "+ the chosen die", with clear space either side of the plus
		draw_set_font(ftBig);
		draw_set_halign(fa_center);
		draw_set_color(make_color_rgb(40, 130, 60));
		draw_text(_bx + 2, _fy - 2, "+");
		draw_set_font(ftDefault);
		draw_set_halign(fa_left);
		offering_bag_icon(oRunManager.offering[_sel].dice, _bx + 40, _fy, _ink);
	}

	var _label = (_sel >= 0) ? "Take the " + oRunManager.offering[_sel].dice.name : "Choose a die";
	var _btn = ui_button(_px + _pw - 200, _fy, 300, 64, oRunManager.offer_btn_scale, _label, global.ui_primary, _sel >= 0, "Choose a die first.", UI_LAYER.POPUP, 1, ftDefault);
	oRunManager.offer_btn_scale = _btn.scale;
	if (_btn.click && _sel >= 0) offering_take(_sel, _px + _pw - 200, _fy);

	draw_set_color(c_white);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
}

/// @func offering_bag_icon(_d, _x, _y, _ink)
/// @desc A die in the bag strip under the offer: its shape in its colour, inked round the edge. Hover: a little bigger,
///       and its tooltip (name, what it does, keywords).
function offering_bag_icon(_d, _x, _y, _ink) {
	var _hover = mouse_hovering(_x, _y, 36, 36, true, noone, noone, true, UI_LAYER.POPUP);
	var _s = _hover ? 1.2 : 1;
	draw_die_shape(_x, _y, 14 * _s, _d.dice_value, _hover ? c_white : _ink, 0, 1);
	draw_die_shape(_x, _y, 11 * _s, _d.dice_value, die_colours(_d.possible_type), 0, 1);
	if (_hover) queue_die_tip(_d, _x, _y - 18);
}

/// @func offering_card_layout(_off, _w)
/// @desc Where things go on an offer card, from the top, measured from its text so there's no dead space (layout C, like
///       the bag's cards): the die on its rule, the name under it, the description, then the core section (core_y),
///       then the bars across the full width. h is the height the card needs.
function offering_card_layout(_off, _w) {
	var _die_y = 62;                  // the die's centre (radius 40)
	var _name_y = _die_y + 58;
	draw_set_font(ftBig);
	var _name_h = string_height_ext(_off.dice.name, -1, _w - 36);
	var _text_w = _w - 44;
	var _text_y = _name_y + _name_h + 10;
	var _core_w = _w - 80 - 18;           // beside the core icon
	draw_set_font(ftDefault);
	var _desc_h = string_height_ext(die_description(_off.dice), font_get_size(ftDefault) * 1.5, _text_w);
	draw_set_font(ftDescriptions);
	var _line = font_get_size(ftDescriptions) * 1.2;
	var _core_desc_h = string_height_ext(_off.core.description, _line, _core_w);
	var _core_y = _text_y + _desc_h + 18;
	var _bars_top = _core_y + 44 + _core_desc_h + 18;
	var _bars_h = (5 + 30 + 5 + 15) * 1.4; // draw_dice_distribution at scale 1.4
	return { die_y: _die_y, name_y: _name_y, text_y: _text_y, text_w: _text_w, core_w: _core_w, core_y: _core_y, bars_bottom: _bars_top + _bars_h, h: _bars_top + _bars_h + 20 };
}

/// @func offering_card_draw(_off, _cx, _top, _w, _h, _hover, _chosen)
/// @desc One offer, in layout C like the bag's cards (card_hero_draw): the die centred on a rule in its colour, its
///       name under it, what it does; then its core: icon, name, what it does, and how it shapes this die's faces (the
///       bars, across the full width). Laid out by offering_card_layout; _h is the shared height.
function offering_card_draw(_off, _cx, _top, _w, _h, _hover, _chosen) {
	var _d = _off.dice, _core = _off.core;
	var _lay = offering_card_layout(_off, _w);
	var _x1 = _cx - _w / 2, _x2 = _cx + _w / 2, _y1 = _top, _y2 = _top + _h;

	// the same paper card as the bag's, a shade brighter than the page it lies on; hover: a brass edge, chosen: green
	// like every dice card (Jared, 2026-11-21): the paper starts at the die's middle, so the die sits over its top edge
	var _pt = _y1 + _lay.die_y;
	if (_hover || _chosen) {
		draw_set_color(_chosen ? global.color_heal : global.ui_col.brass);
		draw_roundrect_ext(_x1 - 7, _pt - 7, _x2 + 7, _y2 + 7, 16, 16, false);
	}
	ui_paper(_x1, _pt, _x2, _y2, _cx * 0.37 + 2, global.ui_col.paper_hi, 1);

	// the die on the paper's edge, then its name and what it does
	var _dy = _pt;
	var _out = get_dice_output(_d, -1, -1, true, "player");
	card_hero_draw(_d, _out, _x1, _x2, _pt + 6, _dy, 40, 1, true, UI_LAYER.POPUP, false, 1.1);
	draw_set_font(ftBig);
	draw_set_halign(fa_center);
	draw_set_valign(fa_top);
	draw_set_color(global.ui_col.ink);
	draw_text_ext(_cx, _y1 + _lay.name_y, _d.name, -1, _w - 36);
	draw_set_font(ftDefault);
	draw_set_halign(fa_center); // centred under the name (coloured text follows halign since B82)
	ui_paper_text(colorcode_text(die_description(_d)), _cx, _y1 + _lay.text_y, _lay.text_w);
	draw_set_halign(fa_left);
	if (mouse_hovering(_cx, _dy, 90, 90, true, noone, noone, true, UI_LAYER.POPUP)) queue_die_tip(_d, _cx, _dy - 46, die_stats_line(_d, _out));

	// the core, just under the die's words
	var _cy = _y1 + _lay.core_y;
	draw_set_color(global.ui_col.paper_shade);
	draw_line_width(_x1 + 18, _cy, _x2 - 18, _cy, 2);
	draw_sprite_ext(sCores, _core.index, _x1 + 42, _cy + 40, 0.8, 0.8, 0, c_white, 1);
	draw_set_font(ftDefault);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_outline_text(_core.name, global.ui_col.paper_hi, global.ui_col.ink, 1, _x1 + 80, _cy + 16, 1, 1, 0);
	draw_set_font(ftDescriptions);
	ui_paper_text(_core.description, _x1 + 80, _cy + 44, _lay.core_w);

	// how this core shapes this die's faces, across the foot of the card (cards share a height, so the bars line up)
	var _preview = clone_die(_d, "");
	_preview.distribution = _core.distribution;
	draw_dice_distribution(_preview, _cx, _y2 - 20, true, 1.4, true, _w - 40);

	// chosen: a green tick stamped on the corner (bottom right: the gem has the top)
	if (_chosen) {
		var _kx = _x2 - 4, _ky = _y2 - 4;
		draw_set_color(global.ui_col.ink);
		draw_circle(_kx, _ky, 18, false);
		draw_set_color(global.color_heal);
		draw_circle(_kx, _ky, 15, false);
		draw_set_color(global.ui_col.paper_hi);
		draw_line_width(_kx - 7, _ky, _kx - 1, _ky + 6, 3.5);
		draw_line_width(_kx - 1, _ky + 6, _kx + 8, _ky - 6, 3.5);
	}
	draw_set_color(c_white);
	draw_set_alpha(1);
}

/// @func offering_take(_index, _x, _y)
/// @desc The chosen die, with its core fitted, flies into your bag (an oDiceParticle adds it when it lands).
function offering_take(_index, _x, _y) {
	var _off = oRunManager.offering[_index];
	var _die = clone_die(_off.dice, "");
	_die.distribution = _off.core.distribution; // the core comes fitted, not as an item
	var _p = instance_create_layer(_x, _y, "Instances", oDiceParticle);
	_p.target_x = global.gui.bag_x + global.gui.bag_w / 2;
	_p.target_y = global.gui.bag_y + global.gui.bag_h / 2;
	_p.color_main = get_dice_color(_die.possible_type);
	_p.die_struct = _die;
	oRunManager.new_run_offering = false;
	oRunManager.offer_selected = -1;
	global.ui_layer = UI_LAYER.BASE;
	global.bag_size++;
}

/// @func draw_padlock(_x, _y, _scale, _col)
/// @desc A small padlock centred on _x, _y (about 22 x 26 at scale 1): a shackle arc over a body with a keyhole.
function draw_padlock(_x, _y, _scale, _col) {
	var _s = _scale;
	draw_set_color(c_black);
	draw_arc_thick_deg(_x, _y - 4 * _s, 5 * _s, 10 * _s, 180, 360, 16); // the top half (y grows downwards)
	draw_roundrect_ext(_x - 12 * _s, _y - 5 * _s, _x + 12 * _s, _y + 14 * _s, 5 * _s, 5 * _s, false);
	draw_set_color(_col);
	draw_arc_thick_deg(_x, _y - 4 * _s, 6.5 * _s, 8.5 * _s, 180, 360, 16);
	draw_roundrect_ext(_x - 10 * _s, _y - 3 * _s, _x + 10 * _s, _y + 12 * _s, 4 * _s, 4 * _s, false);
	draw_set_color(c_black);
	draw_circle(_x, _y + 3 * _s, 2.5 * _s, false);
	draw_line_width(_x, _y + 3 * _s, _x, _y + 8 * _s, 2 * _s);
	draw_set_color(c_white);
}

/// @func draw_inkwell(_x, _y, _scale, _fill, _blotted)
/// @desc Your insight as an inkwell (about 50 x 46 at scale 1, centred on _x, _y): a squat dark glass pot, golden ink
///       inside filled to _fill (0-1), a quill standing in it while there's ink. Blotted: the pot tipped over, spilled.
function draw_inkwell(_x, _y, _scale, _fill, _blotted) {
	var _s = _scale;
	var _ink = global.color_intel;
	var _glass = make_color_rgb(32, 36, 52);
	var _rim = make_color_rgb(70, 76, 100);
	if (_blotted) {
		draw_insight_icon("blotted", _x + 6 * _s, _y + 14 * _s, 1.1 * _s, 1); // the spill
		draw_set_color(c_black);
		draw_roundrect_ext(_x - 22 * _s, _y - 14 * _s, _x + 8 * _s, _y + 10 * _s, 10 * _s, 10 * _s, false); // the pot on its side
		draw_set_color(_glass);
		draw_roundrect_ext(_x - 20 * _s, _y - 12 * _s, _x + 6 * _s, _y + 8 * _s, 9 * _s, 9 * _s, false);
		draw_set_color(c_white);
		return;
	}
	// the quill behind the pot, leaning right, while there's ink to write with
	if (_fill > 0) draw_quill(_x + 2 * _s, _y - 2 * _s, 44 * _s, 62);
	// the pot: outline, glass, then the ink, then a shine
	draw_set_color(c_black);
	draw_roundrect_ext(_x - 25 * _s, _y - 8 * _s, _x + 25 * _s, _y + 24 * _s, 14 * _s, 14 * _s, false);
	draw_roundrect_ext(_x - 12 * _s, _y - 20 * _s, _x + 12 * _s, _y - 4 * _s, 5 * _s, 5 * _s, false);
	draw_set_color(_glass);
	draw_roundrect_ext(_x - 22 * _s, _y - 5 * _s, _x + 22 * _s, _y + 21 * _s, 12 * _s, 12 * _s, false);
	draw_set_color(_rim);
	draw_roundrect_ext(_x - 9 * _s, _y - 17 * _s, _x + 9 * _s, _y - 6 * _s, 4 * _s, 4 * _s, false);
	var _f = clamp(_fill, 0, 1);
	if (_f > 0) {
		var _top = _y + 19 * _s - 22 * _s * _f; // the ink's surface rises with your insight
		draw_set_color(_ink);
		draw_roundrect_ext(_x - 20 * _s, _top, _x + 20 * _s, _y + 19 * _s, 10 * _s, 10 * _s, false);
		draw_set_color(merge_colour(_ink, c_white, 0.45));
		draw_line_width(_x - 16 * _s, _top + 2 * _s, _x + 16 * _s, _top + 2 * _s, 2 * _s);
	}
	draw_set_alpha(0.35);
	draw_set_color(c_white);
	draw_roundrect_ext(_x - 18 * _s, _y - 2 * _s, _x - 12 * _s, _y + 12 * _s, 3 * _s, 3 * _s, false);
	draw_set_alpha(1);
	draw_set_color(c_white);
}

/// @func draw_quill(_nx, _ny, _len, _dir)
/// @desc A feather quill in code (after Jared's reference): its nib at _nx, _ny, the feather reaching _len pixels in
///       direction _dir (degrees, 0 right, 90 up). A parchment-white vane, wider on its upper side and curling
///       towards its tip, with a few notches; a bare shaft near the nib; a dark split nib with a gold band; an ink outline.
function draw_quill(_nx, _ny, _len, _dir) {
	var _ink = make_color_rgb(34, 26, 20);
	var _vane = make_color_rgb(244, 236, 214);
	var _shade = make_color_rgb(214, 202, 172);
	var _steps = 16;
	var _left = [], _right = [], _axis = [];
	for (var i = 0; i <= _steps; i++) {
		var _t = i / _steps;
		// the shaft bends a little as it goes, like the reference
		var _d = _dir + 10 * _t * _t;
		var _ax = _nx + lengthdir_x(_len * _t, _d), _ay = _ny + lengthdir_y(_len * _t, _d);
		// the vane: none near the nib, widest about two thirds up, a curled point at the tip
		var _w = (_t < 0.16) ? 0 : sin(pi * clamp((_t - 0.16) / 0.84, 0, 1)) * _len * 0.2;
		var _wl = _w * (1 + 0.25 * _t), _wr = _w * 0.62;
		array_push(_axis, [_ax, _ay]);
		array_push(_left, [_ax + lengthdir_x(_wl, _d + 90), _ay + lengthdir_y(_wl, _d + 90)]);
		array_push(_right, [_ax + lengthdir_x(_wr, _d - 90), _ay + lengthdir_y(_wr, _d - 90)]);
	}
	// the outline: the vane a touch bigger in ink first
	for (var _pass = 0; _pass < 2; _pass++) {
		var _grow = (_pass == 0) ? 2 : 0;
		draw_set_color((_pass == 0) ? _ink : _vane);
		draw_primitive_begin(pr_trianglelist);
		for (var i = 0; i < _steps; i++) {
			var _d = _dir + 10 * (i / _steps) * (i / _steps);
			var _ux = lengthdir_x(_grow, _d + 90), _uy = lengthdir_y(_grow, _d + 90);
			var _l0 = _left[i], _l1 = _left[i + 1], _r0 = _right[i], _r1 = _right[i + 1];
			draw_vertex(_l0[0] + _ux, _l0[1] + _uy); draw_vertex(_l1[0] + _ux, _l1[1] + _uy); draw_vertex(_r0[0] - _ux, _r0[1] - _uy);
			draw_vertex(_l1[0] + _ux, _l1[1] + _uy); draw_vertex(_r1[0] - _ux, _r1[1] - _uy); draw_vertex(_r0[0] - _ux, _r0[1] - _uy);
		}
		draw_primitive_end();
	}
	// a soft shade along the lower half of the vane
	draw_set_color(_shade);
	draw_primitive_begin(pr_trianglelist);
	for (var i = 0; i < _steps; i++) {
		var _a0 = _axis[i], _a1 = _axis[i + 1], _r0 = _right[i], _r1 = _right[i + 1];
		draw_vertex(_a0[0], _a0[1]); draw_vertex(_a1[0], _a1[1]); draw_vertex(_r0[0], _r0[1]);
		draw_vertex(_a1[0], _a1[1]); draw_vertex(_r1[0], _r1[1]); draw_vertex(_r0[0], _r0[1]);
	}
	draw_primitive_end();
	// notches: little cuts slanting back from the edge towards the shaft
	draw_set_color(_ink);
	var _notches = [[0.38, 1], [0.56, 1], [0.74, 1], [0.47, -1], [0.66, -1]];
	for (var n = 0; n < array_length(_notches); n++) {
		var _i = floor(_notches[n][0] * _steps);
		var _edge = (_notches[n][1] > 0) ? _left[_i] : _right[_i];
		var _in = _axis[max(0, _i - 1)];
		draw_line_width(_edge[0], _edge[1], lerp(_edge[0], _in[0], 0.55), lerp(_edge[1], _in[1], 0.55), max(1.5, _len * 0.025));
	}
	// the shaft, through the vane to the tip
	draw_set_color(_ink);
	for (var i = 0; i < _steps; i++) draw_line_width(_axis[i][0], _axis[i][1], _axis[i + 1][0], _axis[i + 1][1], max(1.5, _len * (i < 3 ? 0.045 : 0.025)));
	// the nib: a dark point with a gold band behind it, and its slit
	var _b = _axis[2];
	var _nd = _dir;
	draw_set_color(_ink);
	draw_triangle(_nx, _ny, _b[0] + lengthdir_x(_len * 0.05, _nd + 90), _b[1] + lengthdir_y(_len * 0.05, _nd + 90), _b[0] + lengthdir_x(_len * 0.05, _nd - 90), _b[1] + lengthdir_y(_len * 0.05, _nd - 90), false);
	draw_set_color(make_color_rgb(220, 180, 70));
	draw_line_width(_b[0] + lengthdir_x(_len * 0.055, _nd + 90), _b[1] + lengthdir_y(_len * 0.055, _nd + 90), _b[0] + lengthdir_x(_len * 0.055, _nd - 90), _b[1] + lengthdir_y(_len * 0.055, _nd - 90), max(2, _len * 0.04));
	draw_set_color(c_white);
}

/// @func workbench_owns_tool(_name)
/// @desc Does the player have this tool (by name, e.g. "The Hammer")?
function workbench_owns_tool(_name) {
	if (!instance_exists(oRunManager) || !ds_safe_exists(oRunManager.tools, ds_type_list)) return false;
	for (var i = 0; i < ds_list_size(oRunManager.tools); i++) {
		var _t = oRunManager.tools[| i];
		if (is_struct(_t) && variable_struct_exists(_t, "name") && _t.name == _name) return true;
	}
	return false;
}

/// @func ui_health_spot()
/// @desc Where your health is in the top bar (oRunManager Draw GUI sets global.heal_pos each frame): healing sparkles go here.
function ui_health_spot() {
	var _x = variable_global_exists("heal_pos") ? global.heal_pos : 44;
	return { x: _x + 30, y: ui_top_bar_h() / 2 };
}

/// @func item_card_layout(_it, _w)
/// @desc Where things go on an item reward card (draw_item_card), from its top: the icon's centre on the paper's top edge
///       (icon_y), the name, the description, a core's distribution. h is the height it needs.
function item_card_layout(_it, _w) {
	var _icon_y = 46;
	var _name_y = _icon_y + 46;
	draw_set_font(ftBig);
	var _name_h = string_height_ext(_it.name, -1, _w - 28);
	var _desc_y = _name_y + _name_h + 8;
	draw_set_font(ftDefault);
	var _desc_h = string_height_ext(string(_it.description), font_get_size(ftDefault) * 1.5, _w - 32);
	var _bars = (variable_struct_exists(_it, "type") && _it.type == "core") ? (5 + 30 + 5 + 15) + 12 : 0;
	return { icon_y: _icon_y, name_y: _name_y, desc_y: _desc_y, h: _desc_y + _desc_h + _bars + 20 };
}

/// @func ui_burn_begin() / ui_burn_end(_t, _seed, _x1, _y1, _x2, _y2)
/// @desc Burns away whatever is drawn between them (F183, like the draft page's page_burn_draw): begin sends drawing to
///       a screen-sized surface, end draws it through shBurn at _t (0 whole to 1 gone, eased) and sends up embers over
///       the box. Draw GUI only.
function ui_burn_begin() {
	var _gw = display_get_gui_width(), _gh = display_get_gui_height();
	if (!variable_global_exists("ui_burn_surf") || !surface_exists(global.ui_burn_surf) || surface_get_width(global.ui_burn_surf) != _gw || surface_get_height(global.ui_burn_surf) != _gh) {
		if (variable_global_exists("ui_burn_surf") && surface_exists(global.ui_burn_surf)) surface_free(global.ui_burn_surf);
		global.ui_burn_surf = surface_create(_gw, _gh);
	}
	surface_set_target(global.ui_burn_surf);
	draw_clear_alpha(c_black, 0);
}
function ui_burn_end(_t, _seed, _x1, _y1, _x2, _y2) {
	surface_reset_target();
	var _gw = display_get_gui_width(), _gh = display_get_gui_height();
	var _e = lerp(-0.15, 1.05, _t * _t * (3 - 2 * _t)); // slow to catch, then quicker
	shader_set(shBurn);
	shader_set_uniform_f(shader_get_uniform(shBurn, "u_t"), _e);
	shader_set_uniform_f(shader_get_uniform(shBurn, "u_seed"), _seed);
	shader_set_uniform_f(shader_get_uniform(shBurn, "u_scale"), _gw / 120, _gh / 120);
	draw_surface(global.ui_burn_surf, 0, 0);
	shader_reset();
	if (_t < 0.9) {
		if (random(1) < 0.5) particle_emit_later(random_range(_x1, _x2), random_range(_y1, _y2), "rise", choose(make_color_rgb(255, 170, 60), make_color_rgb(255, 110, 30), make_color_rgb(255, 220, 120)), 1);
		if (random(1) < 0.12) particle_emit_later(random_range(_x1, _x2), random_range(_y1, _y2), "rise", make_color_rgb(70, 64, 58), 1);
	}
}

/// @func draw_item_card(_it, _cx, _cy, _w, _h, _alpha, _hover, _locked)
/// @desc An item (potion, core, coins) as a reward card, the same design as the dice reward cards (Jared, 2026-11-21):
///       paper starting under the icon, which sits on its top edge; the rarity gem; the name; what it does, centred; a
///       core's distribution across the full width; how many, if more than one. Locked (the map-lock pick): darkened,
///       with chains. Lifts with a brass edge when hovered.
function draw_item_card(_it, _cx, _cy, _w, _h, _alpha, _hover, _locked) {
	var _lay = item_card_layout(_it, _w);
	var _x1 = _cx - _w / 2, _y1 = _cy - _h / 2 - (_hover ? 5 : 0);
	var _x2 = _x1 + _w, _y2 = _y1 + _h;
	var _pt = _y1 + _lay.icon_y;
	if (_hover) {
		draw_set_alpha(_alpha);
		draw_set_color(global.ui_col.brass);
		draw_roundrect_ext(_x1 - 6, _pt - 6, _x2 + 6, _y2 + 6, 14, 14, false);
		draw_set_alpha(1);
	}
	ui_paper(_x1, _pt, _x2, _y2, round(_cx) * 7 + 3, global.ui_col.paper, _alpha);
	if (!variable_struct_exists(_it, "rarity") || _it.rarity != "none") draw_rarity_gem(_x2 - 20, _pt + 20, variable_struct_exists(_it, "rarity") ? _it.rarity : "common", 1, _alpha); // keepsakes have none

	// the icon on the paper's edge, on a paper disc so it reads half on the card and half off
	draw_set_alpha(_alpha);
	draw_set_color(global.ui_col.ink);
	draw_circle(_cx, _pt, 41, false);
	draw_set_color(global.ui_col.paper_hi);
	draw_circle(_cx, _pt, 38, false);
	var _sc = 62 / max(1, max(sprite_get_width(_it.sprite), sprite_get_height(_it.sprite)));
	draw_sprite_ext(_it.sprite, _it.index, _cx, _pt, _sc, _sc, 0, c_white, _alpha);
	if (variable_struct_exists(_it, "amount") && _it.amount > 1) {
		draw_set_font(ftBig);
		draw_set_halign(fa_center);
		draw_set_valign(fa_middle);
		draw_outline_text("x" + string(_it.amount), global.ui_col.paper_hi, global.ui_col.ink, 2, _cx + 46, _pt + 18, 1, _alpha, 0);
	}

	// its name, then what it does, centred
	draw_set_alpha(_alpha);
	draw_set_font(ftBig);
	draw_set_halign(fa_center);
	draw_set_valign(fa_top);
	draw_set_color(global.ui_col.ink);
	draw_text_ext(_cx, _y1 + _lay.name_y, _it.name, -1, _w - 28);
	draw_set_font(ftDefault);
	ui_paper_text(colorcode_text(string(_it.description)), _cx, _y1 + _lay.desc_y, _w - 32, _alpha);
	draw_set_halign(fa_left);

	// a core: how it shapes a die's faces
	if (variable_struct_exists(_it, "type") && _it.type == "core" && variable_struct_exists(_it, "distribution")) {
		var _pd = core_preview_die();
		_pd.distribution = _it.distribution;
		draw_set_alpha(_alpha);
		draw_dice_distribution(_pd, _cx, _y2 - 12, true, 1, true, _w - 28);
	}

	// locked away by the first pick: darkened, chained
	if (_locked) {
		draw_set_alpha(0.55 * _alpha);
		draw_set_color(global.ui_col.slate);
		draw_rectangle(_x1, _pt, _x2, _y2, false);
		draw_set_alpha(1);
		draw_sprite_ext(sRewardChain, 0, _cx, (_pt + _y2) / 2, 1.1, 1.1, 0, c_white, _alpha);
	}
	draw_set_alpha(1);
	draw_set_color(c_white);
}
