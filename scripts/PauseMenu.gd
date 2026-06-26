class_name PauseMenu
extends CanvasLayer


func _ready() -> void:
	layer = 30
	# 即使游戏暂停也能响应输入和绘制
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle()


func _toggle() -> void:
	if visible:
		_resume()
	else:
		show()
		get_tree().paused = true


func _resume() -> void:
	hide()
	get_tree().paused = false


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.65)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(280, 0)
	vbox.process_mode = Node.PROCESS_MODE_ALWAYS
	center.add_child(vbox)

	var title := Label.new()
	title.text = "暂停"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	_add_spacer(vbox, 28)

	var resume_btn := _make_btn("继续游戏")
	resume_btn.pressed.connect(_resume)
	vbox.add_child(resume_btn)

	_add_spacer(vbox, 10)

	var menu_btn := _make_btn("返回主菜单")
	menu_btn.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	vbox.add_child(menu_btn)

	_add_spacer(vbox, 10)

	var quit_btn := _make_btn("退出游戏")
	quit_btn.pressed.connect(func(): get_tree().quit())
	vbox.add_child(quit_btn)


func _make_btn(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 46)
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	return btn


func _add_spacer(parent: Control, h: int) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	parent.add_child(s)
