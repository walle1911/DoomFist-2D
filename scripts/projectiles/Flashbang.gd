extends Area2D

@export var horizontal_speed: float = 180.0
@export var start_y_speed: float = -120.0
@export var arc_gravity: float = 800.0

@export var explode_delay: float = 0.45
@export var skill_lock_duration: float = 0.5
@export var slow_duration: float = 0.5
@export var slow_multiplier: float = 0.45

var direction: Vector2 = Vector2.LEFT
var velocity: Vector2 = Vector2.ZERO
var exploded: bool = false

@onready var explosion_area: Area2D = $ExplosionArea


func _ready() -> void:
	add_to_group("respawn_clear")
	body_entered.connect(_on_body_entered)
	setup(direction)


func _physics_process(delta: float) -> void:
	if exploded:
		return

	global_position += velocity * delta
	velocity.y += arc_gravity * delta

	explode_delay -= delta
	if explode_delay <= 0.0:
		explode()


func setup(new_direction: Vector2) -> void:
	var x_direction: float = signf(new_direction.x)

	if x_direction == 0.0:
		x_direction = -1.0

	direction = Vector2(x_direction, 0.0)
	velocity = Vector2(direction.x * horizontal_speed, start_y_speed)


func _on_body_entered(body: Node) -> void:
	explode(body)


func explode(extra_body: Node = null) -> void:
	if exploded:
		return

	exploded = true

	if extra_body != null and extra_body.has_method("apply_flash"):
		extra_body.apply_flash(skill_lock_duration, slow_duration, slow_multiplier)

	for body in explosion_area.get_overlapping_bodies():
		if body.has_method("apply_flash"):
			body.apply_flash(skill_lock_duration, slow_duration, slow_multiplier)

	queue_free()


func on_blocked(_blocker: Node) -> void:
	queue_free()
