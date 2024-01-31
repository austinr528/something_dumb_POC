extends CharacterBody2D

# Player movement
@export var speed = 100
@export var gravity = 200
@export var jump = -175

var curr_jump_pos = 0
var last_dir_right
var jumping = false
var sprite_angle = 0.0

signal animation_change(animation)

func horizontal_movement(is_jump):
	# if keys are pressed it will return 1 for ui_right, -1 for ui_left, and 0 for neither
	var horizontal_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	last_dir_right = horizontal_input > 0
	# horizontal velocity which moves player left or right based on input
	velocity.x = horizontal_input * speed
	if !is_jump:
		if velocity.x != 0:
			$AnimatedSprite2D.play('walk')
		else:
			$AnimatedSprite2D.play('default')

#movement and physics
func _physics_process(delta):
	var is_jumped := Input.is_action_just_pressed("ui_jump")
	# vertical movement velocity (down)
	velocity.y += gravity * delta
	if is_jumped:
		jumping = true
		curr_jump_pos = position.y
		print('Jump')
		velocity.y = jump

	if jumping && curr_jump_pos > position.y:
		print(curr_jump_pos, '   ', position.y)	
		curr_jump_pos = position.y
		$AnimatedSprite2D.play('jump_up')		
	elif jumping:
		print('down')
		$AnimatedSprite2D.play('jump_down')
	
	if !is_jumped && is_on_floor():
		jumping = false
	# horizontal movement processing (left, right)
	horizontal_movement(jumping)
	
	if last_dir_right:
		$AnimatedSprite2D.flip_h = false
	else:
		$AnimatedSprite2D.flip_h = true
		
	print(get_floor_angle(), ' ', get_floor_normal().angle())
	if is_on_floor():
		var angle = get_floor_angle()
		if angle != sprite_angle:
			var angle_delta
			if last_dir_right: angle_delta = (sprite_angle - angle)
			else: angle_delta = (angle - sprite_angle)
			$AnimatedSprite2D.rotate(angle_delta)
			sprite_angle = angle
	else:
		$AnimatedSprite2D.rotation = 0
	#applies movement
	move_and_slide()
