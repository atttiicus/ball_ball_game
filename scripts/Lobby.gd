class_name Lobby
extends CanvasLayer

signal start_online(player_name: String, is_host: bool, address: String)
signal back_to_menu

var _name_input: LineEdit
var _address_input: LineEdit
var _status_label: Label


func _ready() -> void:
	layer = 20
	_build_ui()
	NetworkManager.player_connected.connect(_on_player_update)
	NetworkManager.player_disconnected.connect(_on_player_update)
	NetworkManager.connection_failed.connect(_on_fail)
	NetworkManager.server_disconnected.connect(_on_fail)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.12, 0.96)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(360, 0)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "联网多人"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	vbox.add_child(title)

	_add_spacer(vbox, 20)

	_name_input = _make_input("昵称", "Player", vbox)
	_add_spacer(vbox, 8)
	_address_input = _make_input("服务器 IP（作为客户端时填写）", "127.0.0.1", vbox)
	_add_spacer(vbox, 16)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	var host_btn := Button.new()
	host_btn.text = "创建房间（主机）"
	host_btn.custom_minimum_size = Vector2(160, 44)
	host_btn.pressed.connect(_on_host)
	hbox.add_child(host_btn)

	_add_spacer_h(hbox, 12)

	var join_btn := Button.new()
	join_btn.text = "加入房间"
	join_btn.custom_minimum_size = Vector2(160, 44)
	join_btn.pressed.connect(_on_join)
	hbox.add_child(join_btn)

	_add_spacer(vbox, 12)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.4))
	vbox.add_child(_status_label)

	_add_spacer(vbox, 12)

	var back_btn := Button.new()
	back_btn.text = "返回"
	back_btn.custom_minimum_size = Vector2(0, 36)
	back_btn.pressed.connect(func():
		NetworkManager.disconnect_from_game()
		emit_signal("back_to_menu")
		queue_free()
	)
	vbox.add_child(back_btn)


func _on_host() -> void:
	NetworkManager.local_player_info["name"] = _get_name()
	var err := NetworkManager.host_game()
	if err != OK:
		_status_label.text = "创建房间失败：%d" % err
		return
	_status_label.text = "房间已创建，等待玩家加入..."
	_begin_game(true)


func _on_join() -> void:
	NetworkManager.local_player_info["name"] = _get_name()
	var addr := _address_input.text.strip_edges()
	var err := NetworkManager.join_game(addr)
	if err != OK:
		_status_label.text = "连接失败：%d" % err
		return
	_status_label.text = "正在连接 %s ..." % addr


func _begin_game(is_host: bool) -> void:
	emit_signal("start_online", _get_name(), is_host, _address_input.text.strip_edges())
	queue_free()


func _on_player_update(_a = null, _b = null) -> void:
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		_status_label.text = "房间人数：%d / %d" % [NetworkManager.players.size(), NetworkManager.MAX_PLAYERS]


func _on_fail(_a = null) -> void:
	_status_label.text = "连接断开或失败，请重试"


func _get_name() -> String:
	var n := _name_input.text.strip_edges()
	return n if not n.is_empty() else "Player"


func _make_input(hint: String, default_text: String, parent: Control) -> LineEdit:
	var lbl := Label.new()
	lbl.text = hint
	lbl.add_theme_font_size_override("font_size", 12)
	parent.add_child(lbl)
	var le := LineEdit.new()
	le.text = default_text
	le.custom_minimum_size = Vector2(0, 36)
	parent.add_child(le)
	return le


func _add_spacer(parent: Control, h: int) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	parent.add_child(s)


func _add_spacer_h(parent: Control, w: int) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(w, 0)
	parent.add_child(s)
