extends CharacterBody2D

# Player movement
@export var speed = 100
@export var gravity = 200
@export var jump = -175

var curr_jump_pos = 0
var last_dir_right
var jumping = false

signal animation_change(animation)

func horizontal_movement(is_jump):
	# if keys are pressed it will return 1 for ui_right, -1 for ui_left, and 0 for neither
	var horizontal_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	last_dir_right = horizontal_input > 0
	# horizontal velocity which moves player left or right based on input
	velocity.x = horizontal_input * speed
	if velocity.x != 0 && !is_jump:
		$AnimatedSprite2D.play('walk')
	elif !is_jump:
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
	#applies movement
	move_and_slide()
