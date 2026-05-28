@tool
extends StaticBody2D

@export var platform_size: Vector2 = Vector2(160, 32):
	set(value):
		platform_size = Vector2(max(value.x, 1.0), max(value.y, 1.0))
		update_platform()

@export var platform_color: Color = Color(0.4, 0.4, 0.4, 1.0):
	set(value):
		platform_color = value
		update_platform()


func _ready() -> void:
	update_platform()


func update_platform() -> void:
	var collision_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	var polygon := get_node_or_null("Polygon2D") as Polygon2D

	if collision_shape == null or polygon == null:
		return

	var rect_shape := collision_shape.shape as RectangleShape2D

	if rect_shape == null:
		rect_shape = RectangleShape2D.new()
		collision_shape.shape = rect_shape

	rect_shape.size = platform_size
	collision_shape.position = Vector2.ZERO

	var half_size := platform_size / 2.0

	polygon.polygon = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y)
	])

	polygon.position = Vector2.ZERO
	polygon.color = platform_color
