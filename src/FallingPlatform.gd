extends AnimatableBody2D

var fallen = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _physics_process(delta):
	#print('time: ', $PlatTimer.time_left)
	#print('stopped: ', $PlatTimer.is_stopped())
	#print('on screen: ', $Sprite2D2/VisibleOnScreenNotifier2D.is_on_screen())
	if !fallen && $PlatTimer.time_left < 0.2 && !$PlatTimer.is_stopped():
		fallen = true
	elif fallen:
		position.y += 4;
	if fallen && !$Sprite2D2/VisibleOnScreenNotifier2D.is_on_screen():
		queue_free()


func _on_area_2d_2_body_entered(body):
	# TODO: this crashed once when I jumped off while it was falling 2/13/24
	#
	# This logic checks that the platform has not fallen, the body is standing on something, and that the time is stopped.
	# The second clause may be too vague but we can cross that bridge if we ever get to it.
	if !fallen && body.is_on_floor() && $PlatTimer.is_stopped():
		$PlatTimer.start()
