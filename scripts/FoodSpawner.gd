class_name FoodSpawner
extends Node

var world_size: Vector2 = GameConfig.WORLD_SIZE
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
	_spawn_batch(GameConfig.FOOD_MAX_COUNT)


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= GameConfig.FOOD_SPAWN_INTERVAL:
		_timer = 0.0
		var current := container.get_child_count() if container else 0
		if current < GameConfig.FOOD_MAX_COUNT:
			_spawn_batch(min(GameConfig.FOOD_SPAWN_BATCH, GameConfig.FOOD_MAX_COUNT - current))


func _spawn_batch(count: int) -> void:
	for i in count:
		var food := Food.new()
		food.food_color = FOOD_COLORS[randi() % FOOD_COLORS.size()]
		food.position = Vector2(
			randf_range(20.0, world_size.x - 20.0),
			randf_range(20.0, world_size.y - 20.0)
		)
		container.add_child(food)
