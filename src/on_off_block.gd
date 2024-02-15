extends AnimatableBody2D

var _is_on = false

# Called when the node enters the scene tree for the first time.
func _ready():
	# Don't love this but it is the only way to connect out of
	# tree elements
	#
	# Get the on/off switch and make all blocks on screen follow
	get_node('../OnOffSwitch').on_off_changed.connect(_on_on_off_change)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _is_on:
		$AnimatedSprite2D.play('on')
		$CollisionShape2D.disabled = false
	else:
		$AnimatedSprite2D.play('off')
		$CollisionShape2D.disabled = true

func _on_on_off_change(is_on):
	_is_on = is_on
