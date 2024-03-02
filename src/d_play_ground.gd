extends Node2D

const STEP: int = 32

var pos: Vector2

func _ready():
	pos = DisplayServer.screen_get_position()


func _draw():
	if Global.DEBUG:
		var half_size: Vector2 = DisplayServer.screen_get_size() * 0.5
		var low_left: Vector2 = pos - half_size
		var up_right: Vector2 = pos + half_size
		var curr_ll: Vector2 = low_left
		var lines: PackedVector2Array = []
		while curr_ll.x < up_right.x:
			while curr_ll.y < up_right.y:
				# Lines from(x, y), to(x, y)
				lines.append_array([ Vector2(low_left.x, curr_ll.y), Vector2(up_right.x, curr_ll.y) ])
				lines.append_array([ Vector2(curr_ll.x, low_left.y), Vector2(curr_ll.x, up_right.y) ])
				curr_ll.y += STEP
			curr_ll.y = low_left.y
			curr_ll.x += STEP
		draw_multiline(lines, Color(0.498039, 1, 0.831373, 0.005), 1.0)

func _on_camera_2d_viewport_moved(new_pos: Vector2):
	pos = new_pos
	queue_redraw()
