extends Area2D

@export var speed: float = 220.0
@export var knockback_speed: float = 360.0
@export var knockback_duration: float = 0.25
@export var life_time: float = 5.0

var direction: Vector2 = Vector2.LEFT


func _ready() -> void:
	add_to_group("respawn_clear")
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

	life_time -= delta
	if life_time <= 0.0:
		queue_free()


func setup(new_direction: Vector2) -> void:
	direction = new_direction.normalized()


func _on_body_entered(body: Node) -> void:
	if body.has_method("apply_knockback"):
		body.apply_knockback(direction, knockback_speed, knockback_duration)
		queue_free()


func on_blocked(_blocker: Node) -> void:
	queue_free()
