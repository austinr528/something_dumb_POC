extends CharacterBody2D

class_name Hero

# Player movement
@export var speed = 100
@export var gravity = 350
@export var jump = -175

var curr_jump_pos = 0
var last_dir_right = true
var direction = 0
var jumping = false
var sprite_angle = 0.0

signal animation_change(animation)

func horizontal_movement(is_jump):
	# if keys are pressed it will return 1 for ui_right, -1 for ui_left, and 0 for neither
	var horizontal_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction = horizontal_input
	# horizontal velocity which moves player left or right based on input
	velocity.x = horizontal_input * speed
	print(velocity.x)
	if !is_jump:
		if velocity.x != 0:
			$AnimatedSprite2D.play('walk')
			emit_signal('animation_change', 'walk')
			_normalize_movement_to_slope()
		else:
			$AnimatedSprite2D.play('default')
			emit_signal('animation_change', 'default')

func _normalize_movement_to_slope():
	if direction > 0:
		if sprite_angle > 0:
			# if we are going down hill we have to fix velocity.y to stay  attached
			velocity.y = 100
		else:
			pass
	elif direction < 0:
		if sprite_angle > 0:
			pass
		else:
			# if we are going down hill we have to fix velocity.y to stay  attached
			velocity.y = 100

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
		emit_signal('animation_change', 'jump_up')
	elif jumping:
		print('down')
		$AnimatedSprite2D.play('jump_down')
		emit_signal('animation_change', 'jump_down')
	
	if !is_jumped && is_on_floor():
		jumping = false
		
	horizontal_movement(jumping)
	
	# orient the character to face the correct direction
	if direction > 0 :
		$AnimatedSprite2D.flip_h = false
		last_dir_right = true
	elif direction < 0:
		$AnimatedSprite2D.flip_h = true
		last_dir_right = false
		
	# Determine the angle of the character
	if is_on_floor():
		var angle = get_floor_normal().angle()
		
		if angle != sprite_angle:
			rotation = angle + (PI/2)
			sprite_angle = rotation

	else:
		rotation = 0
	#applies movement
	move_and_slide()
