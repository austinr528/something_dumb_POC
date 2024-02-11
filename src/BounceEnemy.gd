extends CharacterBody2D

@export var speed = 100
@export var gravity = 350
@export var jump = -175

var limit_movement = 30
var start_pos = 0
var direction = -1

# TODO: this is dumb has to be a better way
func get_speed(): pass
func timer_process(): pass
func animation_process(): pass
func bounced_on(): pass
# For some reason $AnimatedSprite2D/VisibleOnScreenNotifier2D is null
func is_on_screen(): pass

func _physics_process(delta):
	velocity.y += gravity * delta

	if is_on_screen():
		timer_process()
		direction = get_global_position().direction_to(get_node('../Hector').get_global_position()).x
		animation_process()
		velocity.x = direction * get_speed()
		move_and_slide()

func _on_bounce_area_body_entered(body):
	if body.has_method('bounce_on_box'):
		bounced_on()
		body.bounce_on_box()
