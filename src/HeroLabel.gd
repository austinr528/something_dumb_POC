extends Label

var label_ref : Label = null

# Called when the node enters the scene tree for the first time.
func _ready():
	text = 'Default'

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var player = get_node('../AnimatedSprite2D')
	text = player.animation
