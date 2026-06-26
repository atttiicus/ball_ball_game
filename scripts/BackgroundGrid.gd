class_name BackgroundGrid
extends Node2D

var world_size := Vector2(4000.0, 4000.0)

const GRID_SIZE := 80.0
const BG_COLOR := Color(0.96, 0.96, 0.96)
const GRID_COLOR := Color(0.85, 0.85, 0.85)
const BORDER_COLOR := Color(0.6, 0.6, 0.8)
const BORDER_WIDTH := 4.0


func _draw() -> void:
	# 背景填充
	draw_rect(Rect2(Vector2.ZERO, world_size), BG_COLOR)

	# 网格线（垂直）
	var x := 0.0
	while x <= world_size.x:
		draw_line(Vector2(x, 0), Vector2(x, world_size.y), GRID_COLOR, 1.0)
		x += GRID_SIZE

	# 网格线（水平）
	var y := 0.0
	while y <= world_size.y:
		draw_line(Vector2(0, y), Vector2(world_size.x, y), GRID_COLOR, 1.0)
		y += GRID_SIZE

	# 世界边框
	draw_rect(Rect2(Vector2.ZERO, world_size), BORDER_COLOR, false, BORDER_WIDTH)
