extends CharacterBody2D

@export var speed: float = 100.0
var gravity: float = 350.0
@export var jump: float = -175.0

var limit_movement = 0
var start_pos = 0
var direction = -1

func _init():
	add_to_group('BounceEnemy')

# TODO: this is dumb has to be a better way, I couldn't figure out how to
#       have member variables that base can override (google said it was difficult/impossible)
func get_speed(): pass
func timer_process(): pass
func animation_process(): pass
func bounced_on(): pass
# For some reason $AnimatedSprite2D/VisibleOnScreenNotifier2D is null here
# so this has to be a method
func is_on_screen() -> bool:
	var msg = 'Called from base class `BounceEnemy` needs override in `' + name + '`'
	assert(false, msg) 
	return false

func _draw():
	if Global.DEBUG:
		var to_add = $Direction.scale.x * 10
		draw_line($Direction.position + Vector2(to_add, 0), $Direction.position + Vector2(to_add, 40), Color.WHITE, 1)

# Detect when we approch a ledge and turn around
# Returns true if facing ledge (we are about to fall off a ledge)
func check_for_ledge() -> bool:
	# Our ray falls off the ledge and doesn't collide
	if not $Direction/OnEdgeRay.is_colliding():
		# TODO: this needs to be a momentum swing
		velocity.x = -velocity.x
		direction = -(sign(direction))
		# move the ray to the other side of the sprite
		$Direction.scale.x = -$Direction.scale.x
		queue_redraw()
		# We will wonder for 20 pixels the other way
		limit_movement = 20000
		start_pos = position.x
		return true
	else:
		# No ledge
		return false

func _ready():
	direction = get_global_position().direction_to(get_node('../Hector').get_global_position()).x
	$Direction/OnEdgeRay.scale.x = sign(direction)

func _physics_process(delta):
	if is_on_screen():
		if not is_on_floor():
			velocity.y += gravity * delta

		timer_process()
		animation_process()

		velocity.x = direction * get_speed()
		# we don't need to turn around to avoid ledge
		if not check_for_ledge():
			# We just turned around
			if limit_movement != 0:
				# TODO: this probably has a real function like clamp, we want to
				# saturate to 0 (I think that's what it's called)
				limit_movement = max(limit_movement - abs(start_pos - position.x), 0)
			# We haven't just turned around, find Hector to kill
			else:
				direction = get_global_position().direction_to(get_node('../Hector').get_global_position()).x
				$Direction/OnEdgeRay.scale.x = sign(direction)
		move_and_slide()

func _on_bounce_area_body_entered(body):
	if body.has_method('bounce_on_box'):
		bounced_on()
		body.bounce_on_box()
