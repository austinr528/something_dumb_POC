extends "res://src/BounceEnemy.gd"

# This allows us to stop the enemy from moving when hit
var curr_speed: float = 50.0
# Any property overriding needs to happen in here
#func _init():
	#speed = 50

func get_speed(): return curr_speed

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
	curr_speed = 0

func belt_hit():
	bounced_on()

func _set_ray_scale(sign: int):
	$Direction.scale.x = sign
	
func _flip_ray():
	$Direction.scale.x = -($Direction.scale.x)

func _on_pain_area_body_entered(body):
	if body.has_method('take_damage'):
		body.take_damage()
