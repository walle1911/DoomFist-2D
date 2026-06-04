extends CharacterBody2D

# =========================
# 基础移动参数
# =========================

@export var move_speed: float = 120.0
@export var ground_accel: float = 1200.0
@export var ground_decel: float = 1600.0
@export var air_accel: float = 840.0

@export var jump_velocity: float = -520.0
@export var gravity: float = 1800.0
@export var max_fall_speed: float = 420.0

@export var coyote_time: float = 0.08
@export var jump_buffer_time: float = 0.10


# =========================
# 上勾拳 / 二段跳
# =========================

@export var uppercut_velocity: float = -440.0
@export var uppercut_horizontal_keep: float = 0.8

var can_uppercut: bool = true


# =========================
# 冲刺重拳
# =========================

@export var punch_tap_threshold: float = 0.15
@export var punch_full_charge_time: float = 0.45

@export var punch_tap_speed: float = 500.0
@export var punch_tap_duration: float = 0.16

@export var punch_charge_speed: float = 560.0
@export var punch_charge_duration: float = 0.20

@export var punch_full_charge_speed: float = 620.0
@export var punch_full_charge_duration: float = 0.22

@export var punch_dash_gravity_scale: float = 0.35
@export var punch_dash_exit_keep: float = 0.65



var can_punch: bool = true
var facing_direction: int = 1

var punch_button_holding: bool = false
var punch_hold_time: float = 0.0

var is_punch_dashing: bool = false
var punch_dash_direction: int = 1
var punch_dash_time_left: float = 0.0
var punch_current_speed: float = 0.0

var punch_is_charged: bool = false
var punch_is_full_charged: bool = false


# =========================
# 裂地重拳
# =========================

@export var slam_x_speed: float = 260.0
@export var slam_start_y_speed: float = 360.0
@export var slam_gravity_scale: float = 1.1
@export var slam_max_down_speed: float = 680.0
@export var slam_max_duration: float = 0.50
@export var slam_landing_x_keep: float = 0.25

var can_slam: bool = true
var is_slamming: bool = false
var slam_time_left: float = 0.0
var slam_direction: int = 1


# =========================
# 计时器 / 重生点
# =========================

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

var spawn_position: Vector2

# =========================
# 格挡
# =========================

@export var block_duration: float = 0.35
@export var block_cooldown: float = 0.8
@export var block_move_multiplier: float = 0.4
@export var block_area_offset_x: float = 22.0

var can_block: bool = true
var is_blocking: bool = false
var block_timer: float = 0.0
var block_cooldown_timer: float = 0.0

var fist_energy: int = 0
@export var max_fist_energy: int = 2


# =========================
# 受击 / 睡眠
# =========================

var is_control_locked: bool = false
var control_lock_timer: float = 0.0
var skill_silence_timer: float = 0.0
var slow_timer: float = 0.0
var slow_speed_multiplier: float = 1.0

@export var chain_body_attach_offset: Vector2 = Vector2(0.0, -24.0)
@export var chain_rope_length: float = 8.0
@export var chain_pull_stiffness: float = 85.0
@export var chain_pull_damping: float = 7.0
@export var chain_max_pull_speed: float = 520.0
@export var chain_release_velocity_keep: float = 0.25
@export var chain_swing_amplitude: float = 8.0
@export var chain_swing_frequency: float = 7.0
@export var chain_bob_amplitude: float = 2.0
@export var chain_visual_tilt_degrees: float = 8.0

var is_chained: bool = false
var chain_timer: float = 0.0
var chain_anchor_position: Vector2 = Vector2.ZERO
var chain_velocity: Vector2 = Vector2.ZERO
var chain_elapsed: float = 0.0
var chain_swing_direction: float = 1.0


# =========================
# 临时美术表现
# =========================

@export var visual_base_color: Color = Color(0.83, 0.72, 0.40, 1.0)
@export var visual_punch_color: Color = Color(1.0, 0.52, 0.14, 1.0)
@export var visual_full_charge_color: Color = Color(1.0, 0.88, 0.18, 1.0)
@export var visual_slam_color: Color = Color(0.35, 0.68, 1.0, 1.0)
@export var visual_block_color: Color = Color(0.35, 0.9, 1.0, 1.0)
@export var visual_locked_color: Color = Color(0.62, 0.64, 0.74, 1.0)
@export var visual_chain_color: Color = Color(0.58, 0.78, 1.0, 1.0)
@export var visual_silence_color: Color = Color(0.9, 0.9, 0.35, 1.0)
@export var afterimage_interval: float = 0.035
@export var afterimage_lifetime: float = 0.18
@export var slam_impact_lifetime: float = 0.22
@export var visual_pose_lerp_speed: float = 18.0
@export var visual_idle_bob_amount: float = 1.2
@export var visual_idle_bob_speed: float = 5.0
@export var visual_run_bob_amount: float = 2.4
@export var visual_run_bob_speed: float = 14.0
@export var visual_run_lean_degrees: float = 5.0
@export var visual_air_lean_degrees: float = 6.0

var afterimage_timer: float = 0.0
var visual_anim_time: float = 0.0
var chain_visual_tilt: float = 0.0


func _ready() -> void:
	spawn_position = global_position
	block_area.area_entered.connect(_on_block_area_entered)
	block_shape.disabled = true
	update_skill_visuals(0.0)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		respawn()

	handle_timers(delta)
	handle_block_cooldown(delta)

	if is_chained:
		handle_chain_hold(delta)
		move_and_slide()
		update_skill_visuals(delta)
		return

	if is_control_locked:
		handle_control_lock(delta)
		move_and_slide()
		check_punch_collisions()
		check_slam_landing()
		update_skill_visuals(delta)
		return

	if is_punch_dashing:
		handle_punch_dash(delta)

	elif is_slamming:
		handle_slam(delta)

	elif is_blocking:
		handle_block(delta)
		handle_horizontal_movement(delta, block_move_multiplier)
		handle_gravity(delta)

	else:
		handle_block_input()

		if is_blocking:
			handle_block(delta)
			handle_horizontal_movement(delta, block_move_multiplier)
			handle_gravity(delta)
		else:
			handle_slam_input()

			if is_slamming:
				handle_slam(delta)
			else:
				handle_punch_input(delta)

				if is_punch_dashing:
					handle_punch_dash(delta)
				else:
					handle_horizontal_movement(delta)
					handle_gravity(delta)
					handle_jump()

	update_block_area()

	move_and_slide()

	check_punch_collisions()
	check_slam_landing()
	update_skill_visuals(delta)

@onready var block_area: Area2D = $BlockArea
@onready var block_shape: CollisionShape2D = $BlockArea/CollisionShape2D
@onready var body_polygon: Polygon2D = get_node_or_null("Polygon2D") as Polygon2D
@onready var block_visual: CanvasItem = get_node_or_null("BlockArea/BlockVisual") as CanvasItem
@onready var punch_charge_visual: Polygon2D = get_node_or_null("PunchChargeVisual") as Polygon2D


# =========================
# 计时器
# =========================

func handle_timers(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
		refresh_normal_skills()
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)
	# 冲刺或裂地阶段不缓存 Space。
	# 防止技能结束后自动触发上勾拳。
	if Input.is_action_just_pressed("jump"):
		if not is_punch_dashing and not is_slamming and not is_blocking:
			jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)

	if skill_silence_timer > 0.0:
		skill_silence_timer = max(skill_silence_timer - delta, 0.0)

	if slow_timer > 0.0:
		slow_timer = max(slow_timer - delta, 0.0)
		if slow_timer <= 0.0:
			slow_speed_multiplier = 1.0
# =========================
# 基础移动
# =========================

func handle_horizontal_movement(delta: float, speed_multiplier: float = 1.0) -> void:
	var direction := Input.get_axis("move_left", "move_right")

	if direction != 0:
		facing_direction = int(sign(direction))

	#var target_speed := direction * move_speed * speed_multiplier
	var target_speed := direction * move_speed * speed_multiplier * slow_speed_multiplier

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


# =========================
# 跳跃 / 上勾拳
# =========================

func handle_jump() -> void:
	if jump_buffer_timer <= 0.0:
		return

	# 普通跳跃：站在地面，或者处于土狼时间内
	if coyote_timer > 0.0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		return

	# 上勾拳 / 二段跳
	if skill_silence_timer <= 0.0 and can_uppercut:
		do_uppercut()
		jump_buffer_timer = 0.0


func do_uppercut() -> void:
	velocity.y = uppercut_velocity
	velocity.x *= uppercut_horizontal_keep
	can_uppercut = false
	spawn_burst_effect(global_position + Vector2(0.0, 16.0), Color(0.55, 0.85, 1.0, 0.55), Vector2(30.0, 10.0), 0.16)


# =========================
# 冲刺重拳输入
# =========================

func handle_punch_input(delta: float) -> void:
	if skill_silence_timer > 0.0:
		return
	if not can_punch:
		return

	if Input.is_action_just_pressed("punch"):
		punch_button_holding = true
		punch_hold_time = 0.0

	if punch_button_holding:
		punch_hold_time += delta

	if Input.is_action_just_released("punch") and punch_button_holding:
		punch_button_holding = false

		if punch_hold_time < punch_tap_threshold:
			start_punch_dash(false, false)
		elif punch_hold_time >= punch_full_charge_time:
			start_punch_dash(true, true)
		else:
			start_punch_dash(true, false)


func start_punch_dash(is_charged: bool, is_full_charged: bool) -> void:
	is_punch_dashing = true
	punch_dash_direction = facing_direction

	punch_is_charged = is_charged
	punch_is_full_charged = is_full_charged

	can_punch = false

	if is_full_charged:
		punch_current_speed = punch_full_charge_speed
		punch_dash_time_left = punch_full_charge_duration
	elif is_charged:
		punch_current_speed = punch_charge_speed
		punch_dash_time_left = punch_charge_duration
	else:
		punch_current_speed = punch_tap_speed
		punch_dash_time_left = punch_tap_duration

	# 冲刺开始时先拉平竖直速度，让重拳是直接水平打出去
	velocity.y = 0.0
	velocity.x = punch_dash_direction * punch_current_speed
	spawn_punch_afterimage()


func handle_punch_dash(delta: float) -> void:
	velocity.x = punch_dash_direction * punch_current_speed
	afterimage_timer -= delta

	if afterimage_timer <= 0.0:
		spawn_punch_afterimage()
		afterimage_timer = afterimage_interval

	# 冲刺阶段仍受弱重力影响，角色会轻微下垂
	velocity.y += gravity * punch_dash_gravity_scale * delta
	velocity.y = min(velocity.y, max_fall_speed)

	punch_dash_time_left -= delta

	if punch_dash_time_left <= 0.0:
		end_punch_dash()


func end_punch_dash() -> void:
	is_punch_dashing = false

	# 冲刺结束后保留一部分水平惯性，不要突然停死
	velocity.x = punch_dash_direction * punch_current_speed * punch_dash_exit_keep


# =========================
# 冲刺碰撞检测
# =========================

func check_punch_collisions() -> void:
	if not is_punch_dashing:
		return

	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()

		if collider == null:
			continue

		if collider.has_method("break_wall"):
			if punch_is_charged:
				collider.break_wall()
			else:
				end_punch_dash()


# =========================
# 裂地重拳
# =========================

func handle_slam_input() -> void:
	if skill_silence_timer > 0.0:
		return
	if not can_slam:
		return

	if is_on_floor():
		return

	if Input.is_action_just_pressed("slam"):
		start_slam()


func start_slam() -> void:
	is_slamming = true
	can_slam = false
	slam_time_left = slam_max_duration
	slam_direction = facing_direction
	spawn_burst_effect(global_position + Vector2(0.0, 8.0), Color(0.25, 0.55, 1.0, 0.45), Vector2(18.0, 26.0), 0.16)

	# 清掉跳跃缓冲，避免裂地结束后自动触发跳跃 / 上勾拳
	jump_buffer_timer = 0.0

	# 斜下砸落：水平朝面向方向，竖直方向快速下落
	velocity.x = slam_direction * slam_x_speed
	velocity.y = slam_start_y_speed


func handle_slam(delta: float) -> void:
	slam_time_left -= delta

	# 裂地期间不能用 A/D 改方向，水平速度固定
	velocity.x = slam_direction * slam_x_speed

	# 裂地是斜下砸落，不是完全直线。这里保留重力，让轨迹逐渐向下压
	velocity.y += gravity * slam_gravity_scale * delta
	velocity.y = min(velocity.y, slam_max_down_speed)

	if slam_time_left <= 0.0:
		end_slam(false)


func check_slam_landing() -> void:
	if not is_slamming:
		return

	if is_on_floor():
		end_slam(true)


func end_slam(landed: bool) -> void:
	is_slamming = false
	slam_time_left = 0.0

	if landed:
		# 落地后保留少量水平惯性，防止落地后继续横飞太远
		velocity.x *= slam_landing_x_keep
		spawn_burst_effect(global_position + Vector2(0.0, 22.0), Color(0.45, 0.75, 1.0, 0.55), Vector2(58.0, 10.0), slam_impact_lifetime)
	else:
		# 空中持续时间结束，则恢复普通空中状态，不强行清掉竖直速度
		velocity.x *= 0.6
		

# =========================
# 格挡
# =========================

func handle_block_cooldown(delta: float) -> void:
	if block_cooldown_timer > 0.0:
		block_cooldown_timer = max(block_cooldown_timer - delta, 0.0)


func handle_block_input() -> void:
	if skill_silence_timer > 0.0:
		return
	if not can_block:
		return

	if block_cooldown_timer > 0.0:
		return

	if Input.is_action_just_pressed("block"):
		start_block()


func start_block() -> void:
	is_blocking = true
	can_block = false
	block_timer = block_duration
	spawn_burst_effect(global_position, Color(0.25, 0.85, 1.0, 0.35), Vector2(42.0, 54.0), 0.12)

	# 防止格挡开始前的 Space 缓冲在结束后触发上勾拳
	jump_buffer_timer = 0.0


func handle_block(delta: float) -> void:
	block_timer -= delta

	if block_timer <= 0.0:
		end_block()


func end_block() -> void:
	is_blocking = false
	block_timer = 0.0
	block_cooldown_timer = block_cooldown
	block_shape.set_deferred("disabled", true)


func update_block_area() -> void:
	block_area.position.x = facing_direction * block_area_offset_x
	block_shape.disabled = not is_blocking

func _on_block_area_entered(area: Area2D) -> void:
	if not is_blocking:
		return

	if area.has_method("on_blocked"):
		area.on_blocked(self)
		gain_fist_energy()
		can_punch = true

func gain_fist_energy() -> void:
	fist_energy = min(fist_energy + 1, max_fist_energy)


# =========================
# 受控
# =========================
func apply_sleep(duration: float) -> void:
	is_control_locked = true
	control_lock_timer = duration

	is_punch_dashing = false
	is_slamming = false
	is_blocking = false

	punch_button_holding = false
	jump_buffer_timer = 0.0
	block_shape.set_deferred("disabled", true)

	velocity.x = 0.0


func handle_control_lock(delta: float) -> void:
	control_lock_timer -= delta

	handle_gravity(delta)
	velocity.x = move_toward(velocity.x, 0.0, ground_decel * delta)

	if control_lock_timer <= 0.0:
		is_control_locked = false
		control_lock_timer = 0.0

func apply_knockback(direction: Vector2, speed: float, duration: float) -> void:
	is_control_locked = true
	control_lock_timer = duration

	is_punch_dashing = false
	is_slamming = false
	is_blocking = false

	punch_button_holding = false
	jump_buffer_timer = 0.0
	block_shape.set_deferred("disabled", true)

	velocity.x = direction.normalized().x * speed
	velocity.y = min(velocity.y, -120.0)


func apply_flash(skill_lock_duration: float, slow_duration: float, speed_multiplier: float) -> void:
	skill_silence_timer = max(skill_silence_timer, skill_lock_duration)
	slow_timer = max(slow_timer, slow_duration)
	slow_speed_multiplier = min(slow_speed_multiplier, speed_multiplier)

	is_punch_dashing = false
	is_slamming = false
	is_blocking = false

	punch_button_holding = false
	jump_buffer_timer = 0.0
	block_shape.set_deferred("disabled", true)


func apply_chain_hold(hold_position: Vector2, duration: float) -> void:
	is_chained = true
	chain_timer = duration
	chain_anchor_position = hold_position
	chain_velocity = velocity * 0.25
	chain_elapsed = 0.0
	chain_swing_direction = signf(global_position.x - hold_position.x)

	if chain_swing_direction == 0.0:
		chain_swing_direction = float(facing_direction)

	is_punch_dashing = false
	is_slamming = false
	is_blocking = false
	is_control_locked = false

	punch_button_holding = false
	jump_buffer_timer = 0.0
	block_shape.set_deferred("disabled", true)

	velocity = chain_velocity


func handle_chain_hold(delta: float) -> void:
	chain_timer -= delta
	chain_elapsed += delta

	var body_target_position: Vector2 = get_chain_body_target_position()
	var pull_vector: Vector2 = body_target_position - global_position
	chain_velocity += pull_vector * chain_pull_stiffness * delta

	var damping_weight: float = chain_pull_damping * delta
	if damping_weight > 1.0:
		damping_weight = 1.0

	chain_velocity = chain_velocity.lerp(Vector2.ZERO, damping_weight)

	if chain_velocity.length() > chain_max_pull_speed:
		chain_velocity = chain_velocity.normalized() * chain_max_pull_speed

	velocity = chain_velocity
	update_chain_visual_tilt()

	if chain_timer <= 0.0:
		end_chain_hold()


func get_chain_body_target_position() -> Vector2:
	var attach_target_position: Vector2 = get_chain_attach_target_position()

	return attach_target_position - chain_body_attach_offset


func get_chain_attach_target_position() -> Vector2:
	var swing: float = sin(chain_elapsed * chain_swing_frequency) * chain_swing_amplitude * chain_swing_direction
	var bob: float = absf(sin(chain_elapsed * chain_swing_frequency * 0.5)) * chain_bob_amplitude

	return chain_anchor_position + Vector2(swing, chain_rope_length + bob)


func get_chain_attach_position() -> Vector2:
	if is_chained:
		return global_position + chain_body_attach_offset

	return global_position


func update_chain_visual_tilt() -> void:
	var speed_ratio: float = chain_velocity.x / chain_max_pull_speed
	speed_ratio = clampf(speed_ratio, -1.0, 1.0)
	chain_visual_tilt = deg_to_rad(chain_visual_tilt_degrees) * speed_ratio


func reset_chain_visual_tilt() -> void:
	chain_visual_tilt = 0.0


func end_chain_hold() -> void:
	is_chained = false
	chain_timer = 0.0
	velocity = chain_velocity * chain_release_velocity_keep
	chain_velocity = Vector2.ZERO
	reset_chain_visual_tilt()

# =========================
# 技能刷新
# =========================
func refresh_normal_skills() -> void:
	can_uppercut = true
	can_punch = true
	can_slam = true
	can_block = true
	block_cooldown_timer = 0.0


func get_debug_text() -> String:
	return "STATE %s\nSKILL U:%s P:%s S:%s B:%s\nENERGY %d/%d\nVEL %.0f %.0f\nSPAWN %.0f %.0f" % [
		get_debug_state_name(),
		debug_flag(can_uppercut),
		debug_flag(can_punch),
		debug_flag(can_slam),
		debug_flag(can_block and block_cooldown_timer <= 0.0),
		fist_energy,
		max_fist_energy,
		velocity.x,
		velocity.y,
		spawn_position.x,
		spawn_position.y,
	]


func get_debug_state_name() -> String:
	if is_chained:
		return "CHAIN"
	if is_control_locked:
		return "LOCK"
	if is_blocking:
		return "BLOCK"
	if is_punch_dashing:
		return "PUNCH"
	if is_slamming:
		return "SLAM"
	if skill_silence_timer > 0.0:
		return "SILENCE"
	if slow_timer > 0.0:
		return "SLOW"

	return "NORMAL"


func debug_flag(value: bool) -> String:
	if value:
		return "Y"

	return "N"


# =========================
# 临时美术表现
# =========================

func update_skill_visuals(delta: float) -> void:
	visual_anim_time += delta

	if body_polygon != null:
		body_polygon.color = get_body_visual_color()
		update_placeholder_pose(delta)

	if block_visual != null:
		block_visual.visible = is_blocking

	if punch_charge_visual != null:
		update_punch_charge_visual(delta)


func get_body_visual_color() -> Color:
	if is_chained:
		return visual_chain_color
	if is_control_locked:
		return visual_locked_color
	if is_blocking:
		return visual_block_color
	if is_slamming:
		return visual_slam_color
	if is_punch_dashing:
		if punch_is_full_charged:
			return visual_full_charge_color
		return visual_punch_color
	if skill_silence_timer > 0.0:
		return visual_silence_color

	return visual_base_color


func update_punch_charge_visual(_delta: float) -> void:
	if not punch_button_holding:
		punch_charge_visual.visible = false
		return

	var charge_ratio: float = clampf(punch_hold_time / punch_full_charge_time, 0.0, 1.0)
	punch_charge_visual.visible = true
	punch_charge_visual.scale = Vector2.ONE * (0.85 + charge_ratio * 0.35)
	punch_charge_visual.color = Color(1.0, 0.38 + charge_ratio * 0.45, 0.12, 0.22 + charge_ratio * 0.32)


func update_placeholder_pose(delta: float) -> void:
	var pose: Dictionary = get_placeholder_pose()
	var target_position: Vector2 = pose["position"] as Vector2
	var target_scale: Vector2 = pose["scale"] as Vector2
	var target_rotation: float = float(pose["rotation"])
	var pose_weight: float = visual_pose_lerp_speed * delta

	if pose_weight > 1.0:
		pose_weight = 1.0

	body_polygon.position = body_polygon.position.lerp(target_position, pose_weight)
	body_polygon.scale = body_polygon.scale.lerp(target_scale, pose_weight)
	body_polygon.rotation = lerpf(body_polygon.rotation, target_rotation, pose_weight)


func get_placeholder_pose() -> Dictionary:
	var target_position := Vector2.ZERO
	var target_scale := Vector2.ONE
	var target_rotation := 0.0

	if is_chained:
		target_position = Vector2(0.0, 2.0)
		target_scale = Vector2(0.92, 1.1)
		target_rotation = chain_visual_tilt
	elif is_control_locked:
		target_position = Vector2(0.0, 3.0)
		target_scale = Vector2(1.08, 0.92)
		target_rotation = deg_to_rad(-4.0 * facing_direction)
	elif is_blocking:
		target_position = Vector2(-2.0 * facing_direction, 1.0)
		target_scale = Vector2(0.9, 1.08)
	elif is_slamming:
		target_position = Vector2(0.0, 1.0)
		target_scale = Vector2(0.9, 1.24)
		target_rotation = deg_to_rad(12.0 * slam_direction)
	elif is_punch_dashing:
		target_scale = Vector2(1.38, 0.78)
		target_rotation = deg_to_rad(-3.0 * punch_dash_direction)
	elif punch_button_holding:
		var charge_ratio: float = clampf(punch_hold_time / punch_full_charge_time, 0.0, 1.0)
		target_scale = Vector2(1.0 - charge_ratio * 0.12, 1.0 + charge_ratio * 0.16)
		target_position = Vector2(-2.0 * facing_direction * charge_ratio, 0.0)
	elif not is_on_floor():
		if velocity.y < 0.0:
			target_position = Vector2(0.0, -1.0)
			target_scale = Vector2(0.92, 1.08)
			target_rotation = deg_to_rad(-visual_air_lean_degrees * facing_direction)
		else:
			target_position = Vector2(0.0, 2.0)
			target_scale = Vector2(1.04, 0.96)
			target_rotation = deg_to_rad(visual_air_lean_degrees * 0.5 * facing_direction)
	elif absf(velocity.x) > 10.0:
		var run_phase: float = sin(visual_anim_time * visual_run_bob_speed)
		target_position = Vector2(0.0, absf(run_phase) * visual_run_bob_amount)
		target_scale = Vector2(1.04, 0.96 + absf(run_phase) * 0.04)
		target_rotation = deg_to_rad(visual_run_lean_degrees * facing_direction)
	else:
		var idle_phase: float = sin(visual_anim_time * visual_idle_bob_speed)
		target_position = Vector2(0.0, idle_phase * visual_idle_bob_amount)
		target_scale = Vector2(1.0 + idle_phase * 0.015, 1.0 - idle_phase * 0.015)

	return {
		"position": target_position,
		"scale": target_scale,
		"rotation": target_rotation,
	}


func spawn_punch_afterimage() -> void:
	if body_polygon == null or get_parent() == null:
		return

	var afterimage := Polygon2D.new()
	afterimage.global_position = body_polygon.global_position
	afterimage.global_rotation = body_polygon.global_rotation
	afterimage.global_scale = body_polygon.global_scale
	afterimage.polygon = body_polygon.polygon
	afterimage.color = Color(visual_punch_color.r, visual_punch_color.g, visual_punch_color.b, 0.42)
	get_parent().add_child(afterimage)

	var tween := afterimage.create_tween()
	tween.tween_property(afterimage, "modulate:a", 0.0, afterimage_lifetime)
	tween.parallel().tween_property(afterimage, "scale", Vector2(1.18, 1.02), afterimage_lifetime)
	tween.tween_callback(afterimage.queue_free)


func spawn_burst_effect(effect_position: Vector2, effect_color: Color, effect_size: Vector2, lifetime: float) -> void:
	if get_parent() == null:
		return

	var burst := Polygon2D.new()
	var half_size: Vector2 = effect_size * 0.5
	burst.polygon = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y)
	])
	burst.global_position = effect_position
	burst.color = effect_color
	get_parent().add_child(burst)

	var tween := burst.create_tween()
	tween.tween_property(burst, "modulate:a", 0.0, lifetime)
	tween.parallel().tween_property(burst, "scale", Vector2(1.45, 1.45), lifetime)
	tween.tween_callback(burst.queue_free)



# =========================
# 检查点 / 重生
# =========================

func set_checkpoint(pos: Vector2) -> void:
	spawn_position = pos

func reset_room_objects() -> void:
	get_tree().call_group("respawn_clear", "queue_free")
	get_tree().call_group("respawn_reset", "reset_on_respawn")

func respawn() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO

	refresh_normal_skills()

	punch_button_holding = false
	punch_hold_time = 0.0

	is_punch_dashing = false
	punch_dash_time_left = 0.0
	punch_current_speed = 0.0

	punch_is_charged = false
	punch_is_full_charged = false

	is_slamming = false
	slam_time_left = 0.0
	slam_direction = 1
	
	is_blocking = false
	block_timer = 0.0
	block_cooldown_timer = 0.0
	can_block = true
	#block_shape.disabled = true
	block_shape.set_deferred("disabled", true)

	is_control_locked = false
	control_lock_timer = 0.0
	
	is_chained = false
	chain_timer = 0.0
	chain_anchor_position = Vector2.ZERO
	chain_velocity = Vector2.ZERO
	chain_elapsed = 0.0
	reset_chain_visual_tilt()

	skill_silence_timer = 0.0
	slow_timer = 0.0
	slow_speed_multiplier = 1.0
	reset_room_objects()
