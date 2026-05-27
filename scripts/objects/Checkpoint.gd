extends Area2D

@onready var spawn_point: Marker2D = $SpawnPoint

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.has_method("set_checkpoint"):
		body.set_checkpoint(spawn_point.global_position)
