extends AnimatedSprite2D


func _ready():
	$BeltArea2D.add_to_group('on_off_able')

func _on_belt_area_2d_body_entered(body):
	if body.has_method('belt_hit'):
		body.belt_hit()

func _on_animation_finished():
	queue_free()
