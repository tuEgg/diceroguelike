// oDice.Begin Step
if (target_x != undefined && target_y != undefined && speed == 0 && !still) {
    direction = point_direction(x, y, target_x, target_y);
    speed = max(30, (distance_to_point(target_x, target_y) / 40));
}