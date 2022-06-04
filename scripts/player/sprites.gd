extends Node2D

const GlobalValues = preload("res://scripts/global_values.gd")

const shake_speed = PI * 20

var ShakeDirections = GlobalValues.ShakeDirections

var sin_value = 0
var shake_direction = ShakeDirections.NONE

func shake(direction):
	shake_direction = direction
	set_process(true)

func stop_shaking():
	shake_direction = ShakeDirections.NONE
	set_process(false)
	position = Vector2()

func _process(delta):
	if shake_direction == ShakeDirections.HORIZONTAL:
		position = Vector2(0, sin(sin_value) * 2)
	elif shake_direction == ShakeDirections.VERTICAL:
		position = Vector2(sin(sin_value) * 2, 0)
	
	sin_value += shake_speed * delta
	
