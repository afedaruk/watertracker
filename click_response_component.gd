extends TextureRect

func blink():
	adjust_self()
	show()
	await get_tree().create_timer(0.03).timeout
	hide()

func adjust_self():
	var max_dimension = max(get_parent().size.x, get_parent().size.y)
	size = Vector2(max_dimension, max_dimension)
	global_position = get_parent().global_position+get_parent().size/2-size/2
