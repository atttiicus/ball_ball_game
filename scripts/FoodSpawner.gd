class_name FoodSpawner
extends Node

const MAX_FOOD := 500
const SPAWN_BATCH := 20       # 每次补充数量
const SPAWN_INTERVAL := 0.5  # 秒

var world_size: Vector2 = Vector2(4000.0, 4000.0)
var container: Node2D

static var FOOD_COLORS := [
	Color(1.0, 0.35, 0.35),
	Color(0.35, 1.0, 0.45),
	Color(0.35, 0.65, 1.0),
	Color(1.0, 0.85, 0.2),
	Color(0.9, 0.35, 1.0),
	Color(0.2, 0.95, 0.95),
]

var _timer: float = 0.0


func _ready() -> void:
	# 初始填满
	_spawn_batch(MAX_FOOD)


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= SPAWN_INTERVAL:
		_timer = 0.0
		var current := container.get_child_count() if container else 0
		if current < MAX_FOOD:
			_spawn_batch(min(SPAWN_BATCH, MAX_FOOD - current))


func _spawn_batch(count: int) -> void:
	for i in count:
		var food := Food.new()
		food.food_color = FOOD_COLORS[randi() % FOOD_COLORS.size()]
		food.position = Vector2(
			randf_range(20.0, world_size.x - 20.0),
			randf_range(20.0, world_size.y - 20.0)
		)
		container.add_child(food)
