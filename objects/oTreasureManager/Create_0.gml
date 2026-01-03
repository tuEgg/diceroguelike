exit_scale = 1.0;

chest_open = false;
chest_scale = 1.0;
keepsake_y = 100;
keepsake_alpha = 0;

keepsake_reward = ds_list_create();
generate_keepsake_rewards(keepsake_reward, global.rollable_keepsake_list, 1);