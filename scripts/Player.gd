class_name Player
extends Ball

var is_dead: bool = false
var joystick: TouchJoystick = null


func _ready() -> void:
	ball_color = Color(0.2, 0.6, 1.0)
	ball_name = "Player"
	mass = PI * 20.0 * 20.0
	super._ready()
	got_eaten.connect(_on_got_eaten)
	_setup_joystick()


func _setup_joystick() -> void:
	joystick = TouchJoystick.new()
	# 挂到 CanvasLayer 保证不受摄像机缩放影响
	var canvas := CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)
	canvas.add_child(joystick)


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if DisplayServer.is_touchscreen_available() and joystick.direction != Vector2.ZERO:
		_move_by_dir(joystick.direction, delta)
	else:
		_move_toward_mouse(delta)
	clamp_to_world()


func _move_toward_mouse(delta: float) -> void:
	var target := get_global_mouse_position()
	var dir := target - global_position
	if dir.length() < radius * 0.5:
		velocity = Vector2.ZERO
		return
	velocity = dir.normalized() * get_speed()
	move_and_collide(velocity * delta)


func _move_by_dir(dir: Vector2, delta: float) -> void:
	velocity = dir.normalized() * get_speed()
	move_and_collide(velocity * delta)


func _on_got_eaten(_by: Ball) -> void:
	if is_dead:
		return
	is_dead = true
	if SoundManager:
		SoundManager.play_die()
	queue_free()
