extends CharacterBody2D

var SPEED:float = 100

var last_dir = 1
# positive means right negitive means left
var direction = 0
var jumping = false
var sprite_angle = 0.0
var running = false

const JUMP_SOUND = preload("res://Sounds/smw_jump.wav")
const THWACK_SOUND = preload("res://Sounds/smw_stomp_no_damage.wav")
const SNAP_SOUND = preload("res://Sounds/smw_bubble_pop.wav")

enum AudioState {
	none,
	jump, jump_played,
	attack, attack_played,
	bounce, bounce_played,
}

var audio_state: AudioState = AudioState.none

const GHOST = preload('res://Scenes/ghost_trail_sprite_2d.tscn')

signal animation_change(animation)

enum AnimationState {
	default, walk, run,
	turn,
	slide,
	jump_up, jump_down,
	attack, # will have all 4 directions :( sad
	duck_down, duck_up,
}

func _init():
	add_to_group('on_off_able')

func _set_animation(anim_state: AnimationState, frame: int = 0):
	var anim = AnimationState.keys()[anim_state]
	$CharSprite.play(anim)
	if Global.DEBUG_ALL:
		emit_signal('animation_change', anim)


func _set_audio(audio: AudioState):
	match audio:
		AudioState.jump when audio_state != AudioState.jump_played:
			$CharAudioPlayer.set_stream(JUMP_SOUND)
			if !$CharAudioPlayer.is_playing(): $CharAudioPlayer.play()
			audio_state = AudioState.jump_played
		AudioState.attack when audio_state != AudioState.attack_played:
			$CharAudioPlayer.set_stream(SNAP_SOUND)
			if !$CharAudioPlayer.is_playing(): $CharAudioPlayer.play()
			audio_state = AudioState.attack_played
		AudioState.bounce when audio_state != AudioState.bounce_played:
			$CharAudioPlayer.set_stream(THWACK_SOUND)
			if !$CharAudioPlayer.is_playing(): $CharAudioPlayer.play()
			audio_state = AudioState.bounce_played


func _jump() -> float:
	push_error("_jump() method must be overriden")
	return 0.0


func _horizontal_movement(delta: float):
	push_error("_horizontal_movement() method must be overriden")


func _normalize_movement_to_slope():
	push_error("_normalize_movement_to_slope() method must be overriden")
	# maybe delete

####
#
# Lifecycle methods
func _ready():
	# To make Hector not collide with enemies unless he hits the `BounceArea`
	# PS: this is fucking awesome groups are the SHIT (look at IDEAS.md)
	for node in get_tree().get_nodes_in_group('BounceEnemy'):
		add_collision_exception_with(node)

#######
#
# Signal handlers
func take_damage():
	push_error("take_damage() method must be overriden")


func bounce_on_box():
	print('bounce on BOX foo')
	_set_audio(AudioState.bounce)
	jumping = false
	velocity.y = _jump()


func _on_char_audio_player_finished():
	audio_state = AudioState.none
