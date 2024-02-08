extends CharacterBody2D


@export var speed = 50
var jump = -175
# TODO: do this for all physicis settings and any other thing like this
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var limit_movement = 30
var start_pos = 0
var direction = -1

func _ready():
	start_pos = position.x

func _physics_process(delta):
	velocity.y += gravity * delta
	
	if direction > 0:
		$AnimatedSprite2D.flip_h = false
	elif direction < 0:
		$AnimatedSprite2D.flip_h = true
		
	if $AnimatedSprite2D/VisibleOnScreenNotifier2D.is_on_screen():
		print(get_node('../Hero'))
		print('dir ', get_global_position().direction_to(get_node('../Hero').get_global_position()))
		direction = get_global_position().direction_to(get_node('../Hero').get_global_position()).x
		$AnimatedSprite2D.play('walk')
		velocity.x = direction * speed
		if abs(position.x - start_pos) >= limit_movement:
			direction *= -1
		move_and_slide()


func _on_bounce_area_body_entered(body):
	if body.has_method('bounce_on_box'):
		$AnimatedSprite2D.play('flat')
		direction = 0
		body.bounce_on_box()
