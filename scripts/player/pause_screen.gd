extends "res://scripts/ui_screen.gd"

const PauseTexture = preload("res://assets/images/paused.png")
const OptionsTexture = preload("res://assets/images/options.png")
const ControlsTexture = preload("res://assets/images/controls.png")
const QuitTexture = preload("res://assets/images/quit.png")
const ControlLayoutTexture = preload("res://assets/images/control_layout.png")
const Caret = preload("res://assets/images/caret.png")

const min_volume = -60
const max_volume = 0

enum Screens {
	MAIN,
	OPTIONS,
	CONTROLS,
	CONFIRM_QUIT
}

onready var warning_label = get_node("Warning")
onready var preview_music = get_node("PreviewMusic")

var released = true
var selector_index = 0
var screen = Screens.MAIN
var music_bus_index = 0
var fx_bus_index = 0

func _ready():
	hide()
	warning_label.hide()
	set_process(false)
	
	music_bus_index = AudioServer.get_bus_index("Music")
	fx_bus_index = AudioServer.get_bus_index("Effects")

func _draw():
	draw_rect(Rect2(Vector2(0, 0), Vector2(320, 240)), Color(0, 0, 0))
	
	if screen == Screens.MAIN:
		# position = middle of screen - half image dimensions
		draw_texture(PauseTexture, Vector2(90, 32))
		
		draw_rect(Rect2(Vector2(80, 96 + 16 * selector_index), Vector2(160, 16)), GlobalValues.ui_secondary)
	
		draw_option(108, "Options")
		draw_option(124, "Controls")
		draw_option(140, "Quit to Main Menu")
		
		draw_icon_string(0, Vector2(244, 219), "Select", -34)
		draw_icon_string(1, Vector2(299, 219), "Close", -30)
	elif screen == Screens.OPTIONS:
		draw_texture(OptionsTexture, Vector2(90, 32))
		
		draw_rect(Rect2(Vector2(80, 88 + 32 * selector_index), Vector2(160, 32)), GlobalValues.ui_secondary)
		
		var music_volume = AudioServer.get_bus_volume_db(music_bus_index)
		var fx_volume = AudioServer.get_bus_volume_db(fx_bus_index)
		draw_slider_option(100, "Music Volume", GlobalValues.remap(music_volume, min_volume, max_volume, 0, 1))
		draw_slider_option(132, "FX Volume", GlobalValues.remap(fx_volume, min_volume, max_volume, 0, 1))
		
		draw_icon_string(1, Vector2(299, 219), "Back", -25)
	elif screen == Screens.CONTROLS:
		draw_texture(ControlsTexture, Vector2(90, 32))
		
		draw_texture(ControlLayoutTexture, Vector2())
		
		draw_icon_string(1, Vector2(299, 219), "Back", -25)
	elif screen == Screens.CONFIRM_QUIT:
		draw_texture(QuitTexture, Vector2(90, 32))
		
		draw_rect(Rect2(Vector2(80, 104 + 16 * selector_index), Vector2(160, 16)), GlobalValues.ui_secondary)
		
		draw_option(116, "No")
		draw_option(132, "Yes")
		
		draw_icon_string(0, Vector2(244, 219), "Select", -34)
		draw_icon_string(1, Vector2(299, 219), "Back", -25)
	
func draw_option(y, text):
	draw_string(M5X7, Vector2(84, y), text)
	draw_line(Vector2(80, y + 4), Vector2(240, y + 4), Color(1, 1, 1))

func draw_slider_option(y, text, value):
	draw_string(M5X7, Vector2(84, y), text)
	draw_line(Vector2(80, y + 20), Vector2(240, y + 20), Color(1, 1, 1))
	
	draw_rect(Rect2(Vector2(84, y + 8), Vector2(152, 8)), Color(0, 0, 0))
	draw_rect(Rect2(Vector2(84, y + 8), Vector2(value * 152, 8)), GlobalValues.ui_primary)

func _process(_delta):
	if Input.is_action_pressed("ui_up"):
		if released:
			increment_selector(-1)
			released = false
	elif Input.is_action_pressed("ui_down"):
		if released:
			increment_selector(1)
			released = false
	elif Input.is_action_pressed("ui_left"):
		if released:
			if screen == Screens.OPTIONS:
				if selector_index == 0:
					increment_music_volume(-2)
				elif selector_index == 1:
					increment_fx_volume(-2)
			released = false
	elif Input.is_action_pressed("ui_right"):
		if released:
			if screen == Screens.OPTIONS:
				if selector_index == 0:
					increment_music_volume(2)
				elif selector_index == 1:
					increment_fx_volume(2)
			released = false
	elif Input.is_action_pressed("ui_accept"):
		if released:
			if screen == Screens.MAIN:
				if selector_index == 0:
					screen = Screens.OPTIONS
					selector_index = 0
					update()
				elif selector_index == 1:
					screen = Screens.CONTROLS
					selector_index = 0
					update()
				elif selector_index == 2:
					screen = Screens.CONFIRM_QUIT
					selector_index = 0
					
					warning_label.show()
					
					update()
				EffectsPlayer.play("ui_accept")
			elif screen == Screens.CONFIRM_QUIT:
				if selector_index == 0:
					screen = Screens.MAIN
					selector_index = 0
					
					warning_label.hide()
					
					EffectsPlayer.play("ui_accept")
					update()
				elif selector_index == 1:
					$"/root/World".stop_all_music()
					get_tree().set_pause(false)
					get_tree().change_scene("res://scenes/start/Start.tscn")
			released = false
	elif Input.is_action_pressed("ui_cancel"):
		if released:
			if screen == Screens.MAIN:
				close()
			elif screen == Screens.OPTIONS || screen == Screens.CONTROLS || Screens.CONFIRM_QUIT:
				screen = Screens.MAIN
				selector_index = 0
				
				warning_label.hide()
				
				EffectsPlayer.play("ui_cancel")
				update()
			released = false
	elif Input.is_action_pressed("ui_pause"):
		if released:
			close()
			released = false
	else:
		released = true

func increment_music_volume(amount):
	var music_volume = AudioServer.get_bus_volume_db(music_bus_index)
	var next_value = clamp(music_volume + amount, min_volume, max_volume)
	
	if next_value != music_volume:
		AudioServer.set_bus_volume_db(music_bus_index, next_value)
		preview_music.play()
		update()

func increment_fx_volume(amount):
	var fx_volume = AudioServer.get_bus_volume_db(fx_bus_index)
	var next_value = clamp(fx_volume + amount, min_volume, max_volume)
	
	if next_value != fx_volume:
		AudioServer.set_bus_volume_db(fx_bus_index, next_value)
		EffectsPlayer.play("ui_accept")
		update()

func increment_selector(amount):
	var selector_index_max = 0
	if screen == Screens.MAIN:
		selector_index_max = 3
	elif screen == Screens.OPTIONS:
		selector_index_max = 2
	elif screen == Screens.CONFIRM_QUIT:
		selector_index_max = 2
	
	selector_index += amount
	if selector_index < 0:
		selector_index = selector_index_max - 1
	elif selector_index >= selector_index_max:
		selector_index = 0
	
	EffectsPlayer.play("ui_hover")
	update()

func save_settings():
	var settings = File.new()
	settings.open("user://settings.save", File.WRITE)
	
	var music_volume = AudioServer.get_bus_volume_db(music_bus_index)
	var fx_volume = AudioServer.get_bus_volume_db(fx_bus_index)
	
	var data = {
		music_volume = music_volume,
		fx_volume = fx_volume
	}
	
	settings.store_line(JSON.print(data))
	settings.close()

func close():
	hide()
	set_process(false)
	
	get_tree().set_pause(false)
	emit_signal("pause_notification")
	emit_signal("screen_toggle", false)
	
	save_settings()
	
	EffectsPlayer.play("ui_minimize")

func open():
	show()
	set_process(true)
	
	get_tree().set_pause(true)
	emit_signal("pause_notification")
	emit_signal("screen_toggle", true)
	
	EffectsPlayer.play("ui_maximize")
	
	selector_index = 0
	released = false
	screen = Screens.MAIN
