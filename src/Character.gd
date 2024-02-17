extends CharacterBody2D

var DEBUG = true
var speed = 100
var gravity = 600
var jump = -300

var last_dir = 1
# positive means right negitive means left
var direction = 0
var jumping = false
var sprite_angle = 0.0
var running = false

signal animation_change(animation)

enum AnimationState { default, walk, run, slide, jump_up, jump_down, attack, }

func _set_animation(anim_state: AnimationState):
	var anim = AnimationState.keys()[anim_state]
	$CharSprite.play(anim)
	if DEBUG: emit_signal('animation_change', anim)

func _jump() -> float:
	push_error("_jump() method must be overriden")
	return 0.0
	
func _horizontal_movement(delta: float):
	push_error("_horizontal_movement() method must be overriden")

func _normalize_movement_to_slope():
	push_error("_normalize_movement_to_slope() method must be overriden")
	# maybe delete

func take_damage():
	push_error("take_damage() method must be overriden")

func bounce_on_box():
	print('bounce on BOX foo')
	jumping = false
	velocity.y = _jump()
