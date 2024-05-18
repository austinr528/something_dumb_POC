extends Camera2D

signal viewport_moved(position: Vector2)

var last_center: Vector2 = Vector2()
var last_position: Vector2 = Vector2()

var shake_fade: float = 0

var rng = RandomNumberGenerator.new()

var shake_strength: float = 0.0

func _ready():
	get_node('../Hector').camera_shake.connect(_apply_camera_shake)
	last_center = get_screen_center_position()
	last_position = position

func _process(delta):
	var center: Vector2 = get_screen_center_position()
	#if not position.is_equal_approx(last_position) and center.is_equal_approx(last_center):
	if not center.is_equal_approx(last_center):
		emit_signal('viewport_moved', center)
	last_center = center
	last_position = position
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0, shake_fade * delta)
		offset = _random_offset()
		
func _random_offset() -> Vector2:
	return Vector2(rng.randf_range(-shake_strength, shake_strength), rng.randf_range(-shake_strength, shake_strength))

func _apply_camera_shake(strength: float, fade: float):
	shake_fade = fade
	shake_strength = strength
	print('we shake')
