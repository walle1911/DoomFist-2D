extends StaticBody2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var polygon: Polygon2D = $Polygon2D

var broken: bool = false

func _ready() -> void:
	add_to_group("breakable_wall")
	add_to_group("respawn_reset")


func break_wall() -> void:
	if broken:
		return

	broken = true
	visible = false
	collision_shape.set_deferred("disabled", true)


func reset_on_respawn() -> void:
	broken = false
	visible = true
	collision_shape.set_deferred("disabled", false)
