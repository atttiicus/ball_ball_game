class_name Minimap
extends Control

const BG_COLOR := Color(0.1, 0.1, 0.15, 0.8)
const BORDER_COLOR := Color(0.5, 0.5, 0.7)
const FOOD_COLOR := Color(0.5, 0.9, 0.5, 0.6)
const PLAYER_COLOR := Color(0.3, 0.7, 1.0)
const AI_COLOR := Color(1.0, 0.5, 0.5, 0.8)

var _player: Ball = null


func refresh(player: Ball) -> void:
	_player = player
	queue_redraw()


func _draw() -> void:
	var sz := size
	draw_rect(Rect2(Vector2.ZERO, sz), BG_COLOR)
	draw_rect(Rect2(Vector2.ZERO, sz), BORDER_COLOR, false, 1.5)

	var balls := get_tree().get_nodes_in_group("balls") if get_tree() else []
	for b in balls:
		var ball := b as Ball
		var mp := _world_to_map(ball.global_position, sz)
		var dot_r := clampf(ball.radius / 30.0, 1.5, 5.0)
		var col := PLAYER_COLOR if ball is Player else AI_COLOR
		draw_circle(mp, dot_r, col)

	# 玩家标记（始终最上层）
	if is_instance_valid(_player):
		var pp := _world_to_map(_player.global_position, sz)
		draw_circle(pp, 4.0, Color.WHITE)


func _world_to_map(world_pos: Vector2, map_sz: Vector2) -> Vector2:
	return Vector2(
		world_pos.x / GameConfig.WORLD_SIZE.x * map_sz.x,
		world_pos.y / GameConfig.WORLD_SIZE.y * map_sz.y
	)
