extends Node

func DEBUG_ALL() -> bool: return _DEBUG_ALL
func DEBUG_GHOST() -> bool: return DEBUG_ALL() or false
func DEBUG_GRID() -> bool: return DEBUG_ALL() or false
func DEBUG_POS() -> bool: return DEBUG_ALL() or false

var _DEBUG_ALL: bool = true

# Returns 
func get_level_upleft_bounds(level: Node2D) -> Vector2i:
	return level.get_node("UpperLeftBound").position
	
func get_level_lowright_bounds(level: Node2D) -> Vector2i:
	return level.get_node("LowerRightBound").position
