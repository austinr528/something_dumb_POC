extends CharacterBody2D

@export var speed = 100
@export var gravity = 350
@export var jump = -175

var last_dir_right = true
# positive means right negitive means left
var direction = 0
var jumping = false
var curr_jump_pos = 0
var sprite_angle = 0.0

signal animation_change(animation)

func _horizontal_movement(is_jump):
	pass

func _normalize_movement_to_slope():
	pass
	# maybe delete

func take_damage():
	pass

func bounce_on_box():
	print('bounce on BOX foo')
	jumping = true
	curr_jump_pos = position.y
	velocity.y = jump
