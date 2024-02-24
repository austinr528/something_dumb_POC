extends "res://src/Character.gd"

# 0 = not sliding, -1 = sliding left, 1 = sliding right
var sliding = 0
var move_spd = 0
var turning = false
var ducking = false

var RUN_VEL_MULT = 2.5
var FALLING_VEL_STEP = 10
var TOP_SPEED = 10
var ACC_RATE = 9
var ATTACK_VEL_STEP = 400
# The movement speed that determins when a skid stops
var SKID_STOP_VEL = 20
# The proportion ducking slows your x velocity
var DUCK_VEL_DIV = 4

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

const TURN_DUST = preload("res://Scenes/turn_dust_cloud.tscn")
var dust_arr: Array = []

func _get_gravity() -> float:
	return jump_gravity if velocity.y < 0.0 else fall_gravity

func _jump() -> float:
	return jump_velocity

func is_walking(x_vel):
	if x_vel == 0: return false
	if x_vel > 0:
		return x_vel < 100 + ACC_RATE
	else:
		return x_vel > -100 - ACC_RATE

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
		_set_audio(AudioState.jump)
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

# Sets the movement speed which is used for velocity, also sets turning to true
# when we change direction
func _set_move_spd(horizontal_input: int):
	var acceloration = 0
	var max_spd = _get_max_spd()
	if direction == horizontal_input and horizontal_input != 0:
		acceloration = (max_spd - move_spd) / ACC_RATE
	elif turning || direction != horizontal_input and horizontal_input != 0:
		print('turning accel: {acc} move speed: {ms}'.format({ 'acc': acceloration, 'ms': move_spd }))
		horizontal_input = last_dir
		acceloration = -1 * (move_spd / ACC_RATE * 2)
		# We show the turn animation if we are not jumping/falling
		turning = true && is_on_floor()
		if move_spd < SKID_STOP_VEL:
			turning = false
	else:
		acceloration = -1 * (move_spd / ACC_RATE)
	move_spd += acceloration
	if move_spd < ACC_RATE:
		move_spd = 0
	print('move speed: {rr} acc: {rd}'.format({ 'rr': move_spd, 'rd': acceloration, }))

func _horizontal_movement(delta: float):
	running = Input.is_action_pressed("ui_run")
	# if keys are pressed it will return 1 for ui_right, -1 for ui_left, and 0 for neither
	var horizontal_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	
	# Sets the property move_spd
	_set_move_spd(horizontal_input)
	
	# Make sure we skid the same direction we went last, basically we need
	# to continue moving in the "wrong" direction for a few frames
	# this is set and unset by `_set_move_spd`
	if turning:
		horizontal_input = last_dir
	
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
	var frame = 0

	jump_hector(delta)

	var vert_input = Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
	# For now attack prevents/cancels jump
	if Input.is_action_just_pressed('ui_attack'):
		_set_audio(AudioState.attack)
		anim_state = AnimationState.attack
		attacking = true
	elif attacking && (
		($CharSprite.get_animation() == 'attack' && $CharSprite.get_frame() == 3)
		|| $CharSprite.get_animation() != 'attack'
		|| true
	):
		attacking = false
		var horiz_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")

		print('horizontal: {h} vertical: {v} last_dir: {d}'.format({ 'h': horiz_input, 'v': vert_input, 'd': last_dir }))

		if horiz_input != 0:
			horizontal_attack_momentum = horiz_input * ATTACK_VEL_STEP
		if vert_input != 0:
			vertical_attack_momentum = vert_input * ATTACK_VEL_STEP
	else:
		if horizontal_attack_momentum != 0:
			horizontal_attack_momentum /= (ACC_RATE * 3)
		if vertical_attack_momentum != 0:
			vertical_attack_momentum /= (ACC_RATE * 3)

	# we check that we aren't jumping or attacking in _horizontal_movement
	_horizontal_movement(delta)
	
	# we need to reset the animation state to turning so it overrides
	# default/walk/run... could maybe do this in _horizontal_movement at the end
	if turning:
		# TODO: we do this a lot which doesn't look terrible (maybe)
		var dust = TURN_DUST.instantiate()
		dust.global_position.y = (global_position.y +
			($CharSprite.get_sprite_frames().get_frame_texture('walk', 0).get_height() - 3))
		dust.global_position.x = global_position.x
		get_parent().add_child(dust)
		dust_arr.push_back(dust)
		# Finaly set the anim_state (mostly this comment is to visually distinguish since no shit)
		anim_state = AnimationState.turn
		# TODO: this fixes a bug where if you attacked then turned (maybe jumped)
		# you would could stick attacking to forever be true and you could lock in any animation
		# shorter than 3 frames (also using a specific frame and not an animation done signal is shitty)
		attacking = false
	# once animation is done delete
	for d in dust_arr:
		if !d.is_playing():
			# TODO: The is exactly what you shouldn't do in a for loop...
			dust_arr.erase(d)
			d.queue_free()

	# TODO: this is not great, it should be a bit more state machine-y
	#
	# We start ducking, play the duck_down animation
	if vert_input < 0 && !attacking && is_on_floor():
		ducking = true
		anim_state = AnimationState.duck_down
		velocity.x /= DUCK_VEL_DIV
	# we are still ducking just play the last frame over and over
	elif ducking && vert_input < 0 && $CharSprite.get_frame() == 2:
		frame = 2
	# we are getting up from ducking lay duck_up
	elif ducking && vert_input >= 0:
		anim_state = AnimationState.duck_up
		# The duck up animation is done we can now be whatever
		if $CharSprite.get_frame() == 2:
			ducking = false

	# We want sliding to overwrite all other animation states
	slide_hector()
	
	# Set the animation based on physics
	_set_animation(anim_state, frame)

	# orient the character to face the correct direction
	if direction > 0 :
		$CharSprite.flip_h = false
		last_dir = 1
	elif direction < 0:
		$CharSprite.flip_h = true
		last_dir = -1

	# This could also be done with a shader on the CharSprite I think
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

	#applies movement and also check if touched something that damges
	if move_and_slide():
		# This is another option, instead of signals and sprites
		# (a tileMap can't use signals or Area2D's)
		for i in range(get_slide_collision_count()):
			var collision: KinematicCollision2D = get_slide_collision(i)
			var n: String = collision.get_collider().name
			if n.contains('Spike'):
				damaged = true

# Signal handlers
#
#

func take_damage():
	print('damage')
	damaged = true
