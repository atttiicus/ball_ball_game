class_name Ball
extends CharacterBody2D

signal eaten_food(amount: float)
signal ate_ball(other: Ball)
signal got_eaten(by: Ball)

var mass: float = 10.0
var radius: float = 20.0
var ball_name: String = ""
var ball_color: Color = Color(0.2, 0.6, 1.0)

var collision_shape: CollisionShape2D
var name_label: Label

# 特效容器，由 Main._ready() 赋值
static var effects_node: Node2D = null

const MIN_RADIUS := 15.0
const MAX_RADIUS := 400.0
const EAT_RATIO := 1.1
const WORLD_SIZE := Vector2(4000.0, 4000.0)


func _ready() -> void:
	# layer=1：球自身层；mask=2：只与边界墙（layer=2）物理碰撞，球之间不物理阻挡
	collision_layer = 1
	collision_mask = 2
	_build_nodes()
	_apply_mass(mass)
	# 食物检测区域（Food 在 layer=4）
	var area := Area2D.new()
	var ashape := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = radius
	ashape.shape = circ
	area.collision_layer = 0
	area.collision_mask = 4
	area.add_child(ashape)
	area.area_entered.connect(_on_food_entered)
	add_child(area)


func _draw() -> void:
	# 主体
	draw_circle(Vector2.ZERO, radius, ball_color)
	# 高光
	var highlight := ball_color.lightened(0.35)
	highlight.a = 0.6
	draw_circle(Vector2(-radius * 0.28, -radius * 0.28), radius * 0.3, highlight)
	# 轮廓
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, ball_color.darkened(0.3), 2.0)


func _build_nodes() -> void:
	collision_shape = CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	collision_shape.shape = circle
	add_child(collision_shape)

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

	# 同步食物检测区域半径（collision_mask=4 的那个 Area2D）
	for child in get_children():
		if child is Area2D:
			for sc in child.get_children():
				if sc is CollisionShape2D and sc.shape is CircleShape2D:
					(sc.shape as CircleShape2D).radius = radius
			break

	queue_redraw()


func add_mass(amount: float) -> void:
	_apply_mass(mass + amount)


func get_speed() -> float:
	return clampf(250.0 / (1.0 + radius / 60.0), 80.0, 250.0)


func can_eat(other: Ball) -> bool:
	return mass >= other.mass * EAT_RATIO


func clamp_to_world() -> void:
	position.x = clampf(position.x, radius, WORLD_SIZE.x - radius)
	position.y = clampf(position.y, radius, WORLD_SIZE.y - radius)


func check_ball_collisions(balls: Array) -> void:
	for other in balls:
		if other == self or not is_instance_valid(other):
			continue
		var dist: float = global_position.distance_to(other.global_position)
		# 球间无物理碰撞，当对方球心进入本球半径内即可吞噬
		if dist < radius and can_eat(other):
			_eat_ball(other)


func _eat_ball(other: Ball) -> void:
	add_mass(other.mass * 0.8)
	var fx_parent := effects_node if is_instance_valid(effects_node) else get_parent()
	EatEffect.spawn(fx_parent, other.global_position, other.ball_color, other.radius)
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
