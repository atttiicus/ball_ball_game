## 联网球：继承自 Ball，通过 RPC 同步状态
class_name NetworkedBall
extends Ball

var peer_id: int = 1  # 控制此球的玩家 peer id

# 插值缓冲
var _remote_pos: Vector2 = Vector2.ZERO
var _remote_mass: float = 0.0
var _interp_speed: float = 12.0


func _ready() -> void:
	super._ready()


func _physics_process(delta: float) -> void:
	if not multiplayer.has_multiplayer_peer():
		return

	if multiplayer.get_unique_id() == peer_id:
		# 本地控制
		_move_toward_mouse(delta)
		clamp_to_world()
		# 定时广播状态（~20Hz）
		if Engine.get_physics_frames() % 3 == 0:
			_sync_state.rpc(global_position, mass)
	else:
		# 远端插值
		global_position = global_position.lerp(_remote_pos, _interp_speed * delta)
		if abs(mass - _remote_mass) > 1.0:
			_apply_mass(_remote_mass)


func _move_toward_mouse(delta: float) -> void:
	var target := get_global_mouse_position()
	var dir := target - global_position
	if dir.length() < radius * 0.5:
		velocity = Vector2.ZERO
		return
	velocity = dir.normalized() * get_speed()
	move_and_collide(velocity * delta)


@rpc("any_peer", "unreliable_ordered")
func _sync_state(pos: Vector2, m: float) -> void:
	if multiplayer.get_remote_sender_id() != peer_id:
		return
	_remote_pos = pos
	_remote_mass = m


# 权威服务端：吞噬只由服务端判定并广播
func server_eat(other_id: int) -> void:
	if not multiplayer.is_server():
		return
	_rpc_eat.rpc(other_id)


@rpc("authority", "reliable")
func _rpc_eat(other_peer_id: int) -> void:
	# 找到对应球并吞噬
	var other := _find_ball_by_peer(other_peer_id)
	if other and can_eat(other):
		_eat_ball(other)


func _find_ball_by_peer(pid: int) -> NetworkedBall:
	for b in get_tree().get_nodes_in_group("balls"):
		if b is NetworkedBall and (b as NetworkedBall).peer_id == pid:
			return b
	return null
