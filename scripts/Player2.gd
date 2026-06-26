class_name Player2
extends Ball

var is_dead: bool = false


func _ready() -> void:
	ball_color = Color(1.0, 0.45, 0.2)
	ball_name = "Player2"
	mass = PI * 20.0 * 20.0
	super._ready()
	got_eaten.connect(_on_got_eaten)


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_move_wasd(delta)
	clamp_to_world()


func _move_wasd(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("p2_up"):    dir.y -= 1
	if Input.is_action_pressed("p2_down"):  dir.y += 1
	if Input.is_action_pressed("p2_left"):  dir.x -= 1
	if Input.is_action_pressed("p2_right"): dir.x += 1
	if dir == Vector2.ZERO:
		velocity = Vector2.ZERO
		return
	velocity = dir.normalized() * get_speed()
	move_and_collide(velocity * delta)


func _on_got_eaten(_by: Ball) -> void:
	if is_dead:
		return
	is_dead = true
	queue_free()
