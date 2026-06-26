class_name Ball
extends CharacterBody2D

signal eaten_food(amount: float)
signal ate_ball(other: Ball)
signal got_eaten(by: Ball)

# 体积相关
var mass: float = 10.0
var radius: float = 20.0
var ball_name: String = ""
var ball_color: Color = Color.WHITE

var collision_shape: CollisionShape2D
var name_label: Label
var _sprite: BallSprite

const MIN_RADIUS := 15.0
const MAX_RADIUS := 400.0
const EAT_RATIO := 1.1
const WORLD_SIZE := Vector2(4000.0, 4000.0)


func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	_build_nodes()
	_apply_mass(mass)
	# 检测食物（Area2D, layer=2）
	var area := Area2D.new()
	var ashape := CollisionShape2D.new()
	ashape.shape = CircleShape2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	area.add_child(ashape)
	area.area_entered.connect(_on_food_entered)
	add_child(area)
	_update_detect_area(area, ashape)


func _build_nodes() -> void:
	collision_shape = CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	collision_shape.shape = circle
	add_child(collision_shape)

	_sprite = BallSprite.new()
	_sprite.set_meta("ball", self)
	add_child(_sprite)

	name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.z_index = 1
	add_child(name_label)


func _apply_mass(new_mass: float) -> void:
	mass = clampf(new_mass, MIN_RADIUS * MIN_RADIUS * PI, MAX_RADIUS * MAX_RADIUS * PI)
	radius = clampf(sqrt(mass / PI), MIN_RADIUS, MAX_RADIUS)

	if collision_shape and collision_shape.shape:
		(collision_shape.shape as CircleShape2D).radius = radius

	if name_label:
		name_label.add_theme_font_size_override("font_size", max(12, int(radius * 0.4)))
		name_label.position = Vector2(-radius, -radius * 0.3)
		name_label.size = Vector2(radius * 2, radius * 0.8)
		name_label.text = ball_name

	if _sprite:
		_sprite.queue_redraw()

	# 同步食物检测区域半径
	for child in get_children():
		if child is Area2D:
			for sc in child.get_children():
				if sc is CollisionShape2D and sc.shape is CircleShape2D:
					(sc.shape as CircleShape2D).radius = radius
			break


func _update_detect_area(area: Area2D, ashape: CollisionShape2D) -> void:
	if ashape.shape is CircleShape2D:
		(ashape.shape as CircleShape2D).radius = radius


func add_mass(amount: float) -> void:
	_apply_mass(mass + amount)


func get_speed() -> float:
	return clampf(250.0 / (1.0 + radius / 60.0), 80.0, 250.0)


func can_eat(other: Ball) -> bool:
	return mass >= other.mass * EAT_RATIO


func clamp_to_world() -> void:
	position.x = clampf(position.x, radius, WORLD_SIZE.x - radius)
	position.y = clampf(position.y, radius, WORLD_SIZE.y - radius)


# 每帧主动检测周围球
func check_ball_collisions(balls: Array) -> void:
	for other in balls:
		if other == self or not is_instance_valid(other):
			continue
		var dist: float = global_position.distance_to(other.global_position)
		if dist < radius * 0.85 and can_eat(other):
			_eat_ball(other)


func _eat_ball(other: Ball) -> void:
	add_mass(other.mass * 0.8)
	EatEffect.spawn(get_parent(), other.global_position, other.ball_color, other.radius)
	if SoundManager:
		SoundManager.play_eat_ball()
	emit_signal("ate_ball", other)
	other.emit_signal("got_eaten", self)
	other.queue_free()


func _on_food_entered(area: Area2D) -> void:
	if not is_instance_valid(area):
		return
	if area is Food:
		var food := area as Food
		add_mass(food.food_mass)
		if SoundManager:
			SoundManager.play_eat_food()
		emit_signal("eaten_food", food.food_mass)
		food.queue_free()
