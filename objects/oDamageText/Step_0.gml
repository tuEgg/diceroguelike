/// oDamageText Step

age += 1;
y -= rise_speed;

// Scale up fast at start, then shrink slightly
if (age < game_get_speed(gamespeed_fps) * 0.1) {
    scale = lerp(scale, 1.5, 0.3);
} else {
    scale = lerp(scale, 1, 0.05);
}

// Fade out toward end
if (age > lifespan * 0.6) {
    alpha = lerp(alpha, 0, 0.05);
}

// Destroy when finished
if (age >= lifespan) instance_destroy();

// larger hits = bigger numbers
size = amount/15 + 0.5;