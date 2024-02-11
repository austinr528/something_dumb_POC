extends "res://src/Character.gd"

# 0 = not sliding, -1 = sliding left, 1 = sliding right
var sliding = 0

func _horizontal_movement(is_jump):
	# if keys are pressed it will return 1 for ui_right, -1 for ui_left, and 0 for neither
	var horizontal_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction = horizontal_input
	if sliding != 0:
		horizontal_input = sliding
	# horizontal velocity which moves player left or right based on input
	velocity.x = horizontal_input * speed
	if !is_jump:
		if velocity.x != 0:
			$CharSprite.play('walk')
			emit_signal('animation_change', 'walk')
			if sliding != 0:
				_normalize_movement_to_slope()
		else:
			$CharSprite.play('default')
			emit_signal('animation_change', 'default')

func _normalize_movement_to_slope():
	velocity.y = 100

#movement and physics
func _physics_process(delta):
	var is_jumped := Input.is_action_just_pressed("ui_jump")
	# vertical movement velocity (down)
	velocity.y += gravity * delta
	if is_jumped:
		jumping = true
		curr_jump_pos = position.y
		velocity.y = jump

	if jumping && curr_jump_pos > position.y:
		curr_jump_pos = position.y
		$CharSprite.play('jump_up')
		emit_signal('animation_change', 'jump_up')
	elif jumping:
		$CharSprite.play('jump_down')
		emit_signal('animation_change', 'jump_down')
	
	if !is_jumped && is_on_floor():
		jumping = false
		
	_horizontal_movement(jumping)
		
	# Determine the angle of the character
	if is_on_floor():
		var angle = get_floor_normal().angle()
		print(angle)
		print(PI/2)
		if abs(angle) >= (PI/2)-0.005 and abs(angle) <= (PI/2)+0.005:
			sliding = 0
		else:
			if abs(angle) > PI/2:
				sliding = -1
				direction = -1
			elif abs(angle) < PI/2:
				sliding = 1
				direction = 1
			$CharSprite.play('slide')
			emit_signal('animation_change', 'slide')
	else:
		sliding = 0

		# orient the character to face the correct direction
	if direction > 0 :
		$CharSprite.flip_h = false
		last_dir_right = true
	elif direction < 0:
		$CharSprite.flip_h = true
		last_dir_right = false
	#applies movement
	move_and_slide()

func take_damage():
	print('damage') 
