image_xscale *= 0.97;
image_yscale *= 0.97;

life++;

if (life > 5) image_alpha *= 0.86;

if (image_alpha <= 0.01) instance_destroy();