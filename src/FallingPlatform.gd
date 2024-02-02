extends AnimatableBody2D

var fallen = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _is_supporting(body):
	return body.is_on_floor()

func _physics_process(delta):
	print(Timer)
	print('time: ', $Timer.time_left)
	print('stopped: ', $Timer.is_stopped())
	
	
	if !fallen && $Timer.time_left < 0.2 && !$Timer.is_stopped():
		fallen = true
	elif fallen:
		position.y += 4;


func _on_area_2d_body_entered(body):
	if !fallen && _is_supporting(body) && $Timer.is_stopped():
		$Timer.start()
