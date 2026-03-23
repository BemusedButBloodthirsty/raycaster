package wolf3d

import sdl "vendor:sdl2"
import "core:fmt"
import "core:math"
import "core:c"

WINDOW_WIDTH :: 640 * 2
WINDOW_HEIGHT :: 360 * 2
FPS :: 60
FRAME_TIME_MILLISECONDS :: 1000 / FPS
FOV_ANGLE := deg2rad(60)
DIST_TO_PROJECTION_PLANE: f32 = (WINDOW_WIDTH/2) / math.tan_f32(FOV_ANGLE/2)

@(private="file") renderer: ^sdl.Renderer
@(private="file") window: ^sdl.Window
@(private="file") color_buffer: []u32
@(private="file") color_buffer_texture: ^sdl.Texture

@(cold)
initialize_window :: proc() -> bool {
	if sdl.Init(sdl.INIT_EVERYTHING) != 0 {
		fmt.eprintln("Error: Could not init.")
		return false
	}

    display_mode: sdl.DisplayMode

    sdl.GetCurrentDisplayMode(0, &display_mode)

    fullscreen_width := display_mode.w
    fullscreen_height := display_mode.h

	window = sdl.CreateWindow(
		title="wolf3d_odin",
		x=sdl.WINDOWPOS_CENTERED,
		y=sdl.WINDOWPOS_CENTERED,
		w=fullscreen_width / 2,
		h=fullscreen_height / 2,
		flags=sdl.WINDOW_RESIZABLE, // | sdl.WINDOW_ALWAYS_ON_TOP,
	)

	if window == nil {
		fmt.eprintln("Error: Could not create window.")
		return false
	}

	renderer = sdl.CreateRenderer(
		window=window,
		index=-1, // Get the default driver.
		flags=sdl.RENDERER_SOFTWARE,
	)

	if renderer == nil {
		fmt.eprintln("Error: Could not create renderer.")
		return false
	}

	sdl.SetRenderDrawBlendMode(
		renderer=renderer,
		blendMode=.NONE,
	)

    color_buffer = make([]u32, WINDOW_HEIGHT*WINDOW_WIDTH, context.allocator)
	color_buffer_texture = sdl.CreateTexture(
		renderer=renderer,
		format=.ARGB8888,
		access=.STREAMING, // Allows changing the texture in real-time.
		w=WINDOW_WIDTH,
		h=WINDOW_HEIGHT,
	)
	sdl.SetTextureBlendMode(color_buffer_texture, .BLEND)


	return true
}

@(cold)
destroy_window :: proc () {
	// Technically not necessary - can cause the app to close even slower.
	free(&color_buffer)
	free(&procedurally_generated_wall_texture)

	sdl.DestroyTexture(color_buffer_texture)

	sdl.DestroyRenderer(renderer)
	sdl.DestroyWindow(window)
	sdl.Quit()
}

clear_color_buffer :: proc(color: u32 = 0xFF1A1A1A) {
    // for &pixel in color_buffer {
    //     pixel = color
    // }
    sdl.SetRenderDrawColor(renderer, 0, 0, 0, 255)
    sdl.RenderClear(renderer)
}

render_color_buffer :: proc() {
	sdl.UpdateTexture(
		texture=color_buffer_texture,
		rect=nil,
		pixels=raw_data(color_buffer),
		pitch=WINDOW_WIDTH*size_of(u32), // number of bytes in a row (including the padding) of pixel data. This might be the same as `stride` possibly?
	)
	sdl.RenderCopy(
		renderer=renderer,
		texture=color_buffer_texture,
		srcrect=nil,
		dstrect=nil, // Entire texture to entire destination.
	)

    sdl.RenderPresent(renderer)
}

draw_pixel :: proc(x, y: int, color: u32) {
    color_buffer[WINDOW_WIDTH*y + x] = color
}

create_line :: proc(x1, y1, x2, y2: f32) -> c.int {
	return sdl.RenderDrawLine(
		renderer=renderer,
		x1=i32(math.floor(x1)),
		y1=i32(math.floor(y1)),
		x2=i32(math.floor(x2)),
		y2=i32(math.floor(y2)),
	)
}

draw_rect :: proc(x, y: int, width, height: int, color: u32) {
    /*
        r == y
        c == x
    */
    for r in y..<(y + height) {
        for c in x..<(x + width) {
            draw_pixel(c, r, color)
        }
    }
}

create_rect :: proc(x, y, w, h: f32) -> sdl.Rect {
	return sdl.Rect {
		x=cast(i32) math.round(x),
		y=cast(i32) math.round(y),
		w=cast(i32) math.round(w),
		h=cast(i32) math.round(h),
	}
}

color_to_argb8888 :: proc(c: sdl.Color) -> u32 {
	return u32(c.a) << 24 | u32(c.r) << 16 | u32(c.g) << 8 | u32(c.b)
}

draw_line :: proc(x1, y1, x2, y2: int, color: u32) {

    delta_x: int = x2 - x1
    delta_y: int = y2 - y1

    side_length: int = abs(delta_x) >= abs(delta_y) ? abs(delta_x) : abs(delta_y)

    x_inc: f32 = f32(delta_x) / f32(side_length)
    y_inc: f32 = f32(delta_y) / f32(side_length)

    current_x: f32 = f32(x1)
    current_y: f32 = f32(y1)

    for i in 0..=side_length {
        draw_pixel(
            x=int(math.round(current_x)),
            y=int(math.round(current_y)),
            color=color,
        )

        current_x += x_inc
        current_y += y_inc
    }
}