extends CharacterBody2D

@export var speed = 100
@export var gravity = 350
@export var jump = -175

var last_dir_right = true
# positive means right negitive means left
var direction = 0
var jumping = false

func _horizontal_movement(is_jump):
	pass
