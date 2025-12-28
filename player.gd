extends CharacterBody2D

var gravity := ProjectSettings.get("physics/2d/default_gravity") as float
var run_speed := 300.0
var jump_velocity := -400.0  # 增加跳跃力度

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _physics_process(delta: float) -> void:
	# 应用重力
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# 获取水平移动方向
	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * run_speed
	
	# 跳跃输入
	if Input.is_action_just_pressed("move_up") and is_on_floor():
		velocity.y = jump_velocity
	
	# 动画控制
	if is_on_floor():
		if is_zero_approx(direction):
			animation_player.play("idle")
		else:
			animation_player.play("running")
	else:
		animation_player.play("idle")
	
	# 翻转精灵
	if not is_zero_approx(direction):
		sprite_2d.flip_h = direction < 0
	
	# 移动角色
	move_and_slide()
