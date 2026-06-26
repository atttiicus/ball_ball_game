## 单例：res://scripts/NetworkManager.gd
## 在 project.godot 中注册为 autoload: NetworkManager
extends Node

signal player_connected(peer_id: int, info: Dictionary)
signal player_disconnected(peer_id: int)
signal server_disconnected
signal connection_failed

const PORT := 7777
const MAX_PLAYERS := 8

# peer_id -> { name, color }
var players: Dictionary = {}
var local_player_info: Dictionary = { "name": "Player", "color": Color(0.2, 0.6, 1.0) }


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


# ── 主机 ──────────────────────────────────────────────

func host_game() -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_PLAYERS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	players[1] = local_player_info
	return OK


# ── 客户端 ────────────────────────────────────────────

func join_game(address: String) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, PORT)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	return OK


func disconnect_from_game() -> void:
	multiplayer.multiplayer_peer = null
	players.clear()


# ── 信号处理 ──────────────────────────────────────────

func _on_peer_connected(id: int) -> void:
	# 主机广播已有玩家信息给新人
	if multiplayer.is_server():
		for pid in players:
			_register_player.rpc_id(id, pid, players[pid])
	# 把自己的信息发给新人（主机发给所有人）
	_register_player.rpc_id(id, multiplayer.get_unique_id(), local_player_info)


func _on_peer_disconnected(id: int) -> void:
	players.erase(id)
	emit_signal("player_disconnected", id)


func _on_connected_to_server() -> void:
	# 向服务端注册自己
	_register_player.rpc_id(1, multiplayer.get_unique_id(), local_player_info)


func _on_connection_failed() -> void:
	multiplayer.multiplayer_peer = null
	emit_signal("connection_failed")


func _on_server_disconnected() -> void:
	multiplayer.multiplayer_peer = null
	players.clear()
	emit_signal("server_disconnected")


# ── RPC ──────────────────────────────────────────────

@rpc("any_peer", "reliable")
func _register_player(id: int, info: Dictionary) -> void:
	players[id] = info
	emit_signal("player_connected", id, info)
