class_name GameCamera
extends Camera2D

# 单人模式：跟随 target
# 双人模式：targets 非空时包含所有目标
var target: Ball = null
var targets: Array[Ball] = []

const ZOOM_MIN := 0.25
const ZOOM_MAX := 1.2
const RADIUS_FOR_MIN_ZOOM := 250.0
const RADIUS_FOR_MAX_ZOOM := 20.0
const ZOOM_SMOOTH := 3.0
const FOLLOW_SMOOTH := 8.0
const PADDING := 150.0  # 双人模式视野边距


func _ready() -> void:
	position_smoothing_enabled = false


func _process(delta: float) -> void:
	var live_targets := targets.filter(func(b): return is_instance_valid(b))

	if live_targets.size() >= 2:
		_follow_multiple(live_targets, delta)
	elif is_instance_valid(target):
		_follow_single(target, delta)


func _follow_single(t: Ball, delta: float) -> void:
	global_position = global_position.lerp(t.global_position, FOLLOW_SMOOTH * delta)
	var pct := inverse_lerp(RADIUS_FOR_MAX_ZOOM, RADIUS_FOR_MIN_ZOOM, t.radius)
	var tz := lerpf(ZOOM_MAX, ZOOM_MIN, clampf(pct, 0.0, 1.0))
	zoom = zoom.lerp(Vector2(tz, tz), ZOOM_SMOOTH * delta)


func _follow_multiple(ts: Array, delta: float) -> void:
	# 中心点
	var center := Vector2.ZERO
	for t in ts:
		center += (t as Ball).global_position
	center /= ts.size()
	global_position = global_position.lerp(center, FOLLOW_SMOOTH * delta)

	# 缩放：让所有玩家都在视野内
	var viewport_size := get_viewport_rect().size
	var max_dist := 0.0
	for t in ts:
		max_dist = maxf(max_dist, center.distance_to((t as Ball).global_position))
	var needed := (max_dist + PADDING) * 2.0
	var target_zoom := minf(viewport_size.x / needed, viewport_size.y / needed)
	target_zoom = clampf(target_zoom, ZOOM_MIN, ZOOM_MAX)
	zoom = zoom.lerp(Vector2(target_zoom, target_zoom), ZOOM_SMOOTH * delta)
