class_name AIBall
extends Ball

enum State { FORAGE, HUNT, FLEE }

var state: State = State.FORAGE
var _target_pos: Vector2 = Vector2.ZERO
var _state_timer: float = 0.0

# ── 分裂 / 合并 ───────────────────────────────────────
# null = 此球是领导球；非null = 此球是分裂出的从属球
var group_leader: AIBall = null
var merge_timer: float = 0.0

# 分裂后的惯性飞出
var launch_velocity: Vector2 = Vector2.ZERO

# 战术分裂计时
var _flee_timer: float = 0.0
var _hunt_timer: float = 0.0
var _split_used: bool = false

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
	ball_name  = AI_NAMES[randi() % AI_NAMES.size()]
	mass = PI * randf_range(15.0, 35.0) ** 2
	super._ready()
	got_eaten.connect(_on_got_eaten)
	split_forced.connect(_on_force_split)
	_target_pos = _random_world_pos()


func _physics_process(delta: float) -> void:
	# 领导球消失时，从属球独立
	if group_leader != null and not is_instance_valid(group_leader):
		group_leader = null

	# ── 惯性飞出阶段 ──────────────────────────────────
	if launch_velocity.length() > 10.0:
		move_and_collide(launch_velocity * delta)
		launch_velocity = launch_velocity.lerp(Vector2.ZERO, GameConfig.AI_SPLIT_LAUNCH_DECEL * delta)
		clamp_to_world()
		merge_timer = maxf(0.0, merge_timer - delta)
		return

	# ── 合并检查（从属球）─────────────────────────────
	merge_timer = maxf(0.0, merge_timer - delta)
	if group_leader != null and merge_timer <= 0.0 and is_instance_valid(group_leader):
		var dist: float = global_position.distance_to(group_leader.global_position)
		if dist < group_leader.radius:
			_merge_into(group_leader)
			return

	# ── 从属球跟随领导球的目标 ─────────────────────────
	if group_leader != null:
		_target_pos = group_leader._target_pos
		state       = group_leader.state
		_move_toward(_target_pos, delta)
		clamp_to_world()
		return

	# ── 领导球逻辑 ────────────────────────────────────
	_state_timer += delta
	if _state_timer >= GameConfig.AI_STATE_INTERVAL:
		_state_timer = 0.0
		_evaluate_state()

	# 更新战术计时器
	match state:
		State.FLEE:
			_flee_timer += delta
			_hunt_timer  = 0.0
		State.HUNT:
			_hunt_timer += delta
			_flee_timer  = 0.0
		_:
			_flee_timer  = 0.0
			_hunt_timer  = 0.0
			_split_used  = false  # 切回游荡时重置标志，允许下次再分裂

	# 战术分裂判断
	if not _split_used and radius >= GameConfig.AI_MIN_SPLIT_RADIUS:
		var should_split := false
		if state == State.FLEE and _flee_timer >= GameConfig.AI_FLEE_SPLIT_TIME:
			should_split = true
		elif state == State.HUNT and _hunt_timer >= GameConfig.AI_HUNT_SPLIT_TIME:
			should_split = true
		if should_split:
			_split_used = true
			_do_ai_split()
			return

	_move_toward(_target_pos, delta)
	clamp_to_world()


func _evaluate_state() -> void:
	var balls: Array = get_tree().get_nodes_in_group("balls")
	var nearest_prey: Ball   = null
	var nearest_threat: Ball = null
	var prey_dist   := INF
	var threat_dist := INF

	for b in balls:
		if b == self or not is_instance_valid(b):
			continue
		var d: float = global_position.distance_to(b.global_position)
		var ball := b as Ball
		if can_eat(ball) and d < prey_dist:
			nearest_prey = ball
			prey_dist    = d
		elif ball.can_eat(self) and d < threat_dist:
			nearest_threat = ball
			threat_dist    = d

	if nearest_threat != null and threat_dist < radius * 8.0:
		state = State.FLEE
		var flee_dir := (global_position - nearest_threat.global_position).normalized()
		_target_pos = global_position + flee_dir * 400.0
	elif nearest_prey != null and prey_dist < radius * 10.0:
		state = State.HUNT
		_target_pos = nearest_prey.global_position
	else:
		state = State.FORAGE
		if global_position.distance_to(_target_pos) < 60.0:
			_target_pos = _random_world_pos()


func _do_ai_split() -> void:
	if radius < GameConfig.AI_MIN_SPLIT_RADIUS:
		return
	var half_mass := mass / 2.0
	_apply_mass(half_mass)

	var new_ai := AIBall.new()
	new_ai.group_leader  = group_leader if is_instance_valid(group_leader) else self
	new_ai.merge_timer   = GameConfig.AI_MERGE_DELAY
	new_ai.ball_color    = ball_color
	new_ai.ball_name     = ball_name
	new_ai.add_to_group("balls")
	get_parent().add_child(new_ai)
	new_ai.global_position = global_position
	new_ai._apply_mass(half_mass)

	# 分裂方向：朝当前目标射出
	var dir := (_target_pos - global_position).normalized() \
		if (_target_pos - global_position).length() > 10.0 else Vector2.RIGHT
	new_ai.launch_velocity = dir * GameConfig.AI_SPLIT_LAUNCH_SPEED
	new_ai.play_spawn_anim()
	play_pulse_anim()


func _merge_into(target: AIBall) -> void:
	target._apply_mass(target.mass + mass)
	queue_free()


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


func _on_force_split() -> void:
	# 炸弹强制分裂，无论领导/从属皆可触发（若体积够大）
	_split_used = true
	_do_ai_split()


func _on_got_eaten(_by: Ball) -> void:
	queue_free()
