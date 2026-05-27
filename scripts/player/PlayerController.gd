extends CharacterBody2D

const ACTION_MOVE_LEFT := "move_left"
const ACTION_MOVE_RIGHT := "move_right"
const ACTION_JUMP := "jump"
const ACTION_RESTART := "restart"

@export var move_speed: float = 120.0
@export var ground_accel: float = 1200.0
@export var ground_decel: float = 1600.0
@export var air_accel: float = 840.0
@export var jump_velocity: float = -520.0
@export var gravity: float = 1800.0
@export var max_fall_speed: float = 420.0

@export var coyote_time: float = 0.08
@export var jump_buffer_time: float = 0.10

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

var spawn_position: Vector2

func _ready() -> void:
	spawn_position = global_position

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed(ACTION_RESTART):
		respawn()

	handle_timers(delta)
	handle_horizontal_movement(delta)
	handle_gravity(delta)
	handle_jump()

	move_and_slide()

func handle_timers(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)

	if Input.is_action_just_pressed(ACTION_JUMP):
		jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)

func handle_horizontal_movement(delta: float) -> void:
	var direction := get_horizontal_direction()
	var target_speed := direction * move_speed

	var accel := ground_accel
	if not is_on_floor():
		accel = air_accel
	elif direction == 0:
		accel = ground_decel

	velocity.x = move_toward(velocity.x, target_speed, accel * delta)

func handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_fall_speed)
	elif velocity.y > 0:
		velocity.y = 0

func handle_jump() -> void:
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

func get_horizontal_direction() -> float:
	var direction := Input.get_axis(ACTION_MOVE_LEFT, ACTION_MOVE_RIGHT)
	if direction != 0.0:
		return direction

	var keyboard_direction := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		keyboard_direction -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		keyboard_direction += 1.0
	return keyboard_direction

func respawn() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
