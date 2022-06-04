extends Node2D

const HealthAndFuel = preload("res://assets/images/health_and_fuel.png")

onready var player = get_node("/root/World/Player")

var health_color = Color(1.00000, 0.00000, 0.25098)
var fuel_color = Color(1.00000, 0.65098, 0.30196)

func _draw():
	draw_texture(HealthAndFuel, Vector2(5, 6))
	
	# ((n-start1)/(stop1-start1))*(stop2-start2)+start2
	var health_width = clamp(round(float(player.hull) / float(player.hull_max) * 94.0), 0, 94)
	draw_rect(Rect2(Vector2(6, 8), Vector2(health_width, 3)), health_color)
	draw_rect(Rect2(Vector2(6, 11), Vector2(health_width, 1)), health_color.linear_interpolate(Color(0, 0, 0), 0.3))
	draw_rect(Rect2(Vector2(6, 7), Vector2(health_width, 1)), health_color.linear_interpolate(Color(1, 1, 1), 0.3))
	
	var fuel_width = clamp(round(float(player.fuel) / float(player.fuel_max) * 71.0), 0, 71)
	draw_rect(Rect2(Vector2(8, 13), Vector2(fuel_width, 1)), fuel_color.linear_interpolate(Color(0, 0, 0), 0.3))
	draw_rect(Rect2(Vector2(8, 14), Vector2(fuel_width, 4)), fuel_color)
