extends Area2D

enum ChainState {
	WAITING,
	WARNING,
	EXTENDING,
	ACTIVE,
	HOLDING,
	RETRACTING,
}

@export var hold_duration: float = 1.2
@export var fire_interval: float = 1.4
@export var initial_fire_delay: float = 0.6
@export var warning_time: float = 0.2
@export var extend_time: float = 0.12
@export var active_time: float = 0.18
@export var retract_time: float = 0.10
@export var max_chain_length: float = 96.0
@export var chain_hitbox_thickness: float = 18.0
@export var chain_wait_color: Color = Color(0.15, 0.55, 0.7, 0.0)
@export var chain_warning_color: Color = Color(1.0, 0.2, 0.12, 0.7)
@export var chain_fire_color: Color = Color(0.75, 0.95, 1.0, 1.0)
@export var chain_hold_color: Color = Color(0.35, 0.75, 1.0, 1.0)

@onready var grab_point: Marker2D = $GrabPoint
@onready var chain_line: Line2D = $ChainLine
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var chained_target: Node2D = null
var chain_state: int = ChainState.WAITING
var state_timer: float = 0.0
var state_duration: float = 0.0


func _ready() -> void:
	add_to_group("respawn_reset")
	start_waiting(initial_fire_delay)


func _physics_process(delta: float) -> void:
	if state_timer > 0.0:
		state_timer = max(state_timer - delta, 0.0)

	match chain_state:
		ChainState.WAITING:
			update_waiting()
		ChainState.WARNING:
			update_warning()
		ChainState.EXTENDING:
			update_extending()
		ChainState.ACTIVE:
			update_active()
		ChainState.HOLDING:
			update_holding()
		ChainState.RETRACTING:
			update_retracting()


func update_waiting() -> void:
	if state_timer <= 0.0:
		start_warning()


func update_warning() -> void:
	if state_timer <= 0.0:
		start_extending()


func update_extending() -> void:
	var progress: float = get_state_progress()
	update_chain_progress(progress)

	if try_grab_target():
		return

	if state_timer <= 0.0:
		start_active()


func update_active() -> void:
	update_chain_progress(1.0)

	if try_grab_target():
		return

	if state_timer <= 0.0:
		start_retracting()


func update_holding() -> void:
	update_chain_line_to_target()

	if state_timer <= 0.0:
		clear_chained_target()
		start_retracting()


func update_retracting() -> void:
	var progress: float = 1.0 - get_state_progress()
	update_chain_progress(progress)

	if state_timer <= 0.0:
		start_waiting(fire_interval)


func start_waiting(duration: float) -> void:
	chain_state = ChainState.WAITING
	state_duration = max(duration, 0.0)
	state_timer = state_duration
	clear_chained_target()
	hide_chain_line()
	set_chain_hitbox_active(false)


func start_warning() -> void:
	chain_state = ChainState.WARNING
	state_duration = max(warning_time, 0.0)
	state_timer = state_duration
	show_warning_line()
	set_chain_hitbox_active(false)

	if state_timer <= 0.0:
		start_extending()


func start_extending() -> void:
	chain_state = ChainState.EXTENDING
	state_duration = max(extend_time, 0.001)
	state_timer = state_duration
	chain_line.visible = true
	chain_line.default_color = chain_fire_color
	update_chain_progress(0.0)
	set_chain_hitbox_active(true)


func start_active() -> void:
	chain_state = ChainState.ACTIVE
	state_duration = max(active_time, 0.0)
	state_timer = state_duration
	update_chain_progress(1.0)
	set_chain_hitbox_active(true)

	if state_timer <= 0.0:
		start_retracting()


func start_holding(target: Node2D) -> void:
	chained_target = target
	chained_target.call("apply_chain_hold", grab_point.global_position, hold_duration)

	chain_state = ChainState.HOLDING
	state_duration = max(hold_duration, 0.0)
	state_timer = state_duration
	chain_line.visible = true
	chain_line.default_color = chain_hold_color
	set_chain_hitbox_active(false)
	update_chain_line_to_target()

	if state_timer <= 0.0:
		clear_chained_target()
		start_retracting()


func start_retracting() -> void:
	chain_state = ChainState.RETRACTING
	state_duration = max(retract_time, 0.001)
	state_timer = state_duration
	clear_chained_target()
	chain_line.visible = true
	chain_line.default_color = chain_fire_color
	set_chain_hitbox_active(false)
	update_chain_progress(1.0)


func try_grab_target() -> bool:
	for body in get_overlapping_bodies():
		var target: Node2D = body as Node2D

		if target == null:
			continue
		if not target.has_method("apply_chain_hold"):
			continue
		if max_chain_length > 0.0 and global_position.distance_to(target.global_position) > max_chain_length:
			continue

		start_holding(target)
		return true

	return false


func update_chain_progress(progress: float) -> void:
	var clamped_progress: float = clampf(progress, 0.0, 1.0)
	var local_end_position: Vector2 = grab_point.position * clamped_progress

	chain_line.points = PackedVector2Array([
		Vector2.ZERO,
		local_end_position
	])

	update_chain_hitbox(local_end_position)


func update_chain_hitbox(local_end_position: Vector2) -> void:
	var hitbox_shape: RectangleShape2D = collision_shape.shape as RectangleShape2D

	if hitbox_shape == null:
		hitbox_shape = RectangleShape2D.new()
		collision_shape.shape = hitbox_shape

	var hitbox_length: float = max(local_end_position.length(), 1.0)
	hitbox_shape.size = Vector2(hitbox_length, chain_hitbox_thickness)

	collision_shape.position = local_end_position * 0.5

	if local_end_position.length() > 0.0:
		collision_shape.rotation = local_end_position.angle()
	else:
		collision_shape.rotation = 0.0


func update_chain_line_to_target() -> void:
	var line_end_position: Vector2 = grab_point.global_position

	if chained_target == null or not is_instance_valid(chained_target):
		return
	if not chained_target.is_inside_tree():
		return

	if chained_target.has_method("get_chain_attach_position"):
		var attach_position: Variant = chained_target.call("get_chain_attach_position")
		if attach_position is Vector2:
			line_end_position = attach_position
	else:
		line_end_position = chained_target.global_position

	chain_line.points = PackedVector2Array([
		Vector2.ZERO,
		to_local(line_end_position)
	])


func hide_chain_line() -> void:
	chain_line.visible = false
	chain_line.default_color = chain_wait_color
	chain_line.points = PackedVector2Array([
		Vector2.ZERO,
		Vector2.ZERO
	])


func show_warning_line() -> void:
	chain_line.visible = true
	chain_line.default_color = chain_warning_color
	chain_line.points = PackedVector2Array([
		Vector2.ZERO,
		grab_point.position
	])


func set_chain_hitbox_active(active: bool) -> void:
	collision_shape.set_deferred("disabled", not active)


func get_state_progress() -> float:
	if state_duration <= 0.0:
		return 1.0

	return 1.0 - state_timer / state_duration


func clear_chained_target() -> void:
	chained_target = null


func reset_on_respawn() -> void:
	start_waiting(initial_fire_delay)
