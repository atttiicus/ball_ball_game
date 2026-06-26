extends Node2D

const WORLD_SIZE := Vector2(4000.0, 4000.0)
const WALL_THICKNESS := 50.0
const MAX_PLAYER_CELLS := 4

const PlayerScene        := preload("res://scenes/Player.tscn")
const Player2Scene       := preload("res://scenes/Player2.tscn")
const NetworkedBallScene := preload("res://scenes/NetworkedBall.tscn")

var background: Node2D
var food_container: Node2D
var ball_container: Node2D
var effects_container: Node2D
var world_border: Node2D
var camera: GameCamera
var player: Ball          # 主细胞（用于 HUD / 排名）
var player2: Ball
var player_cells: Array = []  # 所有玩家细胞
var food_spawner: FoodSpawner
var ai_spawner: AISpawner
var hud: HUD

var _two_player: bool = false
var _start_time: float = 0.0
var _peak_mass: float = 0.0


func _ready() -> void:
	background = $Background
	food_container = $FoodContainer
	ball_container = $BallContainer
	effects_container = $EffectsContainer
	world_border = $WorldBorder
	Ball.effects_node = effects_container

	_build_world_border()
	_setup_background()
	_setup_food_spawner()
	_setup_ai_spawner()
	_show_main_menu()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	var balls := ball_container.get_children()
	for ball in balls:
		if is_instance_valid(ball) and ball is Ball:
			(ball as Ball).check_ball_collisions(balls)

	_check_player_merges()

	# 统计所有细胞的总质量
	var total := 0.0
	for c in player_cells:
		if is_instance_valid(c):
			total += (c as Ball).mass
	_peak_mass = maxf(_peak_mass, total)


# ── 初始化 ───────────────────────────────────────────────

func _build_world_border() -> void:
	var walls := [
		[Vector2(WORLD_SIZE.x / 2, -WALL_THICKNESS / 2),               Vector2(WORLD_SIZE.x + WALL_THICKNESS * 2, WALL_THICKNESS)],
		[Vector2(WORLD_SIZE.x / 2, WORLD_SIZE.y + WALL_THICKNESS / 2),  Vector2(WORLD_SIZE.x + WALL_THICKNESS * 2, WALL_THICKNESS)],
		[Vector2(-WALL_THICKNESS / 2, WORLD_SIZE.y / 2),                Vector2(WALL_THICKNESS, WORLD_SIZE.y)],
		[Vector2(WORLD_SIZE.x + WALL_THICKNESS / 2, WORLD_SIZE.y / 2),  Vector2(WALL_THICKNESS, WORLD_SIZE.y)],
	]
	for wall_data in walls:
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = wall_data[1]
		shape.shape = rect
		body.position = wall_data[0]
		body.collision_layer = 2
		body.collision_mask = 1
		body.add_child(shape)
		world_border.add_child(body)


func _setup_background() -> void:
	var bg := BackgroundGrid.new()
	bg.world_size = WORLD_SIZE
	background.add_child(bg)


func _setup_food_spawner() -> void:
	food_spawner = FoodSpawner.new()
	food_spawner.world_size = WORLD_SIZE
	food_spawner.container = food_container
	add_child(food_spawner)


func _setup_ai_spawner() -> void:
	ai_spawner = AISpawner.new()
	ai_spawner.world_size = WORLD_SIZE
	ai_spawner.container = ball_container
	add_child(ai_spawner)


# ── 菜单 / 游戏启动 ────────────────────────────────────

func _show_main_menu() -> void:
	var menu := MainMenu.new()
	add_child(menu)
	menu.start_game.connect(_on_game_start)


func _on_game_start(player_name: String, two_player: bool, color: Color = Color(0.2, 0.6, 1.0)) -> void:
	_two_player = two_player
	_start_time = Time.get_ticks_msec() / 1000.0
	_peak_mass = 0.0

	if not NetworkManager.players.is_empty():
		NetworkManager.local_player_info["color"] = color
		_spawn_online_players(player_name)
	else:
		_spawn_player(player_name, color)
		if two_player:
			_spawn_player2()

	_setup_camera()
	_setup_hud()


func _spawn_online_players(player_name: String) -> void:
	var my_id := multiplayer.get_unique_id()
	for pid in NetworkManager.players:
		var info: Dictionary = NetworkManager.players[pid]
		var nb: NetworkedBall = NetworkedBallScene.instantiate()
		nb.peer_id = pid
		nb.ball_name = info.get("name", "Player")
		nb.ball_color = info.get("color", Color(0.5, 0.5, 1.0))
		nb.global_position = Vector2(
			randf_range(200, WORLD_SIZE.x - 200),
			randf_range(200, WORLD_SIZE.y - 200)
		)
		nb.add_to_group("balls")
		ball_container.add_child(nb)
		if pid == my_id:
			player = nb
			player.got_eaten.connect(_on_player_died)

	NetworkManager.player_connected.connect(_on_network_player_connected)
	NetworkManager.player_disconnected.connect(_on_network_player_disconnected)
	NetworkManager.server_disconnected.connect(_on_server_dc)


func _on_network_player_connected(pid: int, info: Dictionary) -> void:
	var nb: NetworkedBall = NetworkedBallScene.instantiate()
	nb.peer_id = pid
	nb.ball_name = info.get("name", "Player")
	nb.ball_color = info.get("color", Color(0.5, 0.5, 1.0))
	nb.global_position = Vector2(randf_range(200, WORLD_SIZE.x - 200), randf_range(200, WORLD_SIZE.y - 200))
	nb.add_to_group("balls")
	ball_container.add_child(nb)


func _on_network_player_disconnected(pid: int) -> void:
	for b in ball_container.get_children():
		if b is NetworkedBall and (b as NetworkedBall).peer_id == pid:
			b.queue_free()
			break


func _on_server_dc() -> void:
	for b in ball_container.get_children():
		b.queue_free()
	_show_main_menu()


func _spawn_player(player_name: String = "Player", color: Color = Color(0.2, 0.6, 1.0)) -> void:
	player_cells.clear()
	var cell: Player = PlayerScene.instantiate()
	cell.ball_name = player_name
	cell.ball_color = color
	cell.add_to_group("balls")
	_connect_cell(cell)
	ball_container.add_child(cell)
	cell.global_position = WORLD_SIZE / 2.0 + Vector2(-200, 0)
	cell._apply_mass(PI * 20.0 * 20.0)
	# 出生保护 3 秒：防止刚出生就被大球吃掉
	cell.is_invincible = true
	get_tree().create_timer(3.0).timeout.connect(func():
		if is_instance_valid(cell):
			cell.is_invincible = false
	)
	player = cell
	player_cells.append(cell)


func _spawn_player2() -> void:
	player2 = Player2Scene.instantiate()
	player2.add_to_group("balls")
	player2.got_eaten.connect(_on_player2_died)
	ball_container.add_child(player2)
	player2.global_position = WORLD_SIZE / 2.0 + Vector2(200, 0)


# ── 分裂 ──────────────────────────────────────────────

func _connect_cell(cell: Player) -> void:
	cell.got_eaten.connect(_on_cell_died.bind(cell))
	cell.split_requested.connect(_on_split_requested)


func _on_split_requested() -> void:
	if player_cells.size() >= MAX_PLAYER_CELLS:
		return
	for cell in player_cells.duplicate():
		if player_cells.size() >= MAX_PLAYER_CELLS:
			break
		if not is_instance_valid(cell):
			continue
		var p_cell := cell as Player
		if p_cell == null or p_cell.radius < Player.MIN_SPLIT_RADIUS:
			continue
		_split_cell(p_cell)


func _split_cell(cell: Player) -> void:
	var half_mass := cell.mass / 2.0
	cell._apply_mass(half_mass)
	cell.merge_timer = Player.MERGE_DELAY

	var new_cell: Player = PlayerScene.instantiate()
	new_cell.ball_name = cell.ball_name
	new_cell.ball_color = cell.ball_color
	new_cell.add_to_group("balls")
	_connect_cell(new_cell)
	ball_container.add_child(new_cell)
	new_cell.global_position = cell.global_position
	new_cell._apply_mass(half_mass)
	new_cell.launch_velocity = cell.last_move_dir * Player.LAUNCH_SPEED
	new_cell.merge_timer = Player.MERGE_DELAY

	player_cells.append(new_cell)
	_update_camera_targets()


# ── 合并 ──────────────────────────────────────────────

func _check_player_merges() -> void:
	player_cells = player_cells.filter(func(c): return is_instance_valid(c))
	if player_cells.size() < 2:
		return
	for i in player_cells.size():
		for j in range(i + 1, player_cells.size()):
			var c1 := player_cells[i] as Player
			var c2 := player_cells[j] as Player
			if c1 == null or c2 == null:
				continue
			if not c1.can_merge_with(c2):
				continue
			var dist := c1.global_position.distance_to(c2.global_position)
			if dist < c1.radius or dist < c2.radius:
				_merge_cells(c1, c2)
				return


func _merge_cells(c1: Player, c2: Player) -> void:
	var bigger  := c1 if c1.mass >= c2.mass else c2
	var smaller := c2 if c1.mass >= c2.mass else c1
	bigger._apply_mass(bigger.mass + smaller.mass)
	player_cells.erase(smaller)
	smaller.queue_free()
	if is_instance_valid(player_cells[0] if not player_cells.is_empty() else null):
		player = player_cells[0]
	_update_camera_targets()


# ── 摄像机 ────────────────────────────────────────────

func _update_camera_targets() -> void:
	if not is_instance_valid(camera):
		return
	var valid: Array[Ball] = []
	for c in player_cells:
		if is_instance_valid(c):
			valid.append(c)
	if valid.is_empty():
		return
	camera.target = valid[0]
	if valid.size() >= 2:
		camera.targets = valid
	else:
		camera.targets.clear()


func _setup_camera() -> void:
	if not is_instance_valid(camera):
		camera = GameCamera.new()
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(WORLD_SIZE.x)
		camera.limit_bottom = int(WORLD_SIZE.y)
		add_child(camera)
		camera.make_current()

	_update_camera_targets()
	if _two_player and is_instance_valid(player2):
		camera.targets = [player, player2]
	if is_instance_valid(player):
		camera.global_position = player.global_position


func _setup_hud() -> void:
	if is_instance_valid(hud):
		hud.player_ref = player
		return
	hud = HUD.new()
	hud.player_ref = player
	add_child(hud)
	# 暂停菜单（每局只创建一次）
	if not get_tree().current_scene.has_node("PauseMenu"):
		var pause_menu := PauseMenu.new()
		pause_menu.name = "PauseMenu"
		add_child(pause_menu)


# ── 死亡处理 ───────────────────────────────────────────

func _on_cell_died(_by: Ball, dead_cell: Ball) -> void:
	player_cells.erase(dead_cell)
	player_cells = player_cells.filter(func(c): return is_instance_valid(c))
	if player_cells.is_empty():
		_trigger_death()
	else:
		player = player_cells[0]
		_update_camera_targets()
		if is_instance_valid(hud):
			hud.player_ref = player


func _trigger_death() -> void:
	var survived := Time.get_ticks_msec() / 1000.0 - _start_time
	var rank := _calc_rank()
	if is_instance_valid(hud):
		hud.queue_free()
		hud = null
	var ds := DeathScreen.new()
	add_child(ds)
	ds.show_result(survived, _peak_mass, rank)
	ds.respawn.connect(_on_respawn)


func _on_player_died(_by: Ball) -> void:
	_trigger_death()


func _on_player2_died(_by: Ball) -> void:
	if is_instance_valid(camera):
		camera.targets = camera.targets.filter(func(b): return is_instance_valid(b))
		if camera.targets.is_empty():
			camera.target = player if is_instance_valid(player) else null


func _on_respawn() -> void:
	_start_time = Time.get_ticks_msec() / 1000.0
	_peak_mass = 0.0
	var pname := player.ball_name if is_instance_valid(player) else "Player"
	_spawn_player(pname)
	if _two_player:
		_spawn_player2()
	_setup_camera()
	_setup_hud()


func _calc_rank() -> int:
	var balls := get_tree().get_nodes_in_group("balls")
	balls.sort_custom(func(a, b): return (a as Ball).mass > (b as Ball).mass)
	for i in balls.size():
		if balls[i] is Player:
			return i + 1
	return balls.size() + 1
