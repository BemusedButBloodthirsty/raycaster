package wolf3d

import "core:image"
import "core:image/png"
import "core:slice"
import "core:log"
import "core:math"
import sdl "vendor:sdl2"

TEXTURE_WIDTH  :: 64
TEXTURE_HEIGHT :: 64

procedurally_generated_wall_texture: []u32
textures: [Tile_Kind][]u32

/*
convert_rgba_to_argb :: proc(rgba_data: []u32) -> []u32 {
	result := make([]u32, len(rgba_data))
	for i in 0..<len(rgba_data) {
		pixel := rgba_data[i]
		r := (pixel >>  0) & 0xFF
		g := (pixel >>  8) & 0xFF
		b := (pixel >> 16) & 0xFF
		a := (pixel >> 24) & 0xFF
		result[i] = (a << 24) | (r << 16) | (g << 8) | b
	}
	return result
}
*/

rgba_u8_to_u32 :: proc(rgba: []u8) -> []u32 {
	count := len(rgba) / 4
	result := make([]u32, count)
	for i in 0..<count {
		r := u32(rgba[i*4 + 0])
		g := u32(rgba[i*4 + 1])
		b := u32(rgba[i*4 + 2])
		a := u32(rgba[i*4 + 3])
		result[i] = u32(a << 24) | u32(r << 16) | u32(g << 8) | u32(b)
	}

	return result
}


pad_rgb_to_rgba :: proc(rgb: []u8) -> []u32 {
	count := len(rgb) / 3
	result := make([]u32, count)

	for i in 0..<count {
		r := u32(rgb[i*3 + 0])
		g := u32(rgb[i*3 + 1])
		b := u32(rgb[i*3 + 2])
		a := 255
		result[i] = u32(a << 24) | u32(r << 16) | u32(g << 8) | u32(b)
	}
	return result
}

change_color_intensity :: proc(color: ^u32, factor: f32 = 0.5) {
    // Split the color value into its RGBA components

    a := u32(f32(color^ & 0xFF000000))
    r := u32(f32(color^ & 0x00FF0000) * factor)
    g := u32(f32(color^ & 0x0000FF00) * factor)
    b := u32(f32(color^ & 0x000000FF) * factor)

    color^ = a | r & 0x00FF0000 | g & 0x0000FF00 | b & 0x000000FF
    // color^ = a | r | g | b
}

change_pixel_alpha_value_u32 :: proc(color: ^u32, length: f32) {
    /*
		Note(bemused):
		This uses an easing function to calcualte the alpha value
		to simulate the lighting effect in the minimap.
		The furthest possible distance is the diagonal pixel distance
		of the map.
	*/
    
    ray_alpha_value: f32 = 1 - easing_out_quad(
		length /
		math.sqrt(
			f32(TILE_SIZE*MAP_NUM_COLS)*(TILE_SIZE*MAP_NUM_COLS) + f32(TILE_SIZE*MAP_NUM_ROWS)*(TILE_SIZE*MAP_NUM_ROWS)
		) 
	)

    a := u32(f32(color^ & 0xFF000000) * ray_alpha_value)
    r := u32(color^ & 0x00FF0000)
    g := u32(color^ & 0x0000FF00)
    b := u32(color^ & 0x000000FF)

    color^ = a & 0xFF000000 | r & 0x00FF0000 | g & 0x0000FF00 | b & 0x000000FF
} 

pixel_alpha_value_is_transparent :: proc(color: u32) -> bool {
    alpha := color >> 24
    return alpha == 0
}

pixel_is_pink :: proc(color: u32) -> bool {
	return color == 0xFFFF00FF
}

change_pixel_alpha_value_sdlcolor :: proc(color: ^sdl.Color, length: f32) {
    /*
		Note(bemused):
		This uses an easing function to calcualte the alpha value
		to simulate the lighting effect in the minimap.
		The furthest possible distance is the diagonal pixel distance
		of the map.
	*/
    
    ray_alpha_value: f32 = 1 - easing_out_quad(
		length /
		math.sqrt(
			f32(TILE_SIZE*MAP_NUM_COLS)*(TILE_SIZE*MAP_NUM_COLS) + f32(TILE_SIZE*MAP_NUM_ROWS)*(TILE_SIZE*MAP_NUM_ROWS)
		) 
	)

    color.a = u8(f32(color.a) * ray_alpha_value)
} 

change_pixel_alpha_value :: proc {
    change_pixel_alpha_value_u32,
    change_pixel_alpha_value_sdlcolor,
}

// @(init) Note: Moved to the setup() proc instead since we have this already in action. No need for @(init)
initialise_textures_array :: proc() {

	IMG_BLUESTONE  , err_load_bluestone   := png.load_from_file("./images/bluestone.png")  //; log.error(err_load_bluestone)
	IMG_COLORSTONE , err_load_colorstone  := png.load_from_file("./images/colorstone.png") //; log.error(err_load_colorstone)
	IMG_EAGLE      , err_load_eagle       := png.load_from_file("./images/eagle.png")      //; log.error(err_load_eagle)
	IMG_GRAYSTONE  , err_load_graystone   := png.load_from_file("./images/graystone.png")  //; log.error(err_load_graystone)
	IMG_MOSSYSTONE , err_load_mossystone  := png.load_from_file("./images/mossystone.png") //; log.error(err_load_mossystone)
	IMG_PURPLESTONE, err_load_purplestone := png.load_from_file("./images/purplestone.png")//; log.error(err_load_purplestone)
	IMG_REDBRICK   , err_load_redbrick    := png.load_from_file("./images/redbrick.png")   //; log.error(err_load_redbrick)
	IMG_WOOD       , err_load_wood        := png.load_from_file("./images/wood.png")       //; log.error(err_load_wood)
	IMG_PIKUMA     , err_load_pikuma      := png.load_from_file("./images/pikuma.png")     //; log.error(err_load_pikuma)

	bluestone_data   := pad_rgb_to_rgba(IMG_BLUESTONE  .pixels.buf[:])
	colorstone_data  := pad_rgb_to_rgba(IMG_COLORSTONE .pixels.buf[:])
	eagle_data       := pad_rgb_to_rgba(IMG_EAGLE      .pixels.buf[:])
	graystone_data   := pad_rgb_to_rgba(IMG_GRAYSTONE  .pixels.buf[:])
	mossystone_data  := pad_rgb_to_rgba(IMG_MOSSYSTONE .pixels.buf[:])
	purplestone_data := pad_rgb_to_rgba(IMG_PURPLESTONE.pixels.buf[:])
	redbrick_data    := pad_rgb_to_rgba(IMG_REDBRICK   .pixels.buf[:])
	wood_data        := pad_rgb_to_rgba(IMG_WOOD       .pixels.buf[:])
	pikuma_data      := pad_rgb_to_rgba(IMG_PIKUMA     .pixels.buf[:])

	textures = {
		.Empty       = procedurally_generated_wall_texture,
		.Bluestone   = bluestone_data,
		.Colorstone  = colorstone_data,
		.Eagle       = eagle_data,
		.Graystone   = graystone_data,
		.Mossystone  = mossystone_data,
		.Purplestone = purplestone_data,
		.Redbrick    = redbrick_data,
		.Wood        = wood_data,
		.Pikuma      = pikuma_data,
	}
}