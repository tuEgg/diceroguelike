/// oDamageText Draw GUI
var font_to_use = ftDamage; // optional big bold font
draw_set_font(font_to_use);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);

var _sign = "";

switch(num_sign) {
	case -1: _sign = "-" break
	case 1: _sign = "+" break;
}

var str = _sign + string(amount);

draw_outline_text(str, c_black, color_main, 2, x, y, scale * size, alpha, 0);