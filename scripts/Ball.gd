class_name Ball
extends CharacterBody2D

signal eaten_food(amount: float)
signal ate_ball(other: Ball)
signal got_eaten(by: Ball)
signal split_forced  # 被炸弹强制分裂

var mass: float = 10.0
var radius: float = 20.0
var ball_name: String = ""
var ball_color: Color = Color(0.2, 0.6, 1.0)

var collision_shape: CollisionShape2D
var name_label: Label

static var effects_node: Node2D = null

var is_invincible: bool = false

# 视觉缩放（用于出生/脉冲动画）。setter 自动触发重绘。
var visual_scale: float = 1.0:
	set(v):
		visual_scale = v
		queue_redraw()

# 以下常量从 GameConfig autoload 读取，此处保留别名方便子类直接使用
var MIN_RADIUS: float  = GameConfig.BALL_MIN_RADIUS
var MAX_RADIUS: float  = GameConfig.BALL_MAX_RADIUS
var EAT_RATIO: float   = GameConfig.EAT_RATIO
var WORLD_SIZE: Vector2 = GameConfig.WORLD_SIZE


func _ready() -> void:
	collision_layer = 1
	collision_mask = 2
	_build_nodes()
	_apply_mass(mass)
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


func _process(_delta: float) -> void:
	# 移动变形和无敌闪烁都需要每帧重绘
	queue_redraw()


func _draw() -> void:
	var draw_r := radius * visual_scale

	# 无敌闪烁
	var c := ball_color
	if is_invincible:
		c.a = 0.35 if (int(Time.get_ticks_msec() / 150) % 2 == 0) else 0.85

	# 移动变形：速度方向拉伸，垂直方向压缩
	var spd := velocity.length()
	if spd > 15.0 and visual_scale > 0.8:
		var ratio := minf(spd / get_speed(), 1.0) * 0.18
		var rot := velocity.angle()
		draw_set_transform(Vector2.ZERO, rot, Vector2(1.0 + ratio, 1.0 - ratio * 0.55))

	# 主体
	draw_circle(Vector2.ZERO, draw_r, c)

	# 高光
	var highlight := ball_color.lightened(0.4)
	highlight.a = 0.55
	draw_circle(Vector2(-draw_r * 0.28, -draw_r * 0.28), draw_r * 0.32, highlight)

	# 轮廓
	draw_arc(Vector2.ZERO, draw_r, 0.0, TAU, 48, ball_color.darkened(0.28), 2.0)


# ── 动画方法 ──────────────────────────────────────────

func play_spawn_anim() -> void:
	visual_scale = 0.0
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "visual_scale", 1.0, 0.35)


func play_pulse_anim() -> void:
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "visual_scale", 1.18, 0.1)
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(self, "visual_scale", 1.0, 0.14)


# ── 核心逻辑 ──────────────────────────────────────────

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
	return clampf(GameConfig.SPEED_MULT / radius, GameConfig.SPEED_MIN, GameConfig.SPEED_MAX)


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
		if dist < radius and can_eat(other) and not other.is_invincible:
			_eat_ball(other)


func _eat_ball(other: Ball) -> void:
	add_mass(other.mass * 0.8)
	play_pulse_anim()
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
		play_pulse_anim()
		if SoundManager:
			SoundManager.play_eat_food()
		emit_signal("eaten_food", food.food_mass)
		food.queue_free()
