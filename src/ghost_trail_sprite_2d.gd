extends Sprite2D


func _ready():
	$GhostTrailTimer.start()
	self_modulate = Color(1, 1, 1, 0.4)
	
func _on_ghost_trail_timer_timeout():
	queue_free()
