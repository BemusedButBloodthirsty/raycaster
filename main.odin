package wolf3d

import "core:log"
import "core:c"
import "core:math"
import sdl "vendor:sdl2"
import "core:fmt"

PI :: math.PI
TAU :: math.TAU

@(private="file") game_is_running: bool = false
@(private="file") ticks_since_last_frame: u32
@(private="file") elapsed_program_ticks: u32

distance_between :: proc(x1, y1, x2, y2: f32) -> f32 {
    return math.sqrt(
        (y2 - y1)*(y2 - y1) + 
        (x2 - x1)*(x2 - x1)
    )
}

normalise_angle :: proc(theta: f32) -> f32 {
	k := math.floor((PI - theta) / (2*PI))
	return theta + 2*k*PI
}

deg2rad :: proc "contextless" (degrees: f32) -> f32 {
	return degrees * (PI / 180)
}

@(cold)
setup :: proc() {
	player.x = MAP_NUM_COLS * TILE_SIZE / 2
	player.y = MAP_NUM_ROWS * TILE_SIZE / 2
	player.w = 10
	player.h = 10
	update_centre_coords()
	player.rotation_angle = - PI / 2
	player.walk_speed = 200 // Pixels per second.
	player.turn_speed = deg2rad(90) // Degrees per second.

	// NOTE(bemused): Procedurally create a texture with a pattern of blue and black lines
	procedurally_generated_wall_texture = make([]u32, TEXTURE_WIDTH*TEXTURE_HEIGHT, context.allocator)
	for x: int = 0; x < TEXTURE_WIDTH; x += 1 {
		for y: int = 0; y < TEXTURE_HEIGHT; y += 1 {
			procedurally_generated_wall_texture[TEXTURE_WIDTH*y + x] = (x % 8 == 0) || (y % 8 == 0) ? 0xFF000000 : 0xFF0000FF
		}
	}

    initialise_textures_array()
    initialise_sprites()
}

process_input :: proc() {
	event: sdl.Event

	sdl.PollEvent(&event)

	#partial switch event.type {
	case .QUIT:	game_is_running = false
	case .KEYDOWN:
		#partial switch event.key.keysym.sym {
		case .ESCAPE: 	game_is_running = false
		case .UP:		player.walk_direction = +1
		case .DOWN: 	player.walk_direction = -1
		case .LEFT: 	player.turn_direction = -1
		case .RIGHT: 	player.turn_direction = +1
		}
	case .KEYUP:
		// player.walk_direction = 0
		// player.turn_direction = 0

        #partial switch event.key.keysym.sym {
        case .UP:		player.walk_direction = 0
        case .DOWN: 	player.walk_direction = 0
        case .LEFT: 	player.turn_direction = 0
        case .RIGHT: 	player.turn_direction = 0
        }
	}
}

update :: proc() {

	time_to_wait := u32(FRAME_TIME_MILLISECONDS) - (sdl.GetTicks() - ticks_since_last_frame)
	if time_to_wait > 0 && time_to_wait <= u32(FRAME_TIME_MILLISECONDS) {
		sdl.Delay(time_to_wait)
	}

	elapsed_program_ticks = sdl.GetTicks()
	delta_time: f32 = f32(elapsed_program_ticks - ticks_since_last_frame) / 1000
	ticks_since_last_frame = elapsed_program_ticks

	player.rotation_angle = normalise_angle(player.rotation_angle) // log.info(player.rotation_angle)
	move_and_turn_player(delta_time)
	cast_all_rays()

	check_if_sprites_in_fov()
	sort_sprites_bubble()
}

render :: proc() {
	clear_color_buffer()

	render_wall_projection()

    draw_sprites()

	render_minimap()

	render_color_buffer()
}


main :: proc() {
	console_logger := log.create_console_logger()
	context.logger = console_logger

	// fmt.println(DIST_TO_PROJECTION_PLANE)

	game_is_running = initialize_window()
	// defer destroy_window()

	setup()
	debug()

	for game_is_running {
		process_input()
		update()
		render()
	}
}

debug :: proc() {
	// log.info(...)
}