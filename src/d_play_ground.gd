extends Node2D

const STEP: int = 32

func _draw():
	if Global.DEBUG_GRID():
		var lines: PackedVector2Array = []
		var up_left: Vector2 = Global.get_level_upleft_bounds(self)
		var low_right: Vector2 = Global.get_level_lowright_bounds(self)
		var curr_ul: Vector2 = up_left
		while curr_ul.x < low_right.x:
			while low_right.y > curr_ul.y:
				# Lines from(x, y), to(x, y)
				# this is the horizontal line pack
				lines.append_array([ Vector2(up_left.x, curr_ul.y), Vector2(low_right.x, curr_ul.y) ])
				# this is the vertical line pack
				lines.append_array([ Vector2(curr_ul.x, low_right.y), Vector2(curr_ul.x, up_left.y) ])
				# continue moving down (towards low of low_right)
				curr_ul.y += STEP
			# reset our vertical position so we don't start lower and lower each time (closer to low of low_right)
			curr_ul.y = up_left.y
			# continue march right for vertical lines
			curr_ul.x += STEP
		# Finally draw the damn lines...
		draw_multiline(lines, Color(0.498039, 1, 0.831373, 0.005), 1.0)
