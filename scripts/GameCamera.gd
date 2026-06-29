class_name GameCamera
extends Camera2D

var target: Ball = null
var targets: Array[Ball] = []


func _ready() -> void:
	position_smoothing_enabled = false


func _process(delta: float) -> void:
	var live_targets := targets.filter(func(b): return is_instance_valid(b))
	if live_targets.size() >= 2:
		_follow_multiple(live_targets, delta)
	elif is_instance_valid(target):
		_follow_single(target, delta)


func _follow_single(t: Ball, delta: float) -> void:
	global_position = global_position.lerp(
		t.global_position, GameConfig.CAM_FOLLOW_SMOOTH * delta)
	var pct := inverse_lerp(
		GameConfig.CAM_RADIUS_FOR_MAX_ZOOM, GameConfig.CAM_RADIUS_FOR_MIN_ZOOM, t.radius)
	var tz := lerpf(GameConfig.CAM_ZOOM_MAX, GameConfig.CAM_ZOOM_MIN, clampf(pct, 0.0, 1.0))
	zoom = zoom.lerp(Vector2(tz, tz), GameConfig.CAM_ZOOM_SMOOTH * delta)


func _follow_multiple(ts: Array, delta: float) -> void:
	var center := Vector2.ZERO
	for t in ts:
		center += (t as Ball).global_position
	center /= ts.size()
	global_position = global_position.lerp(center, GameConfig.CAM_FOLLOW_SMOOTH * delta)

	var viewport_size := get_viewport_rect().size
	var max_dist := 0.0
	for t in ts:
		max_dist = maxf(max_dist, center.distance_to((t as Ball).global_position))
	var needed := (max_dist + GameConfig.CAM_MULTI_PADDING) * 2.0
	var target_zoom := minf(viewport_size.x / needed, viewport_size.y / needed)
	target_zoom = clampf(target_zoom, GameConfig.CAM_ZOOM_MIN, GameConfig.CAM_ZOOM_MAX)
	zoom = zoom.lerp(Vector2(target_zoom, target_zoom), GameConfig.CAM_ZOOM_SMOOTH * delta)
