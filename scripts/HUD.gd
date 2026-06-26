class_name HUD
extends CanvasLayer

var player_ref: Ball = null

var _mass_label: Label
var _leaderboard: VBoxContainer
var _minimap: Control

const LEADERBOARD_COUNT := 10


func _ready() -> void:
	layer = 10
	_build_ui()


func _build_ui() -> void:
	# 左下角：玩家质量
	_mass_label = Label.new()
	_mass_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_mass_label.position = Vector2(16, -48)
	_mass_label.add_theme_font_size_override("font_size", 20)
	_mass_label.add_theme_color_override("font_color", Color.WHITE)
	_mass_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_mass_label.add_theme_constant_override("shadow_offset_x", 1)
	_mass_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_mass_label)

	# 左上角：操作提示
	var hints_panel := PanelContainer.new()
	hints_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	hints_panel.position = Vector2(10, 10)
	add_child(hints_panel)

	var hints_vbox := VBoxContainer.new()
	hints_panel.add_child(hints_vbox)

	for line in ["WASD  移动", "空格  分裂", "ESC   暂停"]:
		var lbl := Label.new()
		lbl.text = line
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		hints_vbox.add_child(lbl)

	# 右上角：排行榜
	var lb_panel := PanelContainer.new()
	lb_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	lb_panel.position = Vector2(-210, 10)
	lb_panel.custom_minimum_size = Vector2(200, 0)
	add_child(lb_panel)

	var vbox := VBoxContainer.new()
	lb_panel.add_child(vbox)

	var title := Label.new()
	title.text = "排行榜"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)

	_leaderboard = VBoxContainer.new()
	vbox.add_child(_leaderboard)

	# 右下角：小地图
	_minimap = Minimap.new()
	_minimap.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_minimap.position = Vector2(-170, -170)
	_minimap.custom_minimum_size = Vector2(160, 160)
	add_child(_minimap)


func _process(_delta: float) -> void:
	_update_mass_label()
	_update_leaderboard()
	if _minimap and _minimap.has_method("refresh"):
		var ref := player_ref if is_instance_valid(player_ref) else null
		_minimap.call("refresh", ref)


func _update_mass_label() -> void:
	# 累加所有分裂块的总质量
	var cells := get_tree().get_nodes_in_group("player_cells")
	if cells.is_empty():
		_mass_label.text = ""
		return
	var total := 0.0
	for c in cells:
		if is_instance_valid(c):
			total += (c as Ball).mass
	_mass_label.text = "质量：%d" % int(total)


func _update_leaderboard() -> void:
	var balls := get_tree().get_nodes_in_group("balls")
	balls.sort_custom(func(a, b): return (a as Ball).mass > (b as Ball).mass)

	# 补齐或裁剪标签
	while _leaderboard.get_child_count() < LEADERBOARD_COUNT:
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 12)
		_leaderboard.add_child(lbl)

	for i in LEADERBOARD_COUNT:
		var lbl := _leaderboard.get_child(i) as Label
		if i < balls.size():
			var b := balls[i] as Ball
			var prefix := "▶ " if b is Player else "  "
			lbl.text = "%s%d. %s  %d" % [prefix, i + 1, b.ball_name, int(b.mass)]
			lbl.modulate = Color(1.0, 0.9, 0.3) if b is Player else Color.WHITE
		else:
			lbl.text = ""
