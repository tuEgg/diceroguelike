if (cutscene_state != CUTSCENE_STATE.FINISHED) exit;

// run all trigger checks
for (var i = 0; i < array_length(cutscenes); i++) {
	var cutscene = cutscenes[i];
	
	var _seen = cutscene.seen ? "Yes" : "No";
	show_debug_message("Cutscene seen? " + _seen);
	
	if (cutscene.seen) continue;
	
	var conditions_met = true; // set this to true - the cutscene will only run if none of the triggers set it to false
	
	// loop through all trigger conditions
	for (var t = 0; t < array_length(cutscene.triggers); t++) {
	    var _trigger = cutscene.triggers[t];
	    var _name = _trigger.variable;
	    var _expected = _trigger.value;
    
	    var _actual;
	    if (_name == "room") {
		    _actual = room;
		} else if (string_starts_with(_name, "global.")) {
	        var _global_name = string_delete(_name, 1, 7); // strip "global."
	        _actual = variable_global_get(_global_name);
	    } else {
	        _actual = variable_instance_get(id, _name);
	    }
    
	    if (_actual != _expected) {
	        conditions_met = false;
	        break;
	    }
	}
	
	if (conditions_met) {
		show_debug_message("Playing cutscene " + string(i));
		cutscenes[i].seen = true;
		cutscene_index = i;
		cutscene_state = CUTSCENE_STATE.STARTED;
	}
}