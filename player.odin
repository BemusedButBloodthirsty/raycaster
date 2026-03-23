package wolf3d

import "core:math"

PLAYER_VIEW_LINE_LENGTH :: 50

player: Player // Since this is a struct, we would need to make so many `getters` and `setters` just to manipulate the data. Rather leave as public instead.

Player :: struct {
	x, y: f32,
	w, h: f32,
	centre_x, centre_y: f32,
	turn_direction: int, // -1 for left, +1 right, 0 stopped.
	walk_direction: int, // -1 for backwards, +1 for forward, 0 stopped.
	rotation_angle: f32,
	walk_speed: f32, // Pixels per second
	turn_speed: f32, // Radians per second
}

move_and_turn_player :: proc(dt: f32) {
	player.rotation_angle += f32(player.turn_direction) * player.turn_speed * dt
	player.rotation_angle = normalise_angle(player.rotation_angle)

	traversal_distance: f32 = player.walk_speed * dt * f32(player.walk_direction)

	// Find the current grid cell coordinates of the next frame:
	grid_r := int(math.floor(((player.centre_y) + traversal_distance * math.sin(player.rotation_angle)) / TILE_SIZE))
	grid_c := int(math.floor(((player.centre_x) + traversal_distance * math.cos(player.rotation_angle)) / TILE_SIZE))

	// Check the next frame if the player will end up in the 0 cell.
	if get_map_at(grid_r,grid_c) == 0 {
		// The player can move. Increment the x and y.
		player.x += traversal_distance * math.cos(player.rotation_angle)
		player.y += traversal_distance * math.sin(player.rotation_angle)
		update_centre_coords()
	}
}

update_centre_coords :: proc() {
	player.centre_x = player.x + player.w/2
	player.centre_y = player.y + player.h/2
}

render_minimap_player :: proc() {

	draw_rect(
		x=int(math.round(player.x * MINIMAP_SCALE_FACTOR)),
		y=int(math.round(player.y * MINIMAP_SCALE_FACTOR)),
		width=int(math.round(player.w * MINIMAP_SCALE_FACTOR)),
		height=int(math.round(player.h * MINIMAP_SCALE_FACTOR)),
		color=color_to_argb8888({
			r=255,
			g=255,
			b=0,
			a=255,
		})
	)

	draw_line(
		x1=int(math.round((player.centre_x) * MINIMAP_SCALE_FACTOR)),
		y1=int(math.round((player.centre_y) * MINIMAP_SCALE_FACTOR)),
		x2=int(math.round(((player.centre_x) + PLAYER_VIEW_LINE_LENGTH * math.cos(player.rotation_angle)) * MINIMAP_SCALE_FACTOR)),
		y2=int(math.round(((player.centre_y) + PLAYER_VIEW_LINE_LENGTH * math.sin(player.rotation_angle)) * MINIMAP_SCALE_FACTOR)),
		color=color_to_argb8888({
			r=255,
			g=255,
			b=0,
			a=255,
		})
	)
}