extends "res://src/BounceEnemy.gd"

# Any property overriding needs to happen in here
#func _init():
	#speed = 50

func get_speed(): return 50

func timer_process(): pass

func is_on_screen() -> bool:
	return $AnimatedSprite2D/VisibleOnScreenEnabler2D.is_on_screen()

func animation_process():
	if direction > 0:
		$AnimatedSprite2D.flip_h = false
	elif direction < 0:
		$AnimatedSprite2D.flip_h = true

func bounced_on():
	$AnimatedSprite2D.play('flat')
	#TODO: this doesn't actually work, I want the box to stop moving and
	# be flat and no more interaction/movement
	direction = 0

func flip_ray():
	$Direction.scale.x = -$Direction.scale.x

func _on_pain_area_body_entered(body):
	if body.has_method('take_damage'):
		body.take_damage()
