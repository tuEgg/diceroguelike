image_xscale *= 0.95;
image_yscale *= 0.95;

life++;

if (life > 5) image_alpha *= 0.86;

if (image_alpha <= 0.01) instance_destroy();