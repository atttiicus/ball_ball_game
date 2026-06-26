## 皮肤选择面板，嵌入主菜单
class_name SkinSelector
extends HBoxContainer

signal color_selected(color: Color)

const PRESET_COLORS := [
	Color(0.2, 0.6, 1.0),   # 蓝
	Color(1.0, 0.35, 0.35),  # 红
	Color(0.3, 0.85, 0.4),   # 绿
	Color(1.0, 0.75, 0.15),  # 黄
	Color(0.85, 0.3, 1.0),   # 紫
	Color(1.0, 0.5, 0.1),    # 橙
	Color(0.2, 0.9, 0.9),    # 青
	Color(1.0, 0.4, 0.7),    # 粉
]

var selected_color: Color = PRESET_COLORS[0]
var _buttons: Array[Button] = []


func _ready() -> void:
	for c in PRESET_COLORS:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(32, 32)
		var style := StyleBoxFlat.new()
		style.bg_color = c
		style.corner_radius_top_left = 16
		style.corner_radius_top_right = 16
		style.corner_radius_bottom_left = 16
		style.corner_radius_bottom_right = 16
		btn.add_theme_stylebox_override("normal", style)
		btn.pressed.connect(func(): _select(c, btn))
		add_child(btn)
		_buttons.append(btn)

	_select(selected_color, _buttons[0])


func _select(c: Color, active_btn: Button) -> void:
	selected_color = c
	for btn in _buttons:
		btn.modulate = Color(0.6, 0.6, 0.6) if btn != active_btn else Color.WHITE
	emit_signal("color_selected", c)
