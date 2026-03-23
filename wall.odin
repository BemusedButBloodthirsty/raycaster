package wolf3d

import sdl "vendor:sdl2"
import "core:fmt"
import "core:log"

render_wall_projection :: proc() {
	for c: int; c < NUM_RAYS; c += 1 {
		current_ray: Ray = rays[c]

		// log.error(current_ray)

		wall_strip_height: int = cast(int) current_ray.ray_wall_height

		r_wall_top: int = (WINDOW_HEIGHT / 2) - (wall_strip_height / 2)
		r_wall_top = clamp(r_wall_top, 0, WINDOW_HEIGHT-1)
		r_wall_bot: int = (WINDOW_HEIGHT / 2) + (wall_strip_height / 2)
		r_wall_bot = clamp(r_wall_bot, 0, WINDOW_HEIGHT-1)

		roof_color  := sdl.Color{r=30,  g=30,  b=50,  a=255}
		floor_color := sdl.Color{r=90,  g=70,  b=50,  a=255}

		// Draw the roof strip:
		// roof_color := sdl.Color {
		// 	r=50,
		// 	g=50,
		// 	b=50,
		// 	a=255,//current_ray.wall_color.a,
		// }
		for r in 0..<r_wall_top {
            draw_pixel(c, r, color_to_argb8888(roof_color)) // color_buffer[(WINDOW_WIDTH*r) + c] = color_to_argb8888(roof_color)
		}

		// Draw the wall strip:
		for r in r_wall_top..=r_wall_bot {
			distance_from_top: int = r + (wall_strip_height / 2) - (WINDOW_HEIGHT / 2)
			texture_offset_y: int = int(f32(distance_from_top) / f32(wall_strip_height) * (TEXTURE_HEIGHT-1)) // NOTE(bemused): This must be a value between 0 and 63.
            // texture_offset_y = clamp(texture_offset_y, 0, TEXTURE_HEIGHT - 1)

			wall_texture: []u32

			switch current_ray.colliding_tile_kind {
			case .Empty: 		wall_texture = textures[.Empty]
			case .Bluestone: 	wall_texture = textures[.Bluestone]
			case .Colorstone: 	wall_texture = textures[.Colorstone]
			case .Eagle: 		wall_texture = textures[.Eagle]
			case .Graystone: 	wall_texture = textures[.Graystone]
			case .Mossystone: 	wall_texture = textures[.Mossystone]
			case .Purplestone: 	wall_texture = textures[.Purplestone]
			case .Redbrick: 	wall_texture = textures[.Redbrick]
			case .Wood: 		wall_texture = textures[.Wood]
			case .Pikuma:       wall_texture = textures[.Pikuma]
			}

			// fmt.println("wall", len(wall_texture))

            texel_color := wall_texture[TEXTURE_WIDTH*texture_offset_y + current_ray.texture_offset_x]

            // Depending on whether the ray hit a vertical or horizontal wall, we darken the color a bit for vertical walls.
            if current_ray.governing_direction == .Vertical {
                // Darken the color a bit
				change_color_intensity(&texel_color)
            } else if current_ray.governing_direction == .Horizontal{
				// Leave the color as is, so do nothing. Here for readability. 
			} 
            
            change_pixel_alpha_value(&texel_color, current_ray.ray_length_fishbowl_correction)

            draw_pixel(c, r, texel_color)
		}

		// Draw the floor strip:
		// floor_color := sdl.Color {
		// 	r=125,
		// 	g=125,
		// 	b=125,
		// 	a=255,//current_ray.wall_color.a,
		// }
		for r in r_wall_bot+1..=WINDOW_HEIGHT-1 {
			draw_pixel(c, r, color_to_argb8888(floor_color))
		}
	}
}