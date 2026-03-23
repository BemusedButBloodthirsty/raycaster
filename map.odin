package wolf3d

import "core:math"
import sdl "vendor:sdl2"

MAP_NUM_ROWS 		 :: 34
MAP_NUM_COLS		 :: 20
MINIMAP_SCALE_FACTOR :: 0.2
TILE_SIZE 			 :: 64 // This is linked to texture size. Textures are 64x64 pixels.
WALL_HEIGHT          :: TILE_SIZE * 1

@(rodata)
@(private="file")
game_map := [MAP_NUM_ROWS][MAP_NUM_COLS]int {
	{1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2},
	{1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3},
	{1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3},
	{1, 0, 0, 0, 9, 0, 5, 0, 5, 0, 5, 0, 6, 0, 6, 0, 6, 0, 0, 3},
	{1, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3},
	{1, 0, 0, 0, 9, 9, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 3},
	{1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 3},
	{1, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0, 3},
	{1, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 7, 7, 7, 7, 0, 0, 3},
	{1, 0, 0, 0, 8, 8, 8, 8, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3},
	{1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3},
	{1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3},
    {1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3},
	{4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3},
}

Intersection_Kind :: enum int {
	Horizontal = 0,
	Vertical = 1,
}

Tile_Kind :: enum int {
	Empty = 0,
	Bluestone,
	Colorstone,
	Eagle,
	Graystone,
	Mossystone,
	Purplestone,
	Redbrick,
	Wood = 8,
	Pikuma = 9,
}

Tile_Color :: enum int {
	Black = 0,
	Red,
	Green,
	Blue,
	Orange,
	Pink,
	Purple,
	Brown,
	White,
	Cyan,
}

get_map_at :: proc(i, j: int) -> int {
	return game_map[i][j]
}

render_minimap :: proc() {

	render_minimap_background :: proc() {
		// Note(bemused):
		// Draw the background.
		for r: int; r < MAP_NUM_ROWS; r += 1 {
			for c: int; c < MAP_NUM_COLS; c += 1 {
				tile_X: i32 = i32(c) * TILE_SIZE
				tile_Y: i32 = i32(r) * TILE_SIZE

				tile_color: sdl.Color

				switch cast(Tile_Color) get_map_at(r,c) {
				case .Black:	tile_color = sdl.Color{   0,   0,   0, 255}
				case .Red: 		tile_color = sdl.Color{ 255,   0,   0, 255}
				case .Green: 	tile_color = sdl.Color{	  0, 255,   0, 255}
				case .Blue:		tile_color = sdl.Color{   0,   0, 255, 255}
				case .Orange: 	tile_color = sdl.Color{ 255, 128,   0, 255}
				case .Brown:    tile_color = sdl.Color{ 139,  69,  19, 255}
				case .Pink:     tile_color = sdl.Color{ 255,  20, 147, 255}
				case .Purple:   tile_color = sdl.Color{ 128,   0, 128, 255}
				case .White:    tile_color = sdl.Color{ 255, 255, 255, 255}
				case .Cyan:     tile_color = sdl.Color{   0, 255, 255, 255}
				}

				draw_rect(
					x=int(math.round(f32(tile_X) * MINIMAP_SCALE_FACTOR)),
					y=int(math.round(f32(tile_Y) * MINIMAP_SCALE_FACTOR)),
					width=int(math.round(f32(TILE_SIZE) * MINIMAP_SCALE_FACTOR)),
					height=int(math.round(f32(TILE_SIZE) * MINIMAP_SCALE_FACTOR)),
					color=color_to_argb8888(tile_color),
				)
			}
		}
	}

	render_minimap_background()
	render_minimap_rays()
    render_minimap_sprites()
	render_minimap_player()
}
