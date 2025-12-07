package main

import "core:math"
import rl "vendor:raylib"

Type :: enum {
	Yin,
	Yang,
}

Tile :: struct {
	type:   Type,
	bounds: rl.Rectangle,
}

Ball :: struct {
	position: [2]f32,
	velocity: [2]f32,
}

PAD1 :: 4
PAD3 :: 16

ROWS :: 20
COLS :: 20

ENTITY_SIZE :: 40

FONT_SIZE :: 10

CONTENT_W :: COLS * ENTITY_SIZE
CONTENT_H :: ROWS * ENTITY_SIZE

SCREEN_W :: CONTENT_W
SCREEN_H :: CONTENT_H + PAD1 + FONT_SIZE + PAD1
TARGET_FPS :: 60

INITIAL_VELOCITY :: [2]f32{ENTITY_SIZE * 5 / 8, ENTITY_SIZE * 5 / 8}

YIN_COLOR :: rl.GOLD
YANG_COLOR :: rl.DARKBLUE

setup :: proc(yang_ball, yin_ball: ^Ball, tiles: ^[COLS][ROWS]Tile) {
	yang_ball^ = Ball{[2]f32{6 * ENTITY_SIZE, 2 * ENTITY_SIZE}, INITIAL_VELOCITY}
	yin_ball^ = Ball{[2]f32{13 * ENTITY_SIZE, 17 * ENTITY_SIZE}, INITIAL_VELOCITY}

	for row in 0 ..< ROWS {
		y := f32(row * ENTITY_SIZE)

		for col in 0 ..< COLS {
			x := f32(col * ENTITY_SIZE)

			tiles[col][row].type = .Yin if col < 10 else .Yang
			tiles[col][row].bounds = rl.Rectangle{x, y, ENTITY_SIZE, ENTITY_SIZE}
		}
	}
	tiles[9][4].type = .Yang
	tiles[9][5].type = .Yang
	tiles[10][14].type = .Yin
	tiles[10][15].type = .Yin
}

reflect :: proc(ball: ^Ball, tile: ^Tile) {
	ball_left := ball.position.x
	ball_right := ball.position.x + ENTITY_SIZE
	ball_top := ball.position.y
	ball_bottom := ball.position.y + ENTITY_SIZE

	tile_left := tile.bounds.x
	tile_right := tile.bounds.x + tile.bounds.width
	tile_top := tile.bounds.y
	tile_bottom := tile.bounds.y + tile.bounds.height

	if ball_left <= tile_left && ball_right >= tile_left && ball_right < tile_right {
		ball.velocity.x = -math.abs(ball.velocity.x)
	}
	if ball_left <= tile_right && ball_right >= tile_right && ball_left > tile_left {
		ball.velocity.x = math.abs(ball.velocity.x)
	}
	if ball_top <= tile_top && ball_bottom >= tile_top && ball_bottom < tile_bottom {
		ball.velocity.y = -math.abs(ball.velocity.y)
	}
	if ball_top <= tile_bottom && ball_bottom >= tile_bottom && ball_top > tile_top {
		ball.velocity.y = math.abs(ball.velocity.y)
	}

	tile.type = .Yin if tile.type == .Yang else .Yang
}

check_for_reflections :: proc(yang_ball, yin_ball: ^Ball, tiles: ^[COLS][ROWS]Tile) {
	yang_ball_bounds := rl.Rectangle {
		yang_ball.position.x,
		yang_ball.position.y,
		ENTITY_SIZE,
		ENTITY_SIZE,
	}
	find_yang_loop: for row in 0 ..< ROWS {
		for col in 0 ..< COLS {
			tile := &tiles[col][row]
			if tile.type == .Yang && rl.CheckCollisionRecs(yang_ball_bounds, tile.bounds) {
				reflect(yang_ball, tile)
				break find_yang_loop
			}
		}
	}

	yin_ball_bounds := rl.Rectangle {
		yin_ball.position.x,
		yin_ball.position.y,
		ENTITY_SIZE,
		ENTITY_SIZE,
	}
	find_yin_loop: for row in 0 ..< ROWS {
		for col in 0 ..< COLS {
			tile := &tiles[col][row]
			if tile.type == .Yin && rl.CheckCollisionRecs(yin_ball_bounds, tile.bounds) {
				reflect(yin_ball, tile)
				break find_yin_loop
			}
		}
	}
}

keep_in_bounds :: proc(ball: ^Ball) {
	if ball.position.x <= 0 || (ball.position.x + ENTITY_SIZE) >= (CONTENT_W - 1) {
		ball.velocity.x *= -1
	}
	if ball.position.y <= 0 || (ball.position.y + ENTITY_SIZE) >= (CONTENT_H - 1) {
		ball.velocity.y *= -1
	}
}

draw_stats :: proc(tiles: ^[COLS][ROWS]Tile, show_fps: bool) {
	yin_count, yang_count: i32
	for row in 0 ..< ROWS {
		for col in 0 ..< COLS {
			tile := tiles[col][row]
			if tile.type == .Yin {
				yin_count += 1
			} else {
				yang_count += 1
			}
		}
	}

	stats: cstring
	if show_fps {
		stats = rl.TextFormat("%d yin    %d yang    (%d FPS)", yin_count, yang_count, rl.GetFPS())
	} else {
		stats = rl.TextFormat("%d yin    %d yang", yin_count, yang_count)
	}
	rl.DrawText(stats, PAD3, SCREEN_H - PAD1 - FONT_SIZE, FONT_SIZE, rl.RAYWHITE)
}

main :: proc() {
	rl.InitWindow(SCREEN_W, SCREEN_H, "Yinyang")
	defer rl.CloseWindow()

	rl.SetTargetFPS(TARGET_FPS)

	yang_ball := Ball{}
	yin_ball := Ball{}
	tiles := [COLS][ROWS]Tile{}
	setup(&yang_ball, &yin_ball, &tiles)

	show_fps := false
	paused := false

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		defer rl.EndDrawing()

		rl.ClearBackground(rl.BLACK)

		for row in 0 ..< ROWS {
			for col in 0 ..< COLS {
				tile := tiles[col][row]
				color := YIN_COLOR if tile.type == .Yin else YANG_COLOR
				rl.DrawRectangleRec(tile.bounds, color)
			}
		}

		r := f32(ENTITY_SIZE) / 2
		rl.DrawCircle(i32(yang_ball.position.x + r), i32(yang_ball.position.y + r), r, YANG_COLOR)
		rl.DrawCircle(i32(yin_ball.position.x + r), i32(yin_ball.position.y + r), r, YIN_COLOR)

		if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
			show_fps = !show_fps
		}
		draw_stats(&tiles, show_fps)

		if rl.IsKeyPressed(rl.KeyboardKey.P) {
			paused = !paused
		}
		if !paused {
			yang_ball.position += yang_ball.velocity
			yin_ball.position += yin_ball.velocity

			check_for_reflections(&yang_ball, &yin_ball, &tiles)
			keep_in_bounds(&yang_ball)
			keep_in_bounds(&yin_ball)

			if rl.IsKeyPressed(rl.KeyboardKey.R) {
				setup(&yang_ball, &yin_ball, &tiles)
			}
		}
	}
}
