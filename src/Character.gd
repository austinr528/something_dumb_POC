extends CharacterBody2D

var DEBUG = true
var speed = 100
var gravity = 600
var jump = -300

var last_dir = 1
# positive means right negitive means left
var direction = 0
var jumping = false
var curr_jump_pos = 0
var sprite_angle = 0.0
var running = false

signal animation_change(animation)

enum AnimationState { default, walk, run, slide, jump_up, jump_down, attack, }

func _set_animation(anim_state: AnimationState):
	var anim = AnimationState.keys()[anim_state]
	$CharSprite.play(anim)
	if DEBUG: emit_signal('animation_change', anim)

func _horizontal_movement(delta: float):
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
