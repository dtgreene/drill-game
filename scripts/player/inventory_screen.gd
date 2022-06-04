extends "res://scripts/ui_screen.gd"

const DrillCar = preload("res://assets/images/drillcar1_outline.png")
const Background = preload("res://assets/images/screen_background.png")

onready var player = get_node("/root/World/Player")

var mineral_names = GlobalValues.mineral_names

var released = false
var selector_index = 0
var mineral_list = []

func _ready():
	hide()

func _draw():
	draw_texture(Background, Vector2())
	draw_rect(Rect2(Vector2(), Vector2(320, 14)), Color(0, 0, 0))
	
	draw_string(M5X7, Vector2(8, 25), "Upgrade")
	draw_string(M5X7, Vector2(130, 25), "Lvl")
	draw_line(Vector2(4, 29), Vector2(158, 29), Color(1, 1, 1))
	
	draw_string(M5X7, Vector2(8, 41), "Drill")
	draw_string(M5X7, Vector2(130, 41), str(player.drill_upgrade.level))
	
	draw_string(M5X7, Vector2(8, 57), "Hull")
	draw_string(M5X7, Vector2(130, 57), str(player.hull_upgrade.level))
	
	draw_string(M5X7, Vector2(8, 73), "Fuel")
	draw_string(M5X7, Vector2(130, 73), str(player.fuel_upgrade.level))
	
	draw_string(M5X7, Vector2(8, 89), "Radiator")
	draw_string(M5X7, Vector2(130, 89), str(player.radiator_upgrade.level))
	
	draw_string(M5X7, Vector2(8, 105), "Cargo")
	draw_string(M5X7, Vector2(130, 105), str(player.cargo_upgrade.level))
	
	draw_string(M5X7, Vector2(166, 25), "Mineral")
	draw_string(M5X7, Vector2(296, 25), "Ct")
	draw_line(Vector2(162, 29), Vector2(316, 29), Color(1, 1, 1))
	
	if mineral_list.size() > 0:
		draw_rect(Rect2(Vector2(162, 29 + 16 * selector_index), Vector2(154, 16)), GlobalValues.ui_secondary)
		
		var i = 0
		while i < mineral_list.size():
			var y = 41 + i * 16
			draw_string(M5X7, Vector2(166, y), mineral_list[i].name)
			draw_string(M5X7, Vector2(296, y), str("x") + str(mineral_list[i].count))
			draw_line(Vector2(162, y + 4), Vector2(316, y + 4), Color(1, 1, 1))
			i += 1
		
		var cargo_percent = round(float(player.cargo_count) / float(player.cargo_count_max) * 100.0)
		draw_string(M5X7, Vector2(166, 193), "Cargo " + str(cargo_percent) + "% full")
		
		draw_icon_string(0, Vector2(244, 219), "Discard", -40)
	else:
		draw_string(M5X7, Vector2(166, 41), "Cargo bay empty")
	
	draw_icon_string(1, Vector2(299, 219), "Close", -30)
	
	draw_texture(DrillCar, Vector2(12, 164))

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
			if mineral_list.size() > 0:
				player.remove_mineral(mineral_list[selector_index].index)
				create_mineral_list()
				
				selector_index = clamp(selector_index, 0, mineral_list.size() - 1)
				
				EffectsPlayer.play("mineral_drop")
				update()
			released = false
	elif Input.is_action_pressed("ui_cancel") || Input.is_action_pressed("inventory"):
		if released:
			hide()
			set_process(false)
			
			get_tree().set_pause(false)
			emit_signal("pause_notification")
			emit_signal("screen_toggle", false)
			
			EffectsPlayer.play("ui_minimize")
			released = false
	else:
		released = true

func increment_selector(amount):
	if mineral_list.size() > 0:
		EffectsPlayer.play("ui_hover")
		selector_index += amount
		if selector_index < 0:
			selector_index = mineral_list.size() - 1
		elif selector_index >= mineral_list.size():
			selector_index = 0
		update()

func create_mineral_list():
	mineral_list = []
	var i = 0
	var minerals = player.cargo_minerals
	while i < minerals.size():
		if minerals[i] > 0:
			mineral_list.append(PlayerMineral.new(mineral_names[i], minerals[i], i))
		i += 1

func open():
	show()
	set_process(true)
	
	get_tree().set_pause(true)
	emit_signal("pause_notification")
	emit_signal("screen_toggle", true)
	
	EffectsPlayer.play("ui_maximize")
	
	released = false
	selector_index = 0
	create_mineral_list()

class PlayerMineral:
	var name = ""
	var count = 0
	var index = -1
	func _init(_name, _count, _index):
		name = _name
		count = _count
		index = _index
