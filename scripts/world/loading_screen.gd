extends Node2D

const LoadingTexture = preload("res://assets/images/loading.png")

func _draw():
	draw_rect(Rect2(Vector2(0, 0), Vector2(320, 240)), Color(0, 0, 0))
	# position = middle of screen - half image dimensions
	draw_texture(LoadingTexture, Vector2(90, 104))
