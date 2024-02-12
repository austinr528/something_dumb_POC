extends "res://src/Character.gd"

# 0 = not sliding, -1 = sliding left, 1 = sliding right
var sliding = 0

# vars for keeping track of attack and attack momentum
var attacking = false
var momentum = 0

# vars for keeping track of damage flashing (60 frames basically)
var damaged = false
var damage_flicker_frames = 0

func is_walking(x_vel):
	if x_vel == 0: return false
	if x_vel > 0:
		return x_vel < 101
	else:
		return x_vel > -101
		

func _horizontal_movement(is_jump):
	running = Input.is_action_pressed("ui_run")
	# if keys are pressed it will return 1 for ui_right, -1 for ui_left, and 0 for neither
	var horizontal_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction = horizontal_input
	if sliding != 0:
		horizontal_input = sliding
	# horizontal velocity which moves player left or right based on input
	velocity.x = horizontal_input * (speed + momentum)
	# TODO: add some momentum, when we stop inputing a direction he should
	# slide a bit more in the last direction especially if running
	if running:
		velocity.x *= 2

	print(velocity.x)
	if !is_jump && !attacking:
		if is_walking(velocity.x):
			$CharSprite.play('walk')
			emit_signal('animation_change', 'walk')
			if sliding != 0:
				_normalize_movement_to_slope()
		# TODO: this needs to take a bit more time to reach top speed
		elif velocity.x != 0:
			$CharSprite.play('run')
			emit_signal('animation_change', 'run')
			if sliding != 0:
				_normalize_movement_to_slope()
		else:
			$CharSprite.play('default')
			emit_signal('animation_change', 'default')

func _normalize_movement_to_slope():
	velocity.y = 100

#movement and physics
func _physics_process(delta):
	# TODO: do we want a short jump and a higher jump (determined by how long the
	# button is held?
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
		# TODO: There is probably a better more mathy way to do this
		velocity.y += 10
		$CharSprite.play('jump_down')
		emit_signal('animation_change', 'jump_down')
	
	if !is_jumped && is_on_floor():
		jumping = false
		
	if Input.is_action_just_pressed('ui_attack'):
		$CharSprite.play('belt')
		emit_signal('animation_change', 'belt')
		attacking = true
	elif attacking && $CharSprite.get_frame() == 3:
		attacking = false
		momentum = 150
	else:
		if momentum > 0: momentum -= 5
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
		
	if damaged && damage_flicker_frames < 60:
		damage_flicker_frames += 1
		if damage_flicker_frames % 6 == 0:
			$CharSprite.modulate = Color(1, 0.2, 0.2, .6)
		else:
			$CharSprite.modulate = Color(1, 1, 1, .4)
	elif damaged:
		damaged = false
		damage_flicker_frames = 0
		$CharSprite.modulate = Color(1, 1, 1, 1)
		
	
		
	## Determine the angle of the character
	#if is_on_floor():
		#var angle = get_floor_normal().angle()
		#if angle != sprite_angle:
			#rotation = angle + (PI/2)
			#sprite_angle = rotation
	#else:
		#rotation = 0

	#applies movement
	move_and_slide()

func take_damage():
	print('damage')
	damaged = true
