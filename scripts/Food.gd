class_name Food
extends Area2D

var food_mass: float = PI * GameConfig.FOOD_RADIUS * GameConfig.FOOD_RADIUS
var food_color: Color = Color.WHITE


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = GameConfig.FOOD_RADIUS
	shape.shape = circle
	add_child(shape)
	collision_layer = 4
	collision_mask = 0


func _draw() -> void:
	var r: float = GameConfig.FOOD_RADIUS
	draw_circle(Vector2.ZERO, r, food_color)
	var h := food_color.lightened(0.4)
	h.a = 0.7
	draw_circle(Vector2(-r * 0.25, -r * 0.25), r * 0.3, h)
