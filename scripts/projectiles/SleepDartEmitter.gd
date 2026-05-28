extends Node2D

@export var dart_scene: PackedScene
@export var direction: Vector2 = Vector2.LEFT
@export var fire_interval: float = 1.5
@export var first_shot_delay: float = 0.3

var fire_timer: float = 0.0


func _ready() -> void:
	add_to_group("respawn_reset")
	fire_timer = first_shot_delay


func _physics_process(delta: float) -> void:
	fire_timer -= delta

	if fire_timer <= 0.0:
		fire()
		fire_timer = fire_interval


func fire() -> void:
	if dart_scene == null:
		print("SleepDartEmitter: dart_scene is null")
		return

	var dart := dart_scene.instantiate()
	get_parent().add_child(dart)

	dart.global_position = global_position

	if dart.has_method("set_direction"):
		dart.set_direction(direction)
	else:
		dart.direction = direction.normalized()


func reset_on_respawn() -> void:
	fire_timer = first_shot_delay
