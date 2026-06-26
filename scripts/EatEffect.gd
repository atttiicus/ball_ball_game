## 吞噬粒子特效（程序化，无需资源文件）
class_name EatEffect
extends Node2D

static func spawn(parent: Node, pos: Vector2, color: Color, radius: float) -> void:
	var fx := EatEffect.new()
	fx.global_position = pos
	parent.add_child(fx)
	fx._burst(color, radius)


var _particles: Array = []
var _lifetime: float = 0.45


func _burst(color: Color, radius: float) -> void:
	var count := int(clampf(radius / 5.0, 6, 24))
	for i in count:
		var angle := (float(i) / count) * TAU
		var speed := randf_range(radius * 1.2, radius * 2.5)
		var vel := Vector2(cos(angle), sin(angle)) * speed
		_particles.append({
			"pos": Vector2.ZERO,
			"vel": vel,
			"r": randf_range(2.0, 6.0),
			"color": color.lightened(randf_range(0.0, 0.3)),
			"life": randf_range(0.25, _lifetime),
			"max_life": _lifetime,
		})


func _process(delta: float) -> void:
	var alive := false
	for p in _particles:
		p["life"] -= delta
		if p["life"] > 0.0:
			p["pos"] += p["vel"] * delta
			p["vel"] = p["vel"].lerp(Vector2.ZERO, delta * 4.0)
			alive = true
	queue_redraw()
	if not alive:
		queue_free()


func _draw() -> void:
	for p in _particles:
		if p["life"] <= 0.0:
			continue
		var alpha := clampf(p["life"] / p["max_life"], 0.0, 1.0)
		var c: Color = p["color"]
		c.a = alpha
		draw_circle(p["pos"], p["r"] * alpha, c)
