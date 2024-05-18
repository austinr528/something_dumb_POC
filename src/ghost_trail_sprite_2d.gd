extends Sprite2D

var wait_time: float

func set_trail_type(time: float, color: Color):
	wait_time = time
	self_modulate = color

func _ready():
	if wait_time == null: push_error('must call set_trail_type')

	$GhostTrailTimer.start(wait_time)

func _on_ghost_trail_timer_timeout():
	queue_free()
