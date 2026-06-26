extends Node2D

const WORLD_SIZE := Vector2(4000.0, 4000.0)
const WALL_THICKNESS := 50.0

const PlayerScene       := preload("res://scenes/Player.tscn")
const Player2Scene      := preload("res://scenes/Player2.tscn")
const NetworkedBallScene := preload("res://scenes/NetworkedBall.tscn")

var background: Node2D
var food_container: Node2D
var ball_container: Node2D
var world_border: Node2D
var camera: GameCamera
var player: Player
var player2: Player2
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
	world_border = $WorldBorder

	_build_world_border()
	_setup_background()
	_setup_food_spawner()
	_setup_ai_spawner()
	_show_main_menu()


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	var balls := ball_container.get_children()
	for ball in balls:
		if is_instance_valid(ball):
			(ball as Ball).check_ball_collisions(balls)
	_peak_mass = maxf(_peak_mass, player.mass)


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

	if multiplayer.has_multiplayer_peer():
		NetworkManager.local_player_info["color"] = color
		_spawn_online_players(player_name)
	else:
		_spawn_player(player_name, color)
		if two_player:
			_spawn_player2()

	_setup_camera()
	_setup_hud()


func _spawn_online_players(player_name: String) -> void:
	# 为每个已连接玩家（含自己）生成 NetworkedBall
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
			player = nb  # 把本地 NetworkedBall 当 player 对待
			player.got_eaten.connect(_on_player_died)

	# 监听后续玩家加入/离开
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
	# 断线回主菜单
	for b in ball_container.get_children():
		b.queue_free()
	_show_main_menu()


func _spawn_player(player_name: String = "Player", color: Color = Color(0.2, 0.6, 1.0)) -> void:
	player = PlayerScene.instantiate()
	player.ball_name = player_name
	player.ball_color = color
	player.global_position = WORLD_SIZE / 2.0 + Vector2(-200, 0)
	player.add_to_group("balls")
	player.got_eaten.connect(_on_player_died)
	ball_container.add_child(player)


func _spawn_player2() -> void:
	player2 = Player2Scene.instantiate()
	player2.global_position = WORLD_SIZE / 2.0 + Vector2(200, 0)
	player2.add_to_group("balls")
	player2.got_eaten.connect(_on_player2_died)
	ball_container.add_child(player2)


func _setup_camera() -> void:
	if not is_instance_valid(camera):
		camera = GameCamera.new()
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(WORLD_SIZE.x)
		camera.limit_bottom = int(WORLD_SIZE.y)
		add_child(camera)

	camera.target = player
	if _two_player and is_instance_valid(player2):
		camera.targets = [player, player2]
	else:
		camera.targets = []
	camera.global_position = player.global_position


func _setup_hud() -> void:
	if is_instance_valid(hud):
		hud.player_ref = player
		return
	hud = HUD.new()
	hud.player_ref = player
	add_child(hud)


# ── 死亡处理 ───────────────────────────────────────────

func _on_player_died(_by: Ball) -> void:
	var survived := Time.get_ticks_msec() / 1000.0 - _start_time
	var rank := _calc_rank()

	if is_instance_valid(hud):
		hud.queue_free()
		hud = null

	var ds := DeathScreen.new()
	add_child(ds)
	ds.show_result(survived, _peak_mass, rank)
	ds.respawn.connect(_on_respawn)


func _on_player2_died(_by: Ball) -> void:
	# P2 死亡后不弹出结算，只从摄像机目标列表移除
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
