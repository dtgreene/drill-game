extends "res://scripts/ui_screen.gd"

const TransmissionTexture = preload("res://assets/images/transmission.png")

onready var backdrop = get_node("/root/World/UI/Backdrop")

var transmit_lines = []
var index_offset = 0
var index_offset_max = 0
var y = -240
var released = false

func _ready():
	hide()
	set_process(false)

func _draw():
	if transmit_lines.size() == 0: return
	
	draw_texture(TransmissionTexture, Vector2(0, 0))
	var index = 0
	while index < 9 && index < transmit_lines.size():
		draw_string(M5X7, Vector2(24, 56 + index * 16), transmit_lines[index + index_offset])
		index += 1
	
	draw_icon_string(1, Vector2(299, 219), "Close", -30)

	if index_offset_max > 0:
		var scroll_bar_height = 144 * (9.0 / (9 + index_offset_max))
		var scroll_bar_y = index_offset * (144 - scroll_bar_height) / index_offset_max
		
		# draw scroll bar 
		draw_rect(Rect2(Vector2(288, 48), Vector2(8, 144)), GlobalValues.ui_secondary)
		# draw scroll bar thumb
		draw_rect(Rect2(Vector2(288, 48 + scroll_bar_y), Vector2(8, scroll_bar_height)), GlobalValues.ui_primary)

func _process(delta):
	if y < 0:
		y += 720 * delta
		# protect against over-shooting our target
		y = min(0, y)
		position = Vector2(0, y)
	if Input.is_action_pressed("ui_up"):
		if released && index_offset > 0:
			index_offset -= 1
			EffectsPlayer.play("ui_scroll")
			update()
			released = false
	elif Input.is_action_pressed("ui_down"):
		if released && index_offset < index_offset_max:
			index_offset += 1
			EffectsPlayer.play("ui_scroll")
			update()
			released = false
	elif Input.is_action_pressed("ui_cancel"):
		if released:
			hide()
			set_process(false)
			
			get_tree().set_pause(false)
			emit_signal("pause_notification")
			emit_signal("screen_toggle", false)
			
			EffectsPlayer.play("transmission_close")
			backdrop.hide()
			released = false
	else:
		released = true

func transmit(lines):
	
	show()
	set_process(true)
	
	get_tree().set_pause(true)
	emit_signal("pause_notification")
	emit_signal("screen_toggle", true)
	
	EffectsPlayer.play("transmission_open")
	backdrop.fadeIn()
	
	transmit_lines = lines
	index_offset = 0
	index_offset_max = max(transmit_lines.size() - 9, 0)
	released = false
	
	position = Vector2(0, -240)
	y = -240
