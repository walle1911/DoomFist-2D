extends Node2D

@export var projectile_scene: PackedScene
@export var direction: Vector2 = Vector2.LEFT
@export var fire_interval: float = 1.5
@export var first_shot_delay: float = 0.3
@export var projectile_spawn_offset: float = 12.0
@export var max_projectile_spawn_offset: float = 48.0
@export var projectile_spawn_clearance_step: float = 4.0

var fire_timer: float = 0.0


func _ready() -> void:
	add_to_group("respawn_reset")
	reset_on_respawn()


func _physics_process(delta: float) -> void:
	fire_timer -= delta

	if fire_timer <= 0.0:
		fire()
		fire_timer = max(fire_interval, 0.001)


func fire() -> void:
	if projectile_scene == null:
		return

	var fire_direction := get_fire_direction()
	var projectile := projectile_scene.instantiate()
	var projectile_2d := projectile as Node2D
	get_parent().add_child(projectile)

	if projectile_2d != null:
		projectile_2d.global_position = get_projectile_spawn_position(projectile_2d, fire_direction)

	if projectile.has_method("setup"):
		projectile.setup(fire_direction)


func reset_on_respawn() -> void:
	fire_timer = max(first_shot_delay, 0.0)


func get_fire_direction() -> Vector2:
	if direction.is_zero_approx():
		return Vector2.LEFT

	return direction.normalized()


func get_projectile_spawn_position(projectile: Node2D, fire_direction: Vector2) -> Vector2:
	var start_offset: float = max(projectile_spawn_offset, 0.0)
	var end_offset: float = max(max_projectile_spawn_offset, start_offset)
	var step: float = max(projectile_spawn_clearance_step, 1.0)
	var current_offset: float = start_offset

	while current_offset <= end_offset:
		var candidate_position: Vector2 = global_position + fire_direction * current_offset

		if is_spawn_position_clear(projectile, candidate_position):
			return candidate_position

		current_offset += step

	return global_position + fire_direction * end_offset


func is_spawn_position_clear(projectile: Node2D, candidate_position: Vector2) -> bool:
	var collision_shape := projectile.get_node_or_null("CollisionShape2D") as CollisionShape2D

	if collision_shape == null or collision_shape.shape == null or collision_shape.disabled:
		return true

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = collision_shape.shape
	query.transform = Transform2D(collision_shape.rotation, candidate_position + collision_shape.position)
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var collision_object := projectile as CollisionObject2D
	if collision_object != null:
		query.collision_mask = collision_object.collision_mask

	var hits := get_world_2d().direct_space_state.intersect_shape(query, 16)

	for hit in hits:
		var collider := hit.get("collider") as Node

		if is_spawn_blocker(collider):
			return false

	return true


func is_spawn_blocker(collider: Node) -> bool:
	if collider == null:
		return false

	if collider.has_method("apply_sleep"):
		return false
	if collider.has_method("apply_knockback"):
		return false
	if collider.has_method("apply_flash"):
		return false
	if collider.has_method("apply_chain_hold"):
		return false

	return true
