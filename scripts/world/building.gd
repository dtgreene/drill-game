extends Node2D

const EnterIcon = preload("res://assets/images/icon_ent.png")
const M5X7 = preload("res://assets/fonts/m5x7.fnt")

onready var world = get_node("/root/World")

var released = false
var player = null
var player_present = false
var building_texture = null

export var world_open_method = ""
export var building_texture_path = ""
export var building_texture_pos = Vector2()
export var enter_text_height = -64

func _ready():
	var area = get_node("Area2D")
	area.connect("area_entered", self, "area_entered")
	area.connect("area_exited", self, "area_exited")
	
	if building_texture_path.length() > 0:
		building_texture = load(building_texture_path)
	
	set_process(false)

func _draw():
	if building_texture != null:
		draw_texture(building_texture, building_texture_pos)
	else:
		draw_rect(Rect2(Vector2(-16, -16), Vector2(32, 32)), Color(1, 1, 1))
	
	if player_present:
		draw_icon_string(Vector2(4, enter_text_height), "Use", -24)

func _process(_delta):
	if Input.is_action_pressed("ui_accept"):
		if released:
			if player.alive:
				world.call_deferred(world_open_method)
			released = false
	else: 
		released = true

func area_entered(_body):
	player_present = true
	
	if player == null:
		player = world.get_node("Player")
	
	set_process(true)
	update()

func area_exited(_body):
	player_present = false
	set_process(false)
	update()

func draw_icon_string(icon_position, string, x_offset):
	draw_texture(EnterIcon, icon_position)
	draw_string(M5X7, Vector2(icon_position.x + x_offset, icon_position.y + 11), string)
