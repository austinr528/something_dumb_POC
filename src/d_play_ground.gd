extends Node2D


func _draw():
	var pos: Vector2 = DisplayServer.screen_get_position()
	var half_size: Vector2 = DisplayServer.screen_get_size() * 0.5
	var low_left = pos - half_size
	var up_right = pos + half_size
	var curr_ll = low_left
	print(low_left, up_right)
	var lines: PackedVector2Array = []
	while curr_ll.x < up_right.x:
		while curr_ll.y < up_right.y:
			# Lines from(x, y), to(x, y)
			lines.append_array([ Vector2(low_left.x, curr_ll.y), Vector2(up_right.x, curr_ll.y) ])
			lines.append_array([ Vector2(curr_ll.x, low_left.y), Vector2(curr_ll.x, up_right.y) ])
			curr_ll.y += 16 * 2
		curr_ll.y = low_left.y
		curr_ll.x += 16 * 2
	draw_multiline(lines, Color(0.498039, 1, 0.831373, 0.2), 1.0)
