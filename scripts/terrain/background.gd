extends Node2D

const GlobalValues = preload("res://scripts/global_values.gd")

const min_y = 16
const offset_y = 8 * 32

const colors = [
	Color(0.50196, 0.41176, 0.32157),
	Color(),
	Color(0.09412, 0.14902, 0.09412),
	Color(0.09804, 0.17647, 0.19608),
	Color(0.19216, 0.14902, 0.24314),
	Color(0.22745, 0.09020, 0.09020),
	Color(0.50588, 0.11373, 0.11373),
	Color(0.08627, 0.08627, 0.15294)
]

var rect_width = GlobalValues.col_count * 32
var rect_height = 16 * 32
var target_y = min_y

func _draw():
	var color = Color()
	# convert the target to feet (* 0.390625), divide by 1000 (* 0.001)
	var target_converted = target_y * 0.000390625
	# remove integer portion
	var color_value = fmod(target_converted, 1)
	var color_index = floor(target_converted)
	
	if color_index >= 0 && color_index < colors.size() - 1:
		color = colors[color_index].linear_interpolate(colors[color_index + 1], color_value)
	else:
		color = colors[colors.size() - 1]
		
	var background_rect = Rect2(Vector2(-16, target_y), Vector2(rect_width, rect_height))
	draw_rect(background_rect, color)

func update_y(y):
	var adjusted_y = max(y - offset_y + min_y, min_y)
	if target_y != adjusted_y:
		target_y = adjusted_y
		update()
