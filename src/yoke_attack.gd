extends CharacterBody2D


@export var speed = 200
var jump = -175

var start_pos = 0
var direction = -1

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	velocity.y = jump
	
func _physics_process(delta):
	velocity.y += gravity * delta
	direction = get_global_position().direction_to(get_node('../Hector').get_global_position()).x
	if direction > 0:
		$AnimatedSprite2D.flip_h = false
	elif direction < 0:
		$AnimatedSprite2D.flip_h = true
	
	# TODO: give this the right name
	$AnimatedSprite2D.play('walk')
	velocity.x = direction * speed

	if is_on_floor():
		$CollisionShape2D.disabled = true
		$AnimatedSprite2D.play('splat')
	else:
		move_and_slide()


func _on_bounce_area_body_entered(body):
	if body.has_method('bounce_on_box'):
		body.bounce_on_box()


func _on_pain_area_body_entered(body):
	if body.has_method('take_damage'):
		body.take_damage()


func _on_despawn_timer_timeout():
	queue_free()
