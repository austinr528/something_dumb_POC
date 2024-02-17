extends "res://src/Character.gd"

# 0 = not sliding, -1 = sliding left, 1 = sliding right
var sliding = 0
var move_spd = 0
var turning = false

var RUN_VEL_MULT = 2.5
var FALLING_VEL_STEP = 10
var TOP_SPEED = 10
var ACC_RATE = 9
var ATTACK_VEL_STEP = 400
# The movement speed that determins when a skid stops
var SKID_STOP_VEL = 20

# vars for keeping track of attack and attack momentum
var attacking = false
var horizontal_attack_momentum = 0
var vertical_attack_momentum = 0

# vars for keeping track of damage flashing (60 frames basically)
var damaged = false
var damage_flicker_frames = 0
var anim_state = AnimationState.default

var jump_height: float = 100
var jump_time_to_peak: float = 0.5
var jump_time_to_descent: float = 0.4

var jump_velocity: float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
var jump_gravity: float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
var fall_gravity: float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0

func _get_gravity() -> float:
	return jump_gravity if velocity.y < 0.0 else fall_gravity

func _jump() -> float:
	return jump_velocity

func is_walking(x_vel):
	if x_vel == 0: return false
	if x_vel > 0:
		return x_vel < 109
	else:
		return x_vel > -109

func slide_hector():
	if is_on_floor():
		var angle = get_floor_normal().angle()
		if abs(angle) >= (PI/2)-0.005 and abs(angle) <= (PI/2)+0.005:
			sliding = 0
		else:
			if abs(angle) > PI/2:
				sliding = -1
				direction = -1
			elif abs(angle) < PI/2:
				sliding = 1
				direction = 1
			anim_state = AnimationState.slide
	else:
		sliding = 0

func jump_hector(delta: float):
	# TODO: if jump is pressed for more than x frames high jump
	# TODO: if jump is held fall slower no matter if falling from jump or walking
	#       off ledge
	var is_jumped := Input.is_action_just_pressed("ui_jump")
	# vertical movement velocity (down)
	velocity.y += (_get_gravity() * delta) + vertical_attack_momentum 
	if is_jumped && !jumping:
		jumping = true
		velocity.y = _jump()

	if jumping && velocity.y < 0.0:
		anim_state = AnimationState.jump_up
	elif jumping:
		anim_state = AnimationState.jump_down
	
	if !is_jumped && is_on_floor():
		jumping = false
		
func _get_max_spd() -> int:
	return (speed * RUN_VEL_MULT) if running else speed

# Returns true if we are turning, false otherwise
func _set_move_spd(horizontal_input: int):
	var acceloration = 0
	var max_spd = _get_max_spd()
	if direction == horizontal_input and horizontal_input != 0:
		acceloration = (max_spd - move_spd) / ACC_RATE
	elif turning || direction != horizontal_input and horizontal_input != 0:
		print('turning accel: {acc} move speed: {ms}'.format({ 'acc': acceloration, 'ms': move_spd }))
		horizontal_input = last_dir
		acceloration = -1 * (move_spd / ACC_RATE * 2)
		turning = true
		if move_spd < SKID_STOP_VEL:
			turning = false
	else:
		acceloration = -1 * (move_spd / ACC_RATE)
	move_spd += acceloration
	if move_spd < ACC_RATE:
		move_spd = 0

func _horizontal_movement(delta: float):
	running = Input.is_action_pressed("ui_run")
	# if keys are pressed it will return 1 for ui_right, -1 for ui_left, and 0 for neither
	var horizontal_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	
	# Sets the property move_spd
	_set_move_spd(horizontal_input)
	
	# Make sure we skid the same direction we went last, basically we need
	# to continue moving in the "wrong" direction for a few frames
	# this is set and unset by `_set_move_spd`
	if turning: horizontal_input = last_dir
	
	direction = horizontal_input
	if sliding != 0:
		horizontal_input = sliding
	# horizontal velocity which moves player left or right based on input
	velocity.x = (last_dir * move_spd) + horizontal_attack_momentum
	# print(velocity.x)
	if !jumping && !attacking:
		if is_walking(velocity.x):
			anim_state = AnimationState.walk
			if sliding != 0:
				_normalize_movement_to_slope()
		# TODO: this needs to take a bit more time to reach top speed
		elif velocity.x != 0:
			anim_state = AnimationState.run
			if sliding != 0:
				_normalize_movement_to_slope()
		else:
			anim_state = AnimationState.default

func _normalize_movement_to_slope():
	velocity.y = 100

#movement and physics
func _physics_process(delta: float):
	jump_hector(delta)

	# For now attack prevents/cancels jump
	if Input.is_action_just_pressed('ui_attack'):
		anim_state = AnimationState.attack
		attacking = true
	elif attacking && $CharSprite.get_frame() == 3:
		var horiz_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		var vert_input = Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
		print('horizontal: {h} vertical: {v} last_dir: {d}'.format({ 'h': horiz_input, 'v': vert_input, 'd': last_dir }))
		if horiz_input != 0:
			horizontal_attack_momentum = horiz_input * ATTACK_VEL_STEP
		if vert_input != 0:
			vertical_attack_momentum = vert_input * ATTACK_VEL_STEP
		attacking = false
	else:
		if horizontal_attack_momentum != 0:
			horizontal_attack_momentum /= (ACC_RATE * 3)
		if vertical_attack_momentum != 0:
			vertical_attack_momentum /= (ACC_RATE * 3)

	# we check that we aren't jumping or attacking
	_horizontal_movement(delta)

	# We want sliding to overwrite all other animation states
	slide_hector()
	
	# Set the animation based on physics
	_set_animation(anim_state)

	# orient the character to face the correct direction
	if direction > 0 :
		$CharSprite.flip_h = false
		last_dir = 1
	elif direction < 0:
		$CharSprite.flip_h = true
		last_dir = -1
		
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

	#applies movement
	move_and_slide()


# Signal handlers
#
#

func take_damage():
	print('damage')
	damaged = true
