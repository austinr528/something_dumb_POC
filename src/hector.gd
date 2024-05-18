extends "res://src/Character.gd"

var RUN_VEL_MULT = 2.5

# The number of frames it takes to stop, this isn't quite accurte
# since we also never slow down faster than MIN_DECEL units of acceleration
var FRAMES_TO_STOP: float = 9.0
var ACC_RATE: float = 60 / FRAMES_TO_STOP
var MIN_DECEL: float = 1
var FALL_VEL_MAX: float = 666.6


# The amount of velocity added when dashing in any horizontal direction
# (only applies to `velocity.x`)
var DASH_HORIZ_MULT = 2.0
var DASH_VERT_MULT = 1.5
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

# vars for keeping track of dash and dash momentum
#
# The base dash is the belt + momentum in the direction pressed left or right
# pressing down gives upward momentum, up gives downward
var dashing: bool = false
var dash_frames: int = 0

# vars for keeping track of damage flashing (60 frames basically)
var damaged = false
var damage_flicker_frames = 0

# Hecotor's AnimationState, we start standing (default)
var anim_state = AnimationState.default

var jump_height: float = 128.0
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

func _apply_slide_animation():
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
				return
			turning = false
			anim_state = AnimationState.slide
	else:
		sliding = 0

func _jump_hector(delta: float):
	var is_jumped := Input.is_action_just_pressed("ui_jump")


	# vertical movement velocity (down)
	velocity.y += (_get_gravity() * delta)
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

func _apply_turn_animation():
	if turning:
		# TODO: we instantiate numberious dust clouds (one each tick) which doesn't look terrible (maybe)
		var dust = TURN_DUST.instantiate()
		dust.global_position.y = (global_position.y +
			($CharSprite.get_sprite_frames().get_frame_texture('walk', 0).get_height() - 3))
		dust.global_position.x = global_position.x
		get_parent().add_child(dust)
		dust_arr.push_back(dust)
		# Finaly set the anim_state (mostly this comment is to visually distinguish since no shit)
		anim_state = AnimationState.turn
		# TODO: this fixes a bug where if you dashed then turned (maybe jumped)
		# you would could stick dashing to forever be true and you could lock in any animation
		# shorter than 3 frames (also using a specific frame and not an animation done signal is shitty)
		dashing = false
	# Delete any lingering dust
	for d in dust_arr:
		if !d.is_playing():
			# TODO: The is exactly what you shouldn't do in a for loop...
			dust_arr.erase(d)
			d.queue_free()

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
	
	# Sets the property move_spd, turning
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
	velocity.x = (last_dir * move_spd)

	if !jumping && sliding == 0:
		if is_walking(velocity.x):
			anim_state = AnimationState.walk
		# TODO: this needs to take a bit more time to reach top speed
		elif velocity.x != 0:
			anim_state = AnimationState.run
		else:
			anim_state = AnimationState.default

func _normalize_movement_to_slope():
	velocity.y = (SPEED * RUN_VEL_MULT)

var down_dash: bool = false
func _dash_hector(delta, vert_input):
	# For now dash prevents/cancels jump
	if not dashing && Input.is_action_just_pressed('ui_dash'):
		dash_frames = 0
		dashing = true
		down_dash = vert_input < 0
	elif dashing:
		dash_frames += 1
		var horiz_input = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")

		if down_dash && vert_input > 0:
			dashing = false
			down_dash = false
			return

		velocity = Vector2(
			(horiz_input * SPEED * RUN_VEL_MULT * DASH_HORIZ_MULT),
			(vert_input * jump_velocity * DASH_VERT_MULT)
		)

		if dash_frames % 2 == 0:
			var dash_ghost = GHOST.instantiate()
			dash_ghost.set_trail_type(0.5, Color(0.25, 1, 1, 0.4))
			get_parent().add_child(dash_ghost)
			dash_ghost.position = position
			dash_ghost.texture = $CharSprite.get_sprite_frames().get_frame_texture($CharSprite.animation, $CharSprite.frame)
			dash_ghost.flip_h = $CharSprite.flip_h
			dash_ghost.flip_v = $CharSprite.flip_v

	if dashing && dash_frames > 15 && !down_dash:
		velocity.y = 0
		dashing = false
	elif down_dash && is_on_floor():
		dashing = false
		down_dash = false

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

func _pipe_movement():
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

# Called when we have collided with some to check if the collision alters our state
#
# This happens with spikes for example.
# - sets damaged and on_pipe
func _check_for_tile_collisions():
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

# Flickers the character for a set number of frames (currently 60)
# once reached we set damaged to false
func _apply_damage():
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

func _apply_ducking_animation(vert_input: int):
	if vert_input < 0 && !dashing && is_on_floor():
		ducking = true
		anim_state = AnimationState.duck_down
		velocity.x /= DUCK_VEL_DIV
	# we are still ducking just play the last frame over and over
	# elif ducking && vert_input < 0 && $CharSprite.get_frame() == 2:
	# we are getting up from ducking play duck_up
	elif ducking && vert_input >= 0:
		anim_state = AnimationState.duck_up
		# The duck up animation is done we can now be whatever
		if $CharSprite.get_frame() == 2:
			ducking = false

# Movement and Physics
func _physics_process(delta: float):
	# We are in a pipe, move along the tile set bounds (TODO: if we keep pipes this needs
	# to be re done)
	if on_pipe:
		_pipe_movement()
		_set_animation(AnimationState.default)
		return

	_jump_hector(delta)

	var vert_input: int = Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
	
	# we check that we aren't jumping in _horizontal_movement
	_horizontal_movement(delta)
	
	# dashing overrides all momentum and gravity (it resets velocity)
	_dash_hector(delta, vert_input)
	
	# we need to reset the animation state to turning so it overrides
	# default/walk/run... could maybe do this in _horizontal_movement at the end
	_apply_turn_animation()
	# ducking overrides most states (you can't be jumping and duck)
	# We start ducking, play the duck_down animation
	_apply_ducking_animation(vert_input)
	# We want sliding to overwrite all other animation states
	_apply_slide_animation()
	# Set the animation based on physics
	_set_animation(anim_state)
	_apply_damage()

	if Global.DEBUG_ALL: _debug_stuff(delta)

	# orient the character to face the correct direction
	if direction > 0 :
		$CharSprite.flip_h = false
		last_dir = 1
	elif direction < 0:
		$CharSprite.flip_h = true
		last_dir = -1

	# Applies movement and also check if touched something that damges
	if move_and_slide():
		_check_for_tile_collisions()


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
			ghost.set_trail_type(3.0, Color(1, 1, 1, 0.4))
			get_parent().add_child(ghost)
			ghost.position = position
			ghost.texture = $CharSprite.get_sprite_frames().get_frame_texture($CharSprite.animation, $CharSprite.frame)
			ghost.flip_h = $CharSprite.flip_h
			ghost.flip_v = $CharSprite.flip_v
		else:
			accum_delta += delta

signal emit_debug_change()
func _unhandled_input(event):
	if event is InputEventJoypadButton:
		print(event)
		if event.pressed && event.button_index == JOY_BUTTON_START:
			Global._DEBUG_ALL = not Global._DEBUG_ALL
			queue_redraw()
			emit_signal("emit_debug_change")
