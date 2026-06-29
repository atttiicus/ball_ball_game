class_name AISpawner
extends Node

const AIBallScene := preload("res://scenes/AIBall.tscn")

var world_size: Vector2 = GameConfig.WORLD_SIZE
var container: Node2D


func _ready() -> void:
	_fill_ai()


func _process(_delta: float) -> void:
	if container.get_child_count() < GameConfig.AI_COUNT:
		_spawn_one()


func _fill_ai() -> void:
	for i in GameConfig.AI_COUNT:
		_spawn_one()


func _spawn_one() -> void:
	var ai: AIBall = AIBallScene.instantiate()
	ai.position = Vector2(
		randf_range(100.0, world_size.x - 100.0),
		randf_range(100.0, world_size.y - 100.0)
	)
	ai.add_to_group("balls")
	container.add_child(ai)
