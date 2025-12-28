extends CharacterBody2D

var gravity := ProjectSettings.get("physics/2d/default_gravity") as float
var run_speed := 250.0
var jump_velocity := -400.0
var acceleration := 1000.0  # 添加加速度
var air_acceleration := 500.0  # 空中加速度
var friction := 800.0  # 地面摩擦力
var air_friction := 200.0  # 空中摩擦力
var coyote_time := 0.1  # 土狼时间（离地后仍可跳跃的时间窗口）
var jump_buffer_time := 0.1  # 跳跃缓冲时间（落地前输入可延迟执行）
var max_fall_speed := 600.0  # 最大下落速度
var fast_fall_multiplier := 1.5  # 快速下落倍率

var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var is_fast_falling := false

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _physics_process(delta: float) -> void:
	# 更新计时器
	coyote_timer -= delta
	jump_buffer_timer -= delta
	
	# 重力处理
	if not is_on_floor():
		velocity.y += gravity * delta
		
		# 土狼时间机制
		if coyote_timer <= 0 and is_on_floor_only():
			coyote_timer = 0.1
		
		# 快速下落机制
		if Input.is_action_pressed("move_down") and velocity.y > 0:
			velocity.y += gravity * delta * fast_fall_multiplier
			is_fast_falling = true
		
		# 限制最大下落速度
		if velocity.y > max_fall_speed:
			velocity.y = max_fall_speed
	else:
		coyote_timer = 0.0
		is_fast_falling = false
	
	# 获取输入
	var direction := Input.get_axis("move_left", "move_right")
	var jump_pressed := Input.is_action_just_pressed("move_up")
	var jump_held := Input.is_action_pressed("move_up")
	
	# 跳跃缓冲机制
	if jump_pressed:
		jump_buffer_timer = jump_buffer_time
	
	# 跳跃处理（支持土狼时间和缓冲时间）
	var can_jump = (is_on_floor() or coyote_timer > 0)
	if can_jump and jump_buffer_timer > 0:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
	
	# 可变高度跳跃（按住跳得更高）
	if not jump_held and velocity.y < jump_velocity * 0.5:
		velocity.y = jump_velocity * 0.5
	
	# 水平移动处理（带加速度和摩擦力）
	if is_on_floor():
		# 地面移动
		if direction != 0:
			velocity.x = move_toward(velocity.x, direction * run_speed, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
	else:
		# 空中移动（减少控制力）
		if direction != 0:
			velocity.x = move_toward(velocity.x, direction * run_speed, air_acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, air_friction * delta)
	
	# 动画控制
	if is_on_floor():
		if is_zero_approx(direction) and is_zero_approx(velocity.x):
			animation_player.play("idle")
		else:
			animation_player.play("running")
			
			# 根据速度方向决定动画播放速度
			var speed_ratio = abs(velocity.x) / run_speed
			animation_player.speed_scale = lerp(0.8, 1.2, speed_ratio)
	else:
		if is_fast_falling:
			animation_player.play("idle")  # 可以考虑添加"fall_fast"动画
		elif velocity.y < 0:
			animation_player.play("idle")  # 可以考虑添加"jump"动画
		else:
			animation_player.play("idle")  # 可以考虑添加"fall"动画
	
	# 翻转精灵（考虑速度方向，不只是输入方向）
	if not is_zero_approx(velocity.x):
		sprite_2d.flip_h = velocity.x < 0
	elif not is_zero_approx(direction):
		sprite_2d.flip_h = direction < 0
	
	# 移动角色
	move_and_slide()
	
	# 碰撞后速度修正（防止卡墙）
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_normal().x != 0:
			velocity.y *= 0.9  # 轻微减少垂直速度防止弹跳

# 可选：添加一些辅助功能
func _unhandled_input(event: InputEvent) -> void:
	# 跳跃快捷重置（调试用）
	if event.is_action_pressed("ui_cancel"):
		velocity = Vector2.ZERO
		global_position = Vector2(100, 100)
