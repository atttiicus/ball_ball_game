class_name Food
extends Area2D

var food_mass: float = PI * 6.0 * 6.0  # 默认半径 6
var food_color: Color = Color.WHITE
const RADIUS := 6.0


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)

	collision_layer = 2
	collision_mask = 0


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, food_color)
	var h := food_color.lightened(0.4)
	h.a = 0.7
	draw_circle(Vector2(-RADIUS * 0.25, -RADIUS * 0.25), RADIUS * 0.3, h)
