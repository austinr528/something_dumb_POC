extends "res://src/Character.gd"

var RUN_VEL_MULT = 2.5

# The number of frames it takes to stop, this isn't quite accurte
# since we also never slow down faster than MIN_DECEL units of acceleration
var FRAMES_TO_STOP: float = 9.0
var ACC_RATE: float = 60 / FRAMES_TO_STOP
var MIN_DECEL: float = 1
var FALL_VEL_MAX: float = 666.6


# The amount of velocity added when attacking in any horizontal direction
# (only applies to `velocity.x`)
var ATTACK_VEL_STEP = 300
# The movement speed that determins when a skid stops
var SKID_STOP_VEL = 20
# The proportion ducking slows your x velocity
var DUCK_VEL_DIV = 4

# Vars for movement state and speed
# 0 = not sliding, -1 = sliding left, 1 = sliding right
var sliding = 0
var move_spd: float = 0.0
var turning = false
var ducking = false

# vars for keeping track of attack and attack momentum
#
# The base attack is the belt + momentum in the direction pressed left or right
# pressing down gives upward momentum, up gives downward
var attacking = false
var horizontal_attack_momentum = 0
var vertical_attack_momentum = 0

# vars for keeping track of damage flashing (60 frames basically)
var damaged = false
var damage_flicker_frames = 0

# Hecotor's AnimationState, we start standing (default)
var anim_state = AnimationState.default

var jump_height: float = 125.0
var jump_time_to_peak: float = 0.6
var jump_time_to_descent: float = 0.3

var jump_velocity: float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
var jump_gravity: float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
var fall_gravity: float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0

const TURN_DUST = preload('res://Scenes/turn_dust_cloud.tscn')
var dust_arr: Array = []

const BELT = preload('res://Scenes/belt_animated_sprite.tscn')
var belt: AnimatedSprite2D = null

var on_pipe: bool = false

func _get_gravity() -> float:
	return jump_gravity if velocity.y < 0.0 else fall_gravity

func _jump() -> float:
	return jump_velocity

func _fall_vel_max(jmp_press: bool) -> float:
	return FALL_VEL_MAX if not jmp_press else FALL_VEL_MAX / 1.5

# TODO: this probably needs some refinement, I think 175 is the 4th tick after
# stepping of a ledge
func _coyote_frames() -> bool:
	return $LeftRay.is_colliding() || $CenterRay.is_colliding() || $RightRay.is_colliding()

func is_walking(x_vel):
	if x_vel == 0: return false
	if x_vel > 0:
		return x_vel < SPEED
	else:
		return x_vel > -SPEED

func slide_hector():
	# TODO: we need to differentiate between sliding down a slope and sliding off
	# a ledge (corner) this should not be considered sliding
	#
	# Use RayCast2D to determine when we are on a ledge (see BounceBaddie.gd)
	const EPSILON: float = 0.05
	if is_on_floor():
		var angle = get_floor_normal().angle()
		if abs(angle) >= (PI/2)- EPSILON and abs(angle) <= (PI/2) + EPSILON:
			sliding = 0
		else:
			print(abs(angle))
			if abs(angle) >= ((3 * PI) / 4) -  EPSILON and abs(angle) <= ((3 * PI) / 4) + EPSILON:
				sliding = -1
				direction = -1
				_normalize_movement_to_slope()
			elif abs(angle) >= (PI / 4) -  EPSILON and abs(angle) <= (PI / 4) + EPSILON:
				sliding = 1
				direction = 1
				_normalize_movement_to_slope()
			else:
				# We return to prevent setting the animation state to sliding which caused a few problems
				#   - fast falling off the ledge
				#   - the slide animation  
				print('OOPS')
				return

			turning = false
			anim_state = AnimationState.slide
		
	else:
		sliding = 0

func jump_hector(delta: float):
	# TODO: if jump is pressed for more than x frames high jump
	# TODO: if jump is held fall slower no matter if falling from jump or walking
	#       off ledge
	var is_jumped := Input.is_action_just_pressed("ui_jump")
	
	# if we get a belt pop bounce we want a full jump
	#
	# This is true for 3 frames of the attack animation, we may want to make this
	# more precise (only reset once)
	if attacking:
		velocity.y = 0
	# vertical movement velocity (down)
	velocity.y += (_get_gravity() * delta) + vertical_attack_momentum
	# TODO: is this good... or bad
	velocity.y = min(velocity.y, _fall_vel_max(Input.is_action_pressed('ui_jump')))

	# if we just pressed jump and are not already jumping, we must either be on
	# the ground or in the first few frames of stepping of a ledge
	if is_jumped && !jumping && (did_bounce || _coyote_frames()):
		_set_audio(AudioState.jump)
		# A full jump is 4 blocks or 2 Hectors high
		jumping = true
		velocity.y = _jump()

	if jumping && velocity.y < 0.0:
		if Input.is_action_just_released('ui_jump'):
			# Stop jumping upwards this is a short jump now
			#
			# The total jump height works out to 2 blocks or 1 Hector
			velocity.y += -(_jump()) / 3.0
		if !ducking:
			anim_state = AnimationState.jump_up
	elif jumping && !ducking:
		anim_state = AnimationState.jump_down
	
	if !is_jumped && is_on_floor():
		jumping = false
		did_bounce = false


func _get_max_spd() -> float:
	return (SPEED * RUN_VEL_MULT) if running else SPEED

# Sets the movement speed which is used for velocity, also sets turning to true
# when we change direction
func _set_move_spd(horizontal_input: int, delta: float):
	# TODO: if we want to get rid of run mess with this stuff 
	var acceloration = 0
	var max_spd = _get_max_spd()
	if direction == horizontal_input and horizontal_input != 0:
		acceloration = ((max_spd - move_spd) * (delta * ACC_RATE))
	elif turning || direction != horizontal_input and horizontal_input != 0:
		horizontal_input = last_dir
		acceloration = -1 * max((move_spd * (delta * ACC_RATE * 2)), MIN_DECEL)
		# We show the turn animation if we are not jumping/falling
		turning = true && is_on_floor()
		if move_spd < SKID_STOP_VEL:
			turning = false
	else:
		acceloration = -1 * max((move_spd * (delta * ACC_RATE)), MIN_DECEL)

	move_spd += acceloration
	if move_spd < (delta * ACC_RATE):
		move_spd = 0
	#print('speed: {d} rate: {rr} acc: {rd}'.format({ 'd': (move_spd), 'rr': delta * ACC_RATE, 'rd': acceloration, }))

func _horizontal_movement(delta: float):
	running = Input.is_action_pressed("ui_run")
	# if keys are pressed it will return 1 for ui_right, -1 for ui_left, and 0 for neither
	var horizontal_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	
	# Sets the property move_spd
	_set_move_spd(horizontal_input, delta)
	
	# Make sure we skid the same direction we went last, basically we need
	# to continue moving in the "wrong" direction for a few frames
	# this is set and unset by `_set_move_spd`
	if turning:
		horizontal_input = last_dir

	# this means we are sliding
	if sliding != 0:
		horizontal_input = sliding
		last_dir = sliding
		# Sliding makes you quickly reach max speed
		move_spd += (SPEED * RUN_VEL_MULT) * (delta * ACC_RATE)

	# This is to fix when sliding (probably any momentum gain) where there is no
	# user direction set we would get stuck in a turn animation, we now let momentum
	# define direction if user has not specified with horizontal_input
	if horizontal_input == 0:
		if velocity.x > 0:
			horizontal_input = 1
		elif velocity.x < 0:
			horizontal_input = -1

	direction = horizontal_input

	# horizontal velocity which moves player left or right based on input
	velocity.x = (last_dir * move_spd) + horizontal_attack_momentum

	if !jumping && !attacking && sliding == 0:
		if is_walking(velocity.x):
			anim_state = AnimationState.walk
		# TODO: this needs to take a bit more time to reach top speed
		elif velocity.x != 0:
			anim_state = AnimationState.run
		else:
			anim_state = AnimationState.default

func _normalize_movement_to_slope():
	velocity.y = (SPEED * RUN_VEL_MULT)

func _attack_hector(delta, vert_input):
	# For now attack prevents/cancels jump
	if Input.is_action_just_pressed('ui_attack'):
		anim_state = AnimationState.attack
		attacking = true

	elif attacking && (
		($CharSprite.get_animation() == 'attack' && $CharSprite.get_frame() == 3)
		|| $CharSprite.get_animation() != 'attack'
		#|| true
	):
		attacking = false
		var horiz_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		
		var yflip = 90 if vert_input > 0 else 0 if vert_input == 0 else -90 
		var xflip = 1 if last_dir > 0 else -1 
		var sprite_y_pos = $CharSprite.get_sprite_frames().get_frame_texture($CharSprite.animation, $CharSprite.frame).get_height()
		belt = BELT.instantiate()
		belt.scale *= xflip
		# this one we can get rid of once we have the animations
		belt.rotation = yflip
		
		get_parent().add_child(belt)
		belt.play()
		if horiz_input != 0:
			horizontal_attack_momentum = horiz_input * ATTACK_VEL_STEP
		# when belt pop down get a jump
		if vert_input < 0:
			vertical_attack_momentum = -(vert_input * _jump())
	else:
		if horizontal_attack_momentum != 0:
			horizontal_attack_momentum += -1 * horizontal_attack_momentum * (delta * ACC_RATE)
			if abs(horizontal_attack_momentum) < ACC_RATE:
				horizontal_attack_momentum = 0
		if vertical_attack_momentum != 0:
			vertical_attack_momentum = 0

	if belt != null:
		var sprite_y_pos = $CharSprite.get_sprite_frames().get_frame_texture($CharSprite.animation, $CharSprite.frame).get_height()
		belt.flip_v = last_dir < 0
		var belt_x_pos_modi = 54 * last_dir
		belt.position.y += (position.y + sprite_y_pos - 31) - belt.position.y
		belt.position.x += (position.x + belt_x_pos_modi) - belt.position.x
		
		if belt.get_frame() > belt.get_sprite_frames().get_frame_count('default') * .75:
			_set_audio(AudioState.attack)

func _move_in_pipe(data: TileData):
	if data != null && is_on_floor():
		# TODO: set skew based on TileSet custom data
		var shade: ShaderMaterial = $CharSprite.get_material()
		# shade.set_shader_parameter('deformation', Vector2(1, 0.1))

		var move: Vector2 = data.get_custom_data('direction')
		if move == null:
			move = Vector2i()
		match move:
			Vector2.UP, Vector2.DOWN:
				velocity.y = move.y * 100
			Vector2.RIGHT, Vector2.LEFT:
				velocity.x = move.x * -100
		position += move * 2.0

func pipe_movement():
	var collision: KinematicCollision2D = move_and_collide(velocity, true)
	if collision && collision.get_collider().name.contains('PipeTileMap'):
		var map: TileMap = collision.get_collider()
		var coords: Vector2 = map.get_coords_for_body_rid(collision.get_collider_rid())
		var data: TileData = map.get_cell_tile_data(0, coords)
		_move_in_pipe(data)
	else:
		# Turn off the skew shader
		# TODO: this could probalby be moved in to custom data on the TileSet cell
		# $CharSprite.get_material().set_shader_parameter('deformation', Vector2(0, 0));
		on_pipe = false

# Movement and Physics
func _physics_process(delta: float):
	# We are in a pipe, move along the tile set bounds
	if on_pipe:
		pipe_movement()
		_set_animation(AnimationState.default)
		return

	var frame = 0

	jump_hector(delta)

	var vert_input = Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
	_attack_hector(delta, vert_input)

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
	# we are getting up from ducking play duck_up
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

	if Global.DEBUG_ALL: _debug_stuff(delta)
	# Applies movement and also check if touched something that damges
	if move_and_slide():
		# TODO: figure out a better way to signal interaction with TileMaps
		#       - One idea is to use groups and a signal, not sure which direction though 
		# This is another option, instead of signals and sprites
		# (a tileMap can't use signals or Area2D's)
		for i in range(get_slide_collision_count()):
			var collision: KinematicCollision2D = get_slide_collision(i)
			var n: String = collision.get_collider().name
			# TODO: this is the only thing I don't love about this
			#       `n.contains('Spike')` feels brittle
			if n.contains('Spike'):
				damaged = true
			if n.contains('PipeTileMap'):
				var map: TileMap = collision.get_collider()
				var coords: Vector2 = map.get_coords_for_body_rid(collision.get_collider_rid())
				var data: TileData = map.get_cell_tile_data(0, coords)
				if data != null && is_on_floor() && data.get_custom_data('PipeEnter') == 'entry':
					on_pipe = true
					_move_in_pipe(data)


# Signal handlers
#
#

func take_damage():
	print('damage')
	damaged = true

var accum_delta: float = 0.0
func _debug_stuff(delta: float):
	if (Global.DEBUG_GHOST()):
		# Only emit ghost trail copy every 12ish frames
		if accum_delta + delta > .125:
			accum_delta = 0.0
			var ghost = GHOST.instantiate()
			get_parent().add_child(ghost)
			ghost.position = position
			ghost.texture = $CharSprite.get_sprite_frames().get_frame_texture($CharSprite.animation, $CharSprite.frame)
			ghost.flip_h = $CharSprite.flip_h
			ghost.flip_v = $CharSprite.flip_v
		else:
			accum_delta += delta

func _unhandled_input(event):
	if event is InputEventJoypadButton:
		print(event)
		if event.pressed && event.button_index == JOY_BUTTON_START:
			Global._DEBUG_ALL = not Global._DEBUG_ALL
			# get_tree().quit()
