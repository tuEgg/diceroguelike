// Script assets have changed for v2.3.0 see
// https://help.yoyogames.com/hc/en-us/articles/360005277377 for more information
function define_keepsakes() {
	var ks_lucky_coin = {
	    _id: "lucky_coin",
	    name: "Lucky Coin",
	    desc: "Your dice can never roll a 1.",
		sub_image: 0,
	    trigger: function(event, data) {
	        if (event == "on_roll_die") {
	            if (data.min_roll == 1) data.min_roll = 2;
	        }
	    }
	};
	ds_list_add(oRunManager.keepsakes_master, ks_lucky_coin);
	
	var ks_message_in_a_bottle = {
	    _id: "message_in_a_bottle",
	    name: "Message in a Bottle",
	    desc: "Discover a random dice at the start of combat.",
	    sub_image: 1,

	    trigger: function(event, data) {
	        // IMPORTANT: `self` here is the keepsake struct itself — no need for `var that`
	        switch (event) {

	            case "on_turn_start":
				break;
	        }
	    }
	};
	ds_list_add(oRunManager.keepsakes_master, ks_message_in_a_bottle);
	
	var ks_eye_patch = {
	    _id: "eye_patch",
	    name: "Eye patch",
	    desc: "Not yet defined.",
	    sub_image: 2,

	    trigger: function(event, data) {
	        // IMPORTANT: `self` here is the keepsake struct itself — no need for `var that`
	        switch (event) {

	            case "on_turn_start":
				break;
	        }
	    }
	};
	ds_list_add(oRunManager.keepsakes_master, ks_eye_patch);
	
	var ks_anchor = {
	    _id: "anchor",
	    name: "Anchor",
	    desc: "Not yet defined.",
	    sub_image: 3,

	    trigger: function(event, data) {
	        // IMPORTANT: `self` here is the keepsake struct itself — no need for `var that`
	        switch (event) {

	            case "on_turn_start":
				break;
	        }
	    }
	};
	ds_list_add(oRunManager.keepsakes_master, ks_anchor);
	
	var ks_ghost_lantern = {
	    _id: "ghost_lantern",
	    name: "Ghost Lantern",
	    desc: "Not yet defined.",
	    sub_image: 4,

	    trigger: function(event, data) {
	        // IMPORTANT: `self` here is the keepsake struct itself — no need for `var that`
	        switch (event) {

	            case "on_turn_start":
				break;
	        }
	    }
	};
	ds_list_add(oRunManager.keepsakes_master, ks_ghost_lantern);
	
	//var ks_message_in_a_bottle = {
	//    _id: "message_in_a_bottle",
	//    name: "Message in a Bottle",
	//    desc: "Discover a random dice at the start of combat.",
	//    sub_image: 1,
	//    state: { last_type: "", streak: 0, buff_ready: false },

	//    trigger: function(event, data) {
	//        // IMPORTANT: `self` here is the keepsake struct itself — no need for `var that`
	//        switch (event) {

	//            case "on_action_used":
	//                if (is_undefined(data) || !variable_struct_exists(data, "action_type")) {
	//                    show_debug_message("⚠️ Invalid data passed to keepsake trigger: " + string(data));
	//                    break;
	//                }

	//                var t = data.action_type;
	//                if (t == self.state.last_type) {
	//                    self.state.streak++;
	//                    show_debug_message("Cutlass streak: " + string(self.state.streak));
	//                } else {
	//                    self.state.streak = 1;
	//                    self.state.last_type = t;
	//                }

	//                if (self.state.streak >= 3) {
	//                    self.state.streak = 0;
	//                    self.state.last_type = "";
	//                    self.state.buff_ready = true;
	//                    show_debug_message("Cutlass buff ready!");
	//                }
	//            break;

	//            case "on_roll_die":
	//                if (self.state.buff_ready && data.action_type == "ATK") {
	//                    show_debug_message("Cutlass buff triggered! +4 damage");
	//                    data._d_amount += 4;
	//                    self.state.buff_ready = false;
	//                }
	//            break;
				
	//			case "on_turn_end":
	//				self.state.streak = 0;
	//			break;
	//        }
	//    }
	//};
	//ds_list_add(oRunManager.keepsakes_master, ks_blooded_cutlass);
}

function get_keepsake_by_id(_id) {
	for (var k = 0; k < ds_list_size(keepsakes_master); k++) {
		if (keepsakes_master[| k]._id == _id) {
			return keepsakes_master[| k];
		}
	}
}