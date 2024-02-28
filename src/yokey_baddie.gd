extends "res://src/BounceEnemy.gd"

const YOKE = preload("res://Scenes/yoke_attack.tscn")

# Any property overriding needs to happen in here
#func _init():
	#speed = 50

func get_speed(): return 50

func timer_process():
	if $AttackTimer.is_stopped(): 
			$AttackTimer.start()

func is_on_screen() -> bool:
	return $AnimatedSprite2D/VisibleOnScreenEnabler2D.is_on_screen()

func animation_process():
	if direction > 0:
		$AnimatedSprite2D.flip_h = false
	elif direction < 0:
		$AnimatedSprite2D.flip_h = true

func bounced_on(): pass

func flip_ray():
	$Direction.scale.x = -$Direction.scale.x

func _on_attack_timer_timeout():
	var yoke = YOKE.instantiate()
	yoke.global_position.y = global_position.y - $AnimatedSprite2D.get_sprite_frames().get_frame_texture('walk', 0).get_height()
	yoke.global_position.x = global_position.x
	yoke.direction = direction
	get_parent().add_child(yoke)
