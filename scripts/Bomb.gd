class_name Bomb
extends Area2D

var _active: bool = true
var _visual_scale: float = 1.0:
	set(v):
		_visual_scale = v
		queue_redraw()


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = GameConfig.BOMB_RADIUS
	shape.shape = circle
	add_child(shape)

	body_entered.connect(_on_body_entered)

	_visual_scale = 0.0
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "_visual_scale", 1.0, 0.4)


func _draw() -> void:
	if not _active and _visual_scale <= 0.01:
		return
	var r: float = GameConfig.BOMB_RADIUS * _visual_scale

	draw_circle(Vector2.ZERO, r, Color(0.18, 0.18, 0.18))
	draw_arc(Vector2.ZERO, r * 0.92, 0.0, TAU, 36, Color(1.0, 0.35, 0.0), 2.5)

	var bar_h := r * 0.42
	draw_line(Vector2(0.0, -bar_h), Vector2(0.0, r * 0.05), Color(1.0, 0.85, 0.0), 2.5)
	draw_circle(Vector2(0.0, r * 0.28), 2.2, Color(1.0, 0.85, 0.0))

	if _active:
		var pulse := absf(sin(Time.get_ticks_msec() * 0.003))
		draw_circle(Vector2.ZERO, r * 1.15, Color(1.0, 0.4, 0.0, pulse * 0.35))


func _process(_delta: float) -> void:
	if _active:
		queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if not _active or not body is Ball:
		return
	var ball := body as Ball
	if ball.radius < GameConfig.PLAYER_MIN_SPLIT_RADIUS:
		return

	_active = false
	if is_instance_valid(Ball.effects_node):
		EatEffect.spawn(Ball.effects_node, global_position, Color(1.0, 0.4, 0.0), GameConfig.BOMB_RADIUS * 3.0)
	ball.emit_signal("split_forced")

	var tw := create_tween()
	tw.tween_property(self, "_visual_scale", 0.0, 0.2)
	get_tree().create_timer(GameConfig.BOMB_RESPAWN_TIME).timeout.connect(_respawn)


func _respawn() -> void:
	_active = true
	_visual_scale = 0.0
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "_visual_scale", 1.0, 0.4)
