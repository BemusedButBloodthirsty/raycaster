package wolf3d

import "core:image"
import "core:image/png"
import "core:math"
import sdl "vendor:sdl2"
import "core:fmt"


NUM_SPRITES :: 4

// NOTE(bemused): 
// 
// The sprite dimensions must match the Tiles. 
// 
SPRITE_WIDTH  :: 64
SPRITE_HEIGHT :: 64

Sprite_Kind :: enum int {
	Barrel = 0,
	Table,
    Lamp, 
	Werewolf,
}

Sprite_Color :: enum int {
    Red = 0, 
    Purple, 
    Orange,
    Blue, 
}

@(private="file") sprites: []Sprite

// NOTE(bemused, 26/01/2026): 
// 
// Sprites are not specified in the map by the look of things. 
// We initialise the sprites into a container. 
// We'll probably be iterating over this in the main loop and 
// checking if its in the FOV, and only then write it to the pixel buffer.
// 
// Transparency is alhpa value == 0. We ignore these pixels during draw.
// 

Sprite :: struct {
	// Map coords:
    x, y: 				f32,
	centre_x, centre_y: f32,
    w, h:				f32, 
    
	distance:			f32, 
    angle:				f32,
	projected_height:	f32,

    visible:			bool,
    image_data:			[]u32,
	color:				Sprite_Color,
	kind:				Sprite_Kind,
}

initialise_sprites :: proc() {
    
    // Load image data from file: 
    IMG_BARREL  , err_load_barrel   := png.load_from_file("./images/barrel.png")
    IMG_TABLE   , err_load_table    := png.load_from_file("./images/table.png")
    IMG_LAMP    , err_load_lamp     := png.load_from_file("./images/lamp.png")
    IMG_WEREWOLF, err_load_werewolf := png.load_from_file("./images/werewolf.png")

    // Sprites were generated in RGBA format already, just use u8 to u32 proc here: 
    image_data_barrel   := rgba_u8_to_u32(IMG_BARREL  .pixels.buf[:])
    image_data_table    := rgba_u8_to_u32(IMG_TABLE   .pixels.buf[:])
    image_data_lamp     := rgba_u8_to_u32(IMG_LAMP    .pixels.buf[:])
    image_data_werewolf := rgba_u8_to_u32(IMG_WEREWOLF.pixels.buf[:])
    
    // Adding data to sprites array:
	//
	// NOTE(bemused): Sprites can be made more random and dynamic now since we allocate enough for each.
	// 
    sprites = make([]Sprite, len=NUM_SPRITES/**size_of(Sprite)*/, allocator=context.temp_allocator)
	
	sprites[0] = Sprite {
		x = 640,
		y = 630,
		w = 20, 
		h = 20,
		color = .Blue,
		image_data = image_data_barrel,
		kind = .Barrel,
	}
	
	sprites[1] = Sprite {
		x = 630,
		y = 1240,
		w = 20, 
		h = 20,
		color = .Purple,
		image_data = image_data_table,
		kind = .Table,
	}

	sprites[2] = Sprite {
		x = 640,
		y = 2000,
		w = 20, 
		h = 20,
		color = .Orange,
		image_data = image_data_lamp,
		kind = .Lamp,
	}

	sprites[3] = Sprite {
		x = 1000,
		y = 2000,
		w = 20, 
		h = 20,
		color = .Red,
		image_data = image_data_werewolf,
		kind = .Werewolf,
	}

	// fmt.printf("Barrel channels: %v  |  width=%d height=%d  |  buf len=%d\n",
    // IMG_BARREL.channels, IMG_BARREL.width, IMG_BARREL.height, len(IMG_BARREL.pixels.buf))

	// NOTE(bemused): Making sure that centre coords are correct.
	for &sprite in sprites {
		sprite.centre_x = sprite.x + sprite.w/2
		sprite.centre_y = sprite.y + sprite.h/2
	}

} 

check_if_sprites_in_fov :: proc() {
    
    //
    // NOTE(bemused, 27/01/2026):  
    // ^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // We just need to find the difference in angle between the player and the sprite.
    // If the |angle| is greater than fov/2, we don't draw it.  
    //

    for &sprite in sprites {

        angle_between_sprite_and_player := player.rotation_angle - math.atan2(sprite.centre_y - player.centre_y, sprite.centre_x - player.centre_x)

        if abs(angle_between_sprite_and_player) < FOV_ANGLE/2 {
            sprite.visible = true

            sprite.angle = angle_between_sprite_and_player
            sprite.distance = distance_between(sprite.centre_x, sprite.centre_y, player.centre_x, player.centre_y)
			// Fishbowl correction:
			sprite_perpendicular_distance := sprite.distance * math.cos(sprite.angle)
			sprite.projected_height = (TILE_SIZE / /*sprite.distance*/ sprite_perpendicular_distance) * DIST_TO_PROJECTION_PLANE


            // fmt.println(sprite.color, sprite.distance) // DEBUG(bemused)
            // fmt.println(sprite.color, "is in view") // DEBUG(bemused)

        } else {
            sprite.visible = false
        }
    }
} 

draw_sprites :: proc() {
	
    for sprite in sprites {
		sprite_width := sprite.projected_height

		if !sprite.visible do continue // The sprite is not visible. 

		if sprite.visible {
			
			// Getting the r coords for the sprite:
			sprite_strip_height: int = cast(int) sprite.projected_height
			
			r_sprite_top: int = (WINDOW_HEIGHT / 2) - (sprite_strip_height / 2)
			r_sprite_bot: int = (WINDOW_HEIGHT / 2) + (sprite_strip_height / 2)
			
            r_sprite_top = clamp(r_sprite_top, 0, WINDOW_HEIGHT-1)
			r_sprite_bot = clamp(r_sprite_bot, 0, WINDOW_HEIGHT-1)
			
			// Getting the c coords for the sprite: 
            c_sprite_centre := math.tan(sprite.angle) * DIST_TO_PROJECTION_PLANE   
            
            c_sprite_left: int  = int((WINDOW_WIDTH / 2) - c_sprite_centre - sprite_width/2)
            c_sprite_right: int = c_sprite_left + int(sprite_width)

            c_sprite_left  = clamp(c_sprite_left,  0, WINDOW_WIDTH - 1)
            c_sprite_right = clamp(c_sprite_right, 0, WINDOW_WIDTH - 1)


			// Draw the sprite strip:
			draw_sprite_strip :: proc(r_sprite_bot, r_sprite_top, c_sprite_left, c_sprite_right: int, sprite_width: f32, sprite: Sprite) {

				for r in r_sprite_top..=r_sprite_bot {
					sprite_screen_height := (r - r_sprite_top) 
					sprite_pixel_coord_r := int(f32(sprite_screen_height) / sprite.projected_height * (SPRITE_HEIGHT-1))
	
					for c in c_sprite_left..=c_sprite_right {
						sprite_screen_width := (c - c_sprite_left)
						sprite_pixel_coord_c := int(f32(sprite_screen_width) / sprite_width * (SPRITE_WIDTH-1))
	
						sprite_pixel_color := sprite.image_data[SPRITE_HEIGHT*sprite_pixel_coord_r + sprite_pixel_coord_c]
											
						if /*pixel_alpha_value_is_transparent*/pixel_is_pink(sprite_pixel_color) do continue // Transparent, we don't need to draw it. 
						if !/*pixel_alpha_value_is_transparent*/pixel_is_pink(sprite_pixel_color) {
							// Not transparent, but then we need to check if its in front of the wall strip:
							if sprite_strip_in_front_of_wall(c, sprite) {
								draw_pixel(c, r, sprite_pixel_color)
							}
						}
					}			
				}
			}

			sprite_strip_in_front_of_wall :: proc(c: int, sprite: Sprite) -> bool {
				
				if rays[c].ray_length > sprite.distance {
					// Sprite is in front 
					return true
				} else {
					return false
				}
			}
			
			draw_sprite_strip(r_sprite_bot, r_sprite_top, c_sprite_left, c_sprite_right, sprite_width, sprite)

		} 
    }
}

sort_sprites_bubble :: proc() {
	
	swap :: proc(sprite_A, sprite_B: ^Sprite) {
		temp_sprite := sprite_B^

		sprite_B^ = sprite_A^
		sprite_A^ = temp_sprite
	}

	n := len(sprites)
	for n > 1 {
		newn := 0
		for i in 1..=n-1 {
			if sprites[i - 1].distance < sprites[i].distance {
				swap(&sprites[i - 1], &sprites[i])
				newn = i
			} 
		}
		n = newn
	}
}

render_minimap_sprites :: proc() {

    for sprite in sprites {

        sprite_color: sdl.Color

        switch sprite.color {
        case .Red:    sprite_color = sdl.Color{ 255,   0,   0, 255}
        case .Purple: sprite_color = sdl.Color{ 128,   0, 128, 255}
        case .Orange: sprite_color = sdl.Color{ 255, 128,   0, 255}
        case .Blue:   sprite_color = sdl.Color{   0,   0, 255, 255}        
        }
        
        sprite_color_argb8888 := color_to_argb8888(sprite_color)

        if !sprite.visible {
            change_color_intensity(&sprite_color_argb8888, 0.2)
        }

        draw_rect(
            x=int(math.round(sprite.centre_x * MINIMAP_SCALE_FACTOR)),
            y=int(math.round(sprite.centre_y * MINIMAP_SCALE_FACTOR)),
            width=int(math.round(sprite.w * MINIMAP_SCALE_FACTOR)),
            height=int(math.round(sprite.h * MINIMAP_SCALE_FACTOR)),
            color=sprite_color_argb8888
        )
    }
}
