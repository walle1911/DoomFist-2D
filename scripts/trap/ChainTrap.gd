extends Area2D

@export var hold_duration: float = 0.5
@export var warning_time: float = 0.2
@export var cooldown: float = 1.0
@export var max_chain_length: float = 64.0

@onready var grab_point: Marker2D = $GrabPoint
@onready var chain_line: Line2D = $ChainLine

var target: Node = null
var warning_timer: float = 0.0
var cooldown_timer: float = 0.0
var holding_timer: float = 0.0


func _ready() -> void:
	add_to_group("respawn_reset")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	chain_line.visible = false


func _physics_process(delta: float) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer = max(cooldown_timer - delta, 0.0)

	if holding_timer > 0.0:
		holding_timer = max(holding_timer - delta, 0.0)
		if holding_timer <= 0.0:
			chain_line.visible = false

	if target == null:
		return

	if warning_timer > 0.0:
		warning_timer -= delta
		if warning_timer <= 0.0:
			try_grab_target()


func _on_body_entered(body: Node) -> void:
	if cooldown_timer > 0.0:
		return

	if body.has_method("apply_chain_hold"):
		target = body
		warning_timer = warning_time


func _on_body_exited(body: Node) -> void:
	if body == target:
		target = null
		warning_timer = 0.0


func try_grab_target() -> void:
	if target == null:
		return

	if not overlaps_body(target):
		target = null
		return

	if global_position.distance_to(target.global_position) > max_chain_length:
		target = null
		return

	target.apply_chain_hold(grab_point.global_position, hold_duration)

	chain_line.visible = true
	chain_line.points = PackedVector2Array([
		Vector2.ZERO,
		to_local(grab_point.global_position)
	])

	holding_timer = hold_duration
	cooldown_timer = cooldown
	target = null


func reset_on_respawn() -> void:
	target = null
	warning_timer = 0.0
	cooldown_timer = 0.0
	holding_timer = 0.0
	chain_line.visible = false
