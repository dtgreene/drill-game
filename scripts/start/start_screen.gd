extends "res://scripts/ui_screen.gd"

const TitleTexture = preload("res://assets/images/title.png")

const animation_speed = PI

enum Screens {
	MAIN,
	LOAD
}

var screen = Screens.MAIN
var released = false
var sin_value = 0
var selector_index = 0
var save_slots = []

func _ready():
	save_slots = GlobalValues.get_save_slots()
	
	Globals.load_slot = -1
	
	# get our audio bus indexes
	var music_bus_index = AudioServer.get_bus_index("Music")
	var fx_bus_index = AudioServer.get_bus_index("Effects")
	
	# load settings
	var settings_file = File.new()
	if settings_file.file_exists("user://settings.save"):
		settings_file.open("user://settings.save", File.READ)
		var parse_result = JSON.parse(settings_file.get_as_text())
		if parse_result.error == OK:
			var settings_data = parse_result.get_result()
			if settings_data.has("music_volume"):
				AudioServer.set_bus_volume_db(music_bus_index, settings_data.music_volume)
			if settings_data.has("fx_volume"):
				AudioServer.set_bus_volume_db(fx_bus_index, settings_data.fx_volume)
			
		settings_file.close()
	else:
		# set the default volumes for the audio buses
		AudioServer.set_bus_volume_db(music_bus_index, -16)
		AudioServer.set_bus_volume_db(fx_bus_index, -8)
	
	$"/root/Start/StartMusic".play()

func _draw():
	draw_rect(Rect2(Vector2(0, 0), Vector2(320, 240)), Color(0, 0, 0))
	
	var title_size = Vector2(32, 32)
	var sin_value_current = sin_value
	for i in range(5):
		draw_texture_rect_region(TitleTexture, Rect2(Vector2(40 + i * 24, 64 + sin(sin_value_current) * 4), title_size), Rect2(Vector2(i * 32, 0), title_size))
		sin_value_current += 0.4
	
	for i in range(4):
		draw_texture_rect_region(TitleTexture, Rect2(Vector2(184 + i * 24, 64 + sin(sin_value_current) * 4), title_size), Rect2(Vector2(160 + i * 32, 0), title_size))
		sin_value_current += 0.4
	
	draw_rect(Rect2(Vector2(80, 136 + 16 * selector_index), Vector2(160, 16)), GlobalValues.ui_secondary)

	if screen == Screens.MAIN:
		draw_string(M5X7, Vector2(84, 148), "New Game")
		draw_line(Vector2(80, 152), Vector2(240, 152), Color(1, 1, 1))
		draw_string(M5X7, Vector2(84, 164), "Load Game")
		draw_line(Vector2(80, 168), Vector2(240, 168), Color(1, 1, 1))
		
		draw_icon_string(0, Vector2(299, 219), "Select", -34)
	elif screen == Screens.LOAD:
		
		draw_string(M5X7, Vector2(84, 132), "Slot")
		draw_string(M5X7, Vector2(204, 132), "Saved")
		draw_line(Vector2(80, 136), Vector2(240, 136), Color(1, 1, 1))
		
		var i = 0
		while i < 3:
			var y = 148 + i * 16
			draw_string(M5X7, Vector2(84, y), "Slot " + str(i))
			draw_string(M5X7, Vector2(204, y), str(save_slots[i]))
			draw_line(Vector2(80, y + 4), Vector2(240, y + 4), Color(1, 1, 1))
			i += 1
		
		draw_icon_string(0, Vector2(244, 219), "Select", -34)
		draw_icon_string(1, Vector2(299, 219), "Close", -30)

func _process(delta):
	sin_value += animation_speed * delta
	update()
	
	if Input.is_action_pressed("ui_up"):
		if released:
			increment_selector(-1)
			released = false
	elif Input.is_action_pressed("ui_down"):
		if released:
			increment_selector(1)
			released = false
	elif Input.is_action_pressed("ui_cancel"):
		if released:
			if screen == Screens.LOAD:
				screen = Screens.MAIN
				selector_index = 0
				
				EffectsPlayer.play("ui_cancel")
				update()
			released = false
	elif Input.is_action_pressed("ui_accept"):
		if released:
			if screen == Screens.MAIN:
				if selector_index == 0:
					
					# music will lag during scene change for some exports
					$"/root/Start/StartMusic".stop()
					
					get_tree().change_scene("res://scenes/world/World.tscn")
				elif selector_index == 1:
					screen = Screens.LOAD
					selector_index = 0
					
					EffectsPlayer.play("ui_accept")
					update()
			elif screen == Screens.LOAD:
				var name = "user://save" + str(selector_index) + ".save"
				var save = File.new()
				if !save.file_exists(name):
					EffectsPlayer.play("ui_deny")
				else:
					Globals.load_slot = selector_index
					
					# music will lag during scene change for some exports
					$"/root/Start/StartMusic".stop()
					
					get_tree().change_scene("res://scenes/world/World.tscn")
			released = false
	else:
		released = true

func increment_selector(amount):
	EffectsPlayer.play("ui_hover")
	selector_index += amount
	
	var selector_index_max = 0
	if screen == Screens.MAIN:
		selector_index_max = 2
	elif screen == Screens.LOAD:
		selector_index_max = 3
		
	if selector_index < 0:
		selector_index = selector_index_max - 1
	elif selector_index >= selector_index_max:
		selector_index = 0
	update()
