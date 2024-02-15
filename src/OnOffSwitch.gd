extends AnimatableBody2D

signal on_off_changed(is_on)

var is_on = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_on:
		$AnimatedSprite2D.play('on')
	else:
		$AnimatedSprite2D.play('off')


func _on_area_2d_body_entered(body):
	# TODO: this is bad we just want Hectors belt...
	if body.has_method('is_walking'):
		is_on = !is_on
		emit_signal('on_off_changed', is_on)
