extends Label

var label_ref : Label = null

# Called when the node enters the scene tree for the first time.
func _ready():
	if Global.DEBUG:
		text = 'Default'

func _on_character_animation_change(animation):
	if Global.DEBUG:
		text = animation
