extends Node2D

const HealthTexture = preload("res://assets/images/boss_health.png")
const M5X7 = preload("res://assets/fonts/m5x7.fnt")
const GlobalValues = preload("res://scripts/global_values.gd")

onready var boss = get_node("/root/World/Underworld/Boss")

var health_color = Color(1.00000, 0.00000, 0.25098)

func _draw():
	draw_string(M5X7, Vector2(7, 226), "Santa")
	draw_texture(HealthTexture, Vector2(5, 228))
	
	var health_width = GlobalValues.remap(boss.health, 0, 800, 0, 308)
	draw_rect(Rect2(Vector2(6, 230), Vector2(health_width, 3)), health_color)
	draw_rect(Rect2(Vector2(6, 233), Vector2(health_width, 1)), health_color.linear_interpolate(Color(0, 0, 0), 0.3))
	draw_rect(Rect2(Vector2(6, 229), Vector2(health_width, 1)), health_color.linear_interpolate(Color(1, 1, 1), 0.3))
	
