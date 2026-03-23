package wolf3d

import "core:fmt"
import "core:log"
import "core:math"
import sdl "vendor:sdl2"

NUM_RAYS :: WINDOW_WIDTH

rays: [NUM_RAYS]Ray // Since this is a struct, we would need to make so many `getters` and `setters` just to manipulate the data. Rather leave as public instead.

Ray :: struct {
	ray_angle:						f32,
	ray_length:						f32, // Need this for minimap
	ray_length_fishbowl_correction:	f32, // Need this for "3d" projection
	colliding_tile_kind:			Tile_Kind, // Depending on the data of the colliding cell, store the kind of tile
	wall_color:						sdl.Color,
	ray_wall_height:				f32,
	texture_offset_x:				int,
    governing_direction:            Intersection_Kind,
}

is_pointing_up :: proc(ray_angle_n: f32) -> bool {
	return ray_angle_n < 0
}

is_pointing_left :: proc(ray_angle_n: f32) -> bool {
	return abs(ray_angle_n) >= (PI / 2)
}

easing_out_quad :: proc(x: f32) -> f32 {
	return 1 - (1 - x) * (1 - x)
}

perform_raycast :: proc(r: ^Ray, current_ray_angle: f32) {
	
    r.ray_angle = normalise_angle(current_ray_angle)

	// Find the current grid cell coordinates of the player:
	player_current_grid_c: f32 = math.floor(player.centre_x / TILE_SIZE)
	player_current_grid_r: f32 = math.floor(player.centre_y / TILE_SIZE)

	// Based on the player angle, will determine which intersection line is the starting point.
	// But first normailise the angle so that we have something between +180 and -180 degrees.
	// Then we find point O which is the top left corner's coords.
	point_O_x: f32 = player_current_grid_c * TILE_SIZE
	point_O_y: f32 = player_current_grid_r * TILE_SIZE 

	current_cell_delta_x: f32 = player.centre_x - point_O_x
	current_cell_delta_y: f32 = player.centre_y - point_O_y

	/*
		Note(bemused):
		Check horizontal grid lines.
	*/
	first_horizontal_intersection_x: f32
	first_horizontal_intersection_y: f32

	if (is_pointing_up(r.ray_angle)) {
		first_horizontal_intersection_y = point_O_y
		first_horizontal_intersection_x = player.centre_x - current_cell_delta_y / math.tan(r.ray_angle)
	} else {
		// The vector is pointing down:
		first_horizontal_intersection_y = point_O_y + TILE_SIZE
		first_horizontal_intersection_x = player.centre_x + (TILE_SIZE - current_cell_delta_y) / math.tan(r.ray_angle)
	}

	// Now that we have the starting point of the first horizontal intersection we check and iterate until we hit a wall by adding a very small length to the ray's length.
	intersection_horizontal_row, intersection_horizontal_col := intersection_coords(
		x=first_horizontal_intersection_x,
		y=first_horizontal_intersection_y,
		ray_angle_n=r.ray_angle,
		intersection_kind=.Horizontal,
	)

	for !found_intersection(intersection_horizontal_row, intersection_horizontal_col) {

		if (is_pointing_up(r.ray_angle)) {
			first_horizontal_intersection_x -= TILE_SIZE / math.tan(r.ray_angle)
			first_horizontal_intersection_y -= TILE_SIZE
		} else {
			first_horizontal_intersection_x += TILE_SIZE / math.tan(r.ray_angle)
			first_horizontal_intersection_y += TILE_SIZE
		}

		intersection_horizontal_row, intersection_horizontal_col = intersection_coords(
			x=first_horizontal_intersection_x,
			y=first_horizontal_intersection_y,
			ray_angle_n=r.ray_angle,
			intersection_kind=.Horizontal,
		)
	}

    distance_to_final_horizontal_intersection := distance_between(
        player.centre_x, player.centre_y, 
        first_horizontal_intersection_x, first_horizontal_intersection_y,
    )

	/*
		Note(bemused):
		Check verticals.
	*/
	// Here we just need to check left and right sides.
	first_vertical_intersection_x: f32
	first_vertical_intersection_y: f32

	if (is_pointing_left(r.ray_angle)) {
		// The vector is pointing left:
		first_vertical_intersection_x = point_O_x
		first_vertical_intersection_y = player.centre_y - (current_cell_delta_x) * math.tan(r.ray_angle)
	} else {
		// The vector is pointing right:
		first_vertical_intersection_x = point_O_x + TILE_SIZE
		first_vertical_intersection_y = player.centre_y + (TILE_SIZE - current_cell_delta_x) * math.tan(r.ray_angle)
	}

	// Now that we have the starting point of the first vertical intersection we check and iterate until we hit a wall by adding a very small length to the ray's length.
	intersection_vertical_row, intersection_vertical_col := intersection_coords(
		first_vertical_intersection_x,
		first_vertical_intersection_y,
		r.ray_angle,
		.Vertical,
	)

	for !found_intersection(intersection_vertical_row, intersection_vertical_col) {

		if (is_pointing_left(r.ray_angle)) {
			first_vertical_intersection_x -= TILE_SIZE
			first_vertical_intersection_y -= TILE_SIZE * math.tan(r.ray_angle)
		} else {
			first_vertical_intersection_x += TILE_SIZE
			first_vertical_intersection_y += TILE_SIZE * math.tan(r.ray_angle)
		}

		intersection_vertical_row, intersection_vertical_col = intersection_coords(
			first_vertical_intersection_x,
			first_vertical_intersection_y,
			r.ray_angle,
			.Vertical,
		)
	}

    distance_to_final_vertical_intersection := distance_between(
        player.centre_x, player.centre_y,
        first_vertical_intersection_x, first_vertical_intersection_y,
    )
    
    dominant_tile_kind: Tile_Kind

	if distance_to_final_horizontal_intersection <= distance_to_final_vertical_intersection {
		// Horizontal is shortest, so horizontal governs
		r.ray_length = distance_to_final_horizontal_intersection
		dominant_tile_kind = cast(Tile_Kind) get_map_at(intersection_horizontal_row, intersection_horizontal_col)
		r.texture_offset_x = int(first_horizontal_intersection_x) % TEXTURE_WIDTH

        r.governing_direction = .Horizontal
	} else {
		// Vertical governs
		r.ray_length = distance_to_final_vertical_intersection
		dominant_tile_kind = cast(Tile_Kind) get_map_at(intersection_vertical_row,intersection_vertical_col)
		r.texture_offset_x = int(first_vertical_intersection_y) % TEXTURE_WIDTH

        r.governing_direction = .Vertical
	}

	r.colliding_tile_kind = dominant_tile_kind

	// Fishbowl correction:
	theta := r.ray_angle - player.rotation_angle
	r.ray_length_fishbowl_correction = r.ray_length * math.cos(theta)

	// TODO(bemused): BUG!
	r.ray_wall_height = (DIST_TO_PROJECTION_PLANE / r.ray_length_fishbowl_correction) * WALL_HEIGHT

    color_black  := sdl.Color{   0,   0,   0, 255}
    color_red    := sdl.Color{ 255,   0,   0, 255}
    color_green  := sdl.Color{   0, 255,   0, 255}
	color_blue   := sdl.Color{   0,   0, 255, 255}
	color_orange := sdl.Color{ 255, 128,   0, 255}
	color_brown  := sdl.Color{ 139,  69,  19, 255}
	color_pink   := sdl.Color{ 255,  20, 147, 255}
	color_purple := sdl.Color{ 128,   0, 128, 255}
	color_white  := sdl.Color{ 255, 255, 255, 255}
	color_cyan   := sdl.Color{   0, 255, 255, 255}
    
	switch cast(Tile_Color) r.colliding_tile_kind {
	case .Black: 	r.wall_color = color_black
	case .Red: 		r.wall_color = color_red
	case .Green: 	r.wall_color = color_green
	case .Blue:		r.wall_color = color_blue
	case .Orange:	r.wall_color = color_orange
	case .Brown:    r.wall_color = color_brown
	case .Pink:     r.wall_color = color_pink
	case .Purple:   r.wall_color = color_purple
	case .White:    r.wall_color = color_white
	case .Cyan:     r.wall_color = color_cyan
	}

	change_pixel_alpha_value(&r.wall_color, r.ray_length_fishbowl_correction)

}

found_intersection :: proc(row, col: int) -> bool {
	return get_map_at(row,col) != 0
}

intersection_coords :: proc(x, y, ray_angle_n: f32, intersection_kind: Intersection_Kind) -> (row, col: int) {
	// We'll use a single pixel for now.
	search_pixels: int = 1

	switch intersection_kind {
	case .Horizontal:
		// We increment/decrement y
		col = int(math.floor((x) / TILE_SIZE))
		if is_pointing_up(ray_angle_n) {
			row = int(math.floor((y - f32(search_pixels)) / TILE_SIZE))
		} else {
			row = int(math.floor((y + f32(search_pixels)) / TILE_SIZE))
		}

	case .Vertical:
		// We increment/decrement x
		row = int(math.floor((y) / TILE_SIZE))
		if is_pointing_left(ray_angle_n) {
			col = int(math.floor((x - f32(search_pixels)) / TILE_SIZE))
		} else {
			col = int(math.floor((x + f32(search_pixels)) / TILE_SIZE))
		}
	}

	// Making sure that we don't exceed the boundaries:
	row = min(MAP_NUM_ROWS - 1, row)
	row = max(0, row)

	col = min(MAP_NUM_COLS - 1, col)
	col = max(0, col)

	return
}

cast_all_rays :: proc() {

	ray_angle_step := FOV_ANGLE / f32(NUM_RAYS - 1)
	current_ray_angle := player.rotation_angle - (FOV_ANGLE / 2) // Starting point for our rays.

	for &ray, index in rays {
		// Assign all data to the current ray:
		perform_raycast(&ray, current_ray_angle) // Note(bemused): Normalisation happens inside the proc.

		// Prepare for next ray:
		// current_ray_angle = player.rotation_angle + normalise_angle(math.atan((f32(index) - NUM_RAYS/2) / DIST_TO_PROJECTION_PLANE))
		current_ray_angle += ray_angle_step
	}
}

render_minimap_rays :: proc() {

    for ray in rays {

        // We can also change the color intensity for the rays in the minimap: 
        ray_minimap_color: u32 = color_to_argb8888({
                r=ray.wall_color.r,
                g=ray.wall_color.g,
                b=ray.wall_color.b,
                a=ray.wall_color.a,
        })
        
        if ray.governing_direction == .Vertical {
            change_color_intensity(&ray_minimap_color)
        } else if ray.governing_direction == .Horizontal {
            // We do nothing to the color value. Here for readablity. 
        }

        draw_line(
            x1=int(math.round((player.centre_x) * MINIMAP_SCALE_FACTOR)),
            y1=int(math.round((player.centre_y) * MINIMAP_SCALE_FACTOR)),
            x2=int(math.round(((player.centre_x) + ray.ray_length * math.cos(ray.ray_angle)) * MINIMAP_SCALE_FACTOR)),
            y2=int(math.round(((player.centre_y) + ray.ray_length * math.sin(ray.ray_angle)) * MINIMAP_SCALE_FACTOR)),
            color=ray_minimap_color,
        )
    }
}