extends Area2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var used: bool = false

func _ready() -> void:
	add_to_group("respawn_reset")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if used:
		return

	if body.has_method("refresh_normal_skills"):
		body.refresh_normal_skills()
		used = true
		hide_bell()


func hide_bell() -> void:
	visible = false
	collision_shape.set_deferred("disabled", true)


func reset_on_respawn() -> void:
	used = false
	visible = true
	collision_shape.set_deferred("disabled", false)
