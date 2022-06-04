extends "res://scripts/ui_screen.gd"

const DeathTexture = preload("res://assets/images/death.png")

onready var reason = get_node("Reason")

var released = false

func _ready():
	hide()
	set_process(false)

func _draw():
	draw_rect(Rect2(Vector2(0, 0), Vector2(320, 240)), Color(0, 0, 0))
	# position = middle of screen - half image dimensions
	draw_texture(DeathTexture, Vector2(90, 70))
	draw_icon_string(0, Vector2(172, 200), "Restart", -42)

func _process(_delta):
	if Input.is_action_pressed("ui_accept"):
		if released:
			get_tree().reload_current_scene()
	else:
		released = true

func open(damage_reason):
	set_process(true)
	show()
	
	released = false
	reason.set_text("Died to " + str(damage_reason))
