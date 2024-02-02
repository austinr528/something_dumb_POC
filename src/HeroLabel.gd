extends Label

var label_ref : Label = null

# Called when the node enters the scene tree for the first time.
func _ready():
	text = 'Default'


func _on_hero_animation_change(animation):
	text = animation
