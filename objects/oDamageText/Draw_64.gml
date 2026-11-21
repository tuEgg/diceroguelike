/// oDamageText Draw GUI
// during a run these are drawn by oRunManager Draw GUI End, after the bag and its picker, so they show over them (B140)
if (instance_exists(oRunManager) && !(variable_global_exists("damage_text_late") && global.damage_text_late)) exit;
var font_to_use = ftDamage; // optional big bold font
draw_set_font(font_to_use);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);

var _sign = "";

switch(num_sign) {
	case -1: _sign = "-" break;
	case 0: _sign = "" break;
	case 1: _sign = "+" break;
}

var str = _sign + string(amount);

if (txt != -1) {
	str = txt;
}

draw_outline_text(str, c_black, color_main, 2, x, y, scale * size, alpha, 0);