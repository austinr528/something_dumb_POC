extends AnimatableBody2D

var fallen = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _is_supporting(node_path):
	return $Area2D.overlaps_body(get_node(node_path)) && get_node(node_path).is_on_floor()

func _physics_process(delta):
	print(Timer)
	# this is bad apparently, we want a signal
	# to notify this when the player enters this Area2d but until then
	print('time: ', $Timer.time_left)
	print('stopped: ', $Timer.is_stopped())
	
	if !fallen && _is_supporting('../Hero') && $Timer.is_stopped():
		$Timer.start()
	elif !fallen && $Timer.time_left < 0.2 && !$Timer.is_stopped():
		fallen = true
	elif fallen:
		position.y += 4;
