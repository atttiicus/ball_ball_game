class_name AIBall
extends Ball

enum State { FORAGE, HUNT, FLEE }

var state: State = State.FORAGE
var _target_pos: Vector2 = Vector2.ZERO
var _state_timer: float = 0.0
const STATE_INTERVAL := 0.4  # 秒，重新评估状态

static var AI_NAMES := [
	"Slime", "Blob", "Goo", "Orb", "Zap", "Nyx", "Pix", "Rex",
	"Gale", "Flux", "Nova", "Bolt", "Haze", "Mire", "Vex", "Zed"
]
static var AI_COLORS := [
	Color(1.0, 0.4, 0.4), Color(0.4, 0.85, 0.4), Color(1.0, 0.75, 0.2),
	Color(0.85, 0.35, 1.0), Color(0.3, 0.9, 0.9), Color(1.0, 0.5, 0.1),
	Color(0.6, 1.0, 0.5), Color(1.0, 0.4, 0.7),
]


func _ready() -> void:
	ball_color = AI_COLORS[randi() % AI_COLORS.size()]
	ball_name = AI_NAMES[randi() % AI_NAMES.size()]
	mass = PI * randf_range(15.0, 35.0) ** 2
	super._ready()
	got_eaten.connect(_on_got_eaten)
	_target_pos = _random_world_pos()


func _physics_process(delta: float) -> void:
	_state_timer += delta
	if _state_timer >= STATE_INTERVAL:
		_state_timer = 0.0
		_evaluate_state()

	_move_toward(_target_pos, delta)
	clamp_to_world()


func _evaluate_state() -> void:
	var balls: Array = get_tree().get_nodes_in_group("balls")
	var nearest_prey: Ball = null
	var nearest_threat: Ball = null
	var prey_dist := INF
	var threat_dist := INF

	for b in balls:
		if b == self or not is_instance_valid(b):
			continue
		var d: float = global_position.distance_to(b.global_position)
		var ball := b as Ball
		if can_eat(ball) and d < prey_dist:
			nearest_prey = ball
			prey_dist = d
		elif ball.can_eat(self) and d < threat_dist:
			nearest_threat = ball
			threat_dist = d

	if nearest_threat != null and threat_dist < radius * 8.0:
		state = State.FLEE
		# 逃离方向：远离威胁
		var flee_dir := (global_position - nearest_threat.global_position).normalized()
		_target_pos = global_position + flee_dir * 400.0
	elif nearest_prey != null and prey_dist < radius * 10.0:
		state = State.HUNT
		_target_pos = nearest_prey.global_position
	else:
		state = State.FORAGE
		if global_position.distance_to(_target_pos) < 60.0:
			_target_pos = _random_world_pos()


func _move_toward(target: Vector2, delta: float) -> void:
	var dir := target - global_position
	if dir.length() < 10.0:
		return
	velocity = dir.normalized() * get_speed()
	move_and_collide(velocity * delta)


func _random_world_pos() -> Vector2:
	return Vector2(
		randf_range(50.0, WORLD_SIZE.x - 50.0),
		randf_range(50.0, WORLD_SIZE.y - 50.0)
	)


func _on_got_eaten(_by: Ball) -> void:
	queue_free()
