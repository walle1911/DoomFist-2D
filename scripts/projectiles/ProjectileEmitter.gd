extends Node2D

@export var projectile_scene: PackedScene
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
	if projectile_scene == null:
		return

	var projectile := projectile_scene.instantiate()
	get_parent().add_child(projectile)

	projectile.global_position = global_position

	if projectile.has_method("setup"):
		projectile.setup(direction.normalized())


func reset_on_respawn() -> void:
	fire_timer = first_shot_delay
