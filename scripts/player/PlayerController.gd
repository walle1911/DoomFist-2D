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


func _ready() -> void:
	spawn_position = global_position


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		respawn()

	handle_timers(delta)

	if is_punch_dashing:
		handle_punch_dash(delta)

	elif is_slamming:
		handle_slam(delta)

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

	move_and_slide()

	check_punch_collisions()
	check_slam_landing()


# =========================
# 计时器
# =========================

func handle_timers(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
		can_uppercut = true
		can_punch = true
		can_slam = true
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)

	# 冲刺或裂地阶段不缓存 Space。
	# 防止技能结束后自动触发上勾拳。
	if Input.is_action_just_pressed("jump"):
		if not is_punch_dashing and not is_slamming:
			jump_buffer_timer = jump_buffer_time
	else:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)


# =========================
# 基础移动
# =========================

func handle_horizontal_movement(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")

	if direction != 0:
		facing_direction = int(sign(direction))

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
	if can_uppercut:
		do_uppercut()
		jump_buffer_timer = 0.0


func do_uppercut() -> void:
	velocity.y = uppercut_velocity
	velocity.x *= uppercut_horizontal_keep
	can_uppercut = false


# =========================
# 冲刺重拳输入
# =========================

func handle_punch_input(delta: float) -> void:
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


func handle_punch_dash(delta: float) -> void:
	velocity.x = punch_dash_direction * punch_current_speed

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
	else:
		# 空中持续时间结束，则恢复普通空中状态，不强行清掉竖直速度
		velocity.x *= 0.6


# =========================
# 检查点 / 重生
# =========================

func set_checkpoint(pos: Vector2) -> void:
	spawn_position = pos


func respawn() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO

	can_uppercut = true
	can_punch = true
	can_slam = true

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
