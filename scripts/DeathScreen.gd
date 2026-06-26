class_name DeathScreen
extends CanvasLayer

signal respawn

var _info_label: Label


func _ready() -> void:
	layer = 20
	_build_ui()


func show_result(survived_seconds: float, peak_mass: float, rank: int) -> void:
	_info_label.text = (
		"存活时间：%s\n最大质量：%d\n最终排名：第 %d 名" % [
			_fmt_time(survived_seconds), int(peak_mass), rank
		]
	)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.7)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(340, 0)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	var title := Label.new()
	title.text = "你被吃掉了！"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	vbox.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	_info_label = Label.new()
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_info_label)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 24)
	vbox.add_child(spacer2)

	var btn := Button.new()
	btn.text = "再来一局"
	btn.custom_minimum_size = Vector2(0, 44)
	btn.pressed.connect(func():
		emit_signal("respawn")
		queue_free()
	)
	vbox.add_child(btn)


func _fmt_time(secs: float) -> String:
	var m := int(secs) / 60
	var s := int(secs) % 60
	return "%02d:%02d" % [m, s]
