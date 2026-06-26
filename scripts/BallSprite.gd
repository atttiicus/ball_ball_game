class_name BallSprite
extends Node2D

# 由父节点 Ball 设置 meta("ball")


func _draw() -> void:
	var ball: Ball = get_meta("ball", null)
	if not ball:
		return
	var r: float = ball.radius
	var c: Color = ball.ball_color

	# 主体
	draw_circle(Vector2.ZERO, r, c)

	# 高光
	var highlight := c.lightened(0.35)
	highlight.a = 0.6
	draw_circle(Vector2(-r * 0.28, -r * 0.28), r * 0.3, highlight)

	# 轮廓
	var outline := c.darkened(0.25)
	draw_arc(Vector2.ZERO, r, 0, TAU, 48, outline, 2.0)
