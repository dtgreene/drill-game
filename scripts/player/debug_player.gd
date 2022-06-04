extends Node2D

const move_speed = 256

onready var terrain = get_node("/root/World/Terrain")
onready var terrain_background = terrain.get_node("/root/World/Terrain/Background")
onready var label = get_node("CanvasLayer/Label")

func _process(delta):
	var right_pressed = Input.is_action_pressed("move_right")
	var left_pressed = Input.is_action_pressed("move_left")
	var up_pressed = Input.is_action_pressed("move_up")
	var down_pressed = Input.is_action_pressed("move_down")
	
	if right_pressed:
		position = Vector2(position.x + move_speed * delta, position.y)
	if left_pressed:
		position = Vector2(position.x - move_speed * delta, position.y)
	if up_pressed:
		position = Vector2(position.x, position.y - move_speed * delta)
	if down_pressed:
		position = Vector2(position.x, position.y + move_speed * delta)
	
	# update terrain background
	terrain_background.update_y(floor(position.y))
	
	# update terrain chunks
	terrain.update_chunks(position)
	
	label.set_text(str(floor(position.y / 32 * 12.5)) + "ft")
