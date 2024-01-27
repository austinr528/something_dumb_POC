extends CharacterBody2D

# Player movement
@export var speed = 100
@export var gravity = 200
@export var jump = -300

func horizontal_movement():
	# if keys are pressed it will return 1 for ui_right, -1 for ui_left, and 0 for neither
	var horizontal_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	# horizontal velocity which moves player left or right based on input
	velocity.x = horizontal_input * speed	

#movement and physics
func _physics_process(delta):
	var is_jumped := Input.is_action_just_pressed("ui_jump")
	# vertical movement velocity (down)
	velocity.y += gravity * delta
	if is_jumped:
		print('Jump')
		velocity.y = jump
	# horizontal movement processing (left, right)
	horizontal_movement()
	#applies movement
	move_and_slide()
