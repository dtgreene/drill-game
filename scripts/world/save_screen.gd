extends "res://scripts/ui_screen.gd"

const DrillCar = preload("res://assets/images/drillcar1_outline.png")
const Background = preload("res://assets/images/screen_background.png")

enum Screens {
	MAIN,
	CONFIRM_SAVE
}

onready var terrain = get_node("/root/World/Terrain")
onready var warning_label = get_node("Warning")
onready var world = get_node("/root/World")

var player = null
var released = false
var status_text = ""
var selector_index = 0
var save_slot = -1
var save_slots = []
var screen = Screens.MAIN

func _ready():
	hide()
	warning_label.hide()
	set_process(false)

func _draw():
	draw_texture(Background, Vector2())
	draw_rect(Rect2(Vector2(), Vector2(320, 14)), Color(0, 0, 0))
	
	if screen == Screens.MAIN:
		draw_string(M5X7, Vector2(8, 25), "Slot")
		draw_string(M5X7, Vector2(260, 25), "Saved")
		draw_line(Vector2(4, 29), Vector2(316, 29), Color(1, 1, 1))
		
		draw_rect(Rect2(Vector2(4, 29 + 16 * selector_index), Vector2(312, 16)), GlobalValues.ui_secondary)
		
		var i = 0
		while i < 3:
			var y = 41 + i * 16
			draw_string(M5X7, Vector2(8, y), "Slot " + str(i))
			draw_string(M5X7, Vector2(260, y), str(save_slots[i]))
			draw_line(Vector2(4, y + 4), Vector2(316, y + 4), Color(1, 1, 1))
			i += 1
		
		if status_text.length() > 0:
			draw_rect(Rect2(Vector2(4, 197), Vector2(312, 18)), GlobalValues.ui_secondary)
			draw_string(M5X7, Vector2(8, 209), status_text)
		
		draw_icon_string(0, Vector2(244, 219), "Select", -34)
		draw_icon_string(1, Vector2(299, 219), "Close", -30)
	elif screen == Screens.CONFIRM_SAVE:
		draw_rect(Rect2(Vector2(80, 104 + 16 * selector_index), Vector2(160, 16)), GlobalValues.ui_secondary)
	
		draw_option(116, "No")
		draw_option(132, "Yes")
		
		draw_icon_string(1, Vector2(299, 219), "Back", -25)

func draw_option(y, text):
	draw_string(M5X7, Vector2(84, y), text)
	draw_line(Vector2(80, y + 4), Vector2(240, y + 4), Color(1, 1, 1))

func _process(_delta):
	if Input.is_action_pressed("ui_up"):
		if released:
			increment_selector(-1)
			released = false
	elif Input.is_action_pressed("ui_down"):
		if released:
			increment_selector(1)
			released = false
	elif Input.is_action_pressed("ui_accept"):
		if released:
			if screen == Screens.MAIN:
				warning_label.show()
				warning_label.set_text("Are you sure you wish to save to slot " + str(selector_index) + "?  Any existing save data will be overwritten.")
				
				screen = Screens.CONFIRM_SAVE
				status_text = ""
				save_slot = selector_index
				selector_index = 0
				
				EffectsPlayer.play("ui_accept")
				update()
			elif screen == Screens.CONFIRM_SAVE:
				if selector_index == 0:
					screen = Screens.MAIN
					save_slot = -1
					selector_index = 0
					
					warning_label.hide()
					
					EffectsPlayer.play("ui_accept")
					update()
				elif selector_index == 1:
					save_game()
					
					screen = Screens.MAIN
					status_text = "Successfully saved game!"
					save_slot = -1
					selector_index = 0
					save_slots = GlobalValues.get_save_slots()
					
					warning_label.hide()
					
					EffectsPlayer.play("ui_success")
					update()
			released = false
	elif Input.is_action_pressed("ui_cancel"):
		if released:
			if screen == Screens.MAIN:
				hide()
				set_process(false)
				
				get_tree().set_pause(false)
				emit_signal("pause_notification")
				emit_signal("screen_toggle", false)
				
				EffectsPlayer.play("ui_minimize")
			elif screen == Screens.CONFIRM_SAVE:
				screen = Screens.MAIN
				save_slot = -1
				selector_index = 0
				
				warning_label.hide()
				
				EffectsPlayer.play("ui_cancel")
				update()
			released = false
	else:
		released = true

func increment_selector(amount):
	EffectsPlayer.play("ui_hover")
	selector_index += amount
	
	var selector_index_max = 0
	if screen == Screens.MAIN:
		selector_index_max = 3
	elif screen == Screens.CONFIRM_SAVE:
		selector_index_max = 2
		
	if selector_index < 0:
		selector_index = selector_index_max - 1
	elif selector_index >= selector_index_max:
		selector_index = 0
	update()

func save_game():
	if save_slot == -1: return
	
	var save = File.new()
	save.open("user://save" + str(save_slot) + ".save", File.WRITE)
	var data = {}
	
	data.timestamp = OS.get_unix_time()
	data.player = {
		money = player.money,
		cargo_minerals = player.cargo_minerals,
		hull = player.hull,
		equipment = player.equipment,
		# drill upgrade
		drill_upgrade_level = player.drill_upgrade.level,
		# hull upgrade
		hull_upgrade_level = player.hull_upgrade.level,
		# fuel upgrade
		fuel_upgrade_level = player.fuel_upgrade.level,
		# radiator upgrade
		radiator_upgrade_level = player.radiator_upgrade.level,
		# cargo upgrade
		cargo_upgrade_level = player.cargo_upgrade.level
	}
	
	data.terrain = []
	
	var used_block
	for block in terrain.blocks:
		used_block = {}
		used_block.filled = block.filled
		used_block.mineral_texture = block.mineral_texture
		data.terrain.append(used_block)
	
	data.world = {
		message_500_sent = world.message_500_sent,
		message_1000_sent = world.message_1000_sent,
		message_1700_sent = world.message_1700_sent,
		message_2100_sent = world.message_2100_sent,
		message_2500_sent = world.message_2500_sent,
		message_3100_sent = world.message_3100_sent,
		message_3500_sent = world.message_3500_sent,
		message_4100_sent = world.message_4100_sent,
		message_4500_sent = world.message_4500_sent,
		message_6200_sent = world.message_6200_sent,
		message_7000_sent = world.message_7000_sent,
		earthquake_happened = world.earthquake_happened,
		boss_defeated = world.boss_defeated
	}
	
	save.store_line(JSON.print(data))
	save.close()

func open():
	show()
	set_process(true)
	
	get_tree().set_pause(true)
	emit_signal("pause_notification")
	emit_signal("screen_toggle", true)
	
	player = get_node("/root/World/Player")
	EffectsPlayer.play("ui_maximize")
	
	warning_label.hide()
	
	released = false
	status_text = ""
	save_slot = -1
	selector_index = 0
	save_slots = GlobalValues.get_save_slots()
