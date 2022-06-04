extends Node2D

const M5X7 = preload("res://assets/fonts/m5x7.fnt")
const GlobalValues = preload("res://scripts/global_values.gd")

const icons = [
	preload("res://assets/images/icon_spc.png"), 
	preload("res://assets/images/icon_esc.png")
]

signal pause_notification()
signal screen_toggle(open)

func draw_icon_string(icon_index, icon_position, string, x_offset):
	draw_texture(icons[icon_index], icon_position)
	draw_string(M5X7, Vector2(icon_position.x + x_offset, icon_position.y + 11), string)
