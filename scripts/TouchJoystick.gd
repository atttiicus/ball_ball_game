## 移动端虚拟摇杆（仅在触摸设备显示）
class_name TouchJoystick
extends Control

var direction: Vector2 = Vector2.ZERO

const RADIUS := 60.0
const KNOB_RADIUS := 24.0
const BG_COLOR := Color(1, 1, 1, 0.25)
const KNOB_COLOR := Color(1, 1, 1, 0.55)

var _center: Vector2 = Vector2.ZERO
var _knob_pos: Vector2 = Vector2.ZERO
var _touch_index: int = -1
var _active: bool = false


func _ready() -> void:
	# 只在触摸设备上显示
	if not DisplayServer.is_touchscreen_available():
		hide()
		set_process_input(false)
		return

	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	custom_minimum_size = Vector2(180, 180)
	position = Vector2(20, -200)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var e := event as InputEventScreenTouch
		if e.pressed and not _active:
			_active = true
			_touch_index = e.index
			_center = e.position
			_knob_pos = _center
		elif not e.pressed and e.index == _touch_index:
			_active = false
			_touch_index = -1
			direction = Vector2.ZERO
			_knob_pos = _center
			queue_redraw()
	elif event is InputEventScreenDrag:
		var e := event as InputEventScreenDrag
		if _active and e.index == _touch_index:
			var offset := e.position - _center
			if offset.length() > RADIUS:
				offset = offset.normalized() * RADIUS
			_knob_pos = _center + offset
			direction = offset / RADIUS
			queue_redraw()


func _draw() -> void:
	if not _active:
		_center = Vector2(RADIUS + 20, size.y - RADIUS - 20)
		_knob_pos = _center

	draw_circle(_center, RADIUS, BG_COLOR)
	draw_arc(_center, RADIUS, 0, TAU, 36, Color(1, 1, 1, 0.4), 2.0)
	draw_circle(_knob_pos, KNOB_RADIUS, KNOB_COLOR)
