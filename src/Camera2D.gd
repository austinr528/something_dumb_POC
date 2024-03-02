extends Camera2D

signal viewport_moved(position: Vector2)

var last_center: Vector2 = Vector2()
var last_position: Vector2 = Vector2()

func ready():
	last_center = get_screen_center_position()
	last_position = position

func _process(delta):
	var center: Vector2 = get_screen_center_position()
	#if not position.is_equal_approx(last_position) and center.is_equal_approx(last_center):
	if not center.is_equal_approx(last_center):
		emit_signal('viewport_moved', center)
	last_center = center
	last_position = position
