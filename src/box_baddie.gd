extends CharacterBody2D


@export var speed = 100
var jump = -175
# TODO: do this for all physicis settings and any other thing like this
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta):
	find
	
	if $AnimatedSprite2D/VisibleOnScreen.is_on_screen():
		move_and_slide()
