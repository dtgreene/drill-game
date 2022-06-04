extends "res://scripts/ui_screen.gd"

const Background = preload("res://assets/images/screen_background.png")

const tab_names = [
	"Drill",
	"Hull",
	"Fuel",
	"Radiator",
	"Cargo"
]

onready var money_label = get_node("Money")
onready var tabs_label = get_node("Tabs")

var player
var released = false
var status_text = ""
var selector_index = 0
var tab_index = 0
var upgrade_list = []
var player_upgrade_current = null

class UpgradeItem:
	var name = ""
	var level = -1
	var cost = 0
	var value = 0
	func _init(_name, _level, _cost, _value):
		name = _name
		level = _level
		cost = _cost
		value = _value

var drill_upgrades = [
	UpgradeItem.new("Stock Drill", 0, 0, 60),
	UpgradeItem.new("Silvide Drill", 1, 750, 55),
	UpgradeItem.new("Goldium Drill", 2, 2000, 50),
	UpgradeItem.new("Emerald Drill", 3, 5000, 45),
	UpgradeItem.new("Ruby Drill", 4, 20000, 40),
	UpgradeItem.new("Diamond Drill", 5, 100000, 35),
	UpgradeItem.new("Unobtainium Drill", 6, 500000, 30)
]

var hull_upgrades = [
	UpgradeItem.new("Stock Hull", 0, 0, 10),
	UpgradeItem.new("Carbonium Hull", 1, 750, 17),
	UpgradeItem.new("Copperium Hull", 2, 2000, 30),
	UpgradeItem.new("Goldium Hull", 3, 5000, 50),
	UpgradeItem.new("Platinium Hull", 4, 20000, 80),
	UpgradeItem.new("Sulfurium Hull", 5, 100000, 120),
	UpgradeItem.new("Energy-Shielded Hull", 6, 500000, 180)
]

var fuel_upgrades = [
	UpgradeItem.new("Micro Tank", 0, 0, 10),
	UpgradeItem.new("Medium Tank", 1, 750, 15),
	UpgradeItem.new("Huge Tank", 2, 2000, 25),
	UpgradeItem.new("Gigantic Tank", 3, 5000, 40),
	UpgradeItem.new("Titanic Tank", 4, 20000, 60),
	UpgradeItem.new("Leviathan Tank", 5, 100000, 100),
	UpgradeItem.new("Liquid Compression Tank", 6, 500000, 150)
]

var radiator_upgrades = [
	UpgradeItem.new("Stock Fan", 0, 0, 0.0),
	UpgradeItem.new("Dual Fans", 1, 2000, 0.1),
	UpgradeItem.new("Single Turbine", 2, 5000, 0.25),
	UpgradeItem.new("Dual Turbines", 3, 20000, 0.4),
	UpgradeItem.new("Puron Cooling", 4, 100000, 0.6),
	UpgradeItem.new("Candy-Cane Freon Array", 5, 500000, 0.8)
]

var cargo_upgrades = [
	UpgradeItem.new("Micro Bay", 0, 0, 7),
	UpgradeItem.new("Medium Bay", 1, 750, 15),
	UpgradeItem.new("Huge Bay", 2, 2000, 25),
	UpgradeItem.new("Gigantic Bay", 3, 5000, 40),
	UpgradeItem.new("Titanic Bay", 4, 20000, 70),
	UpgradeItem.new("Leviathan Bay", 5, 100000, 120)
]

func _ready():
	hide()
	set_process(false)

func _draw():
	draw_texture(Background, Vector2())
	draw_rect(Rect2(Vector2(), Vector2(320, 14)), Color(0, 0, 0))
	
	draw_string(M5X7, Vector2(8, 36), "Upgrade")
	draw_string(M5X7, Vector2(180, 36), "Lvl")
	draw_string(M5X7, Vector2(260, 36), "Cost")
	draw_line(Vector2(4, 40), Vector2(316, 40), Color(1, 1, 1))
	
	draw_rect(Rect2(Vector2(4, 40 + 16 * selector_index), Vector2(312, 16)), GlobalValues.ui_secondary)
	
	var y = 52
	for upgrade in upgrade_list:
		draw_string(M5X7, Vector2(8, y), upgrade.name)
		draw_string(M5X7, Vector2(180, y), str(upgrade.level))
		draw_string(M5X7, Vector2(260, y), "$" + str(upgrade.cost))
		draw_line(Vector2(4, y + 4), Vector2(316, y + 4), Color(1, 1, 1))
		y += 16
	
	draw_string(M5X7, Vector2(8, 193), "Current: " + player_upgrade_current.name)
	
	if status_text.length() > 0:
		draw_rect(Rect2(Vector2(4, 197), Vector2(312, 18)), GlobalValues.ui_secondary)
		draw_string(M5X7, Vector2(8, 209), status_text)
	
	draw_icon_string(0, Vector2(244, 219), "Purchase", -49)
	draw_icon_string(1, Vector2(299, 219), "Close", -30)

func _process(_delta):
	if Input.is_action_pressed("ui_up"):
		if released:
			increment_selector(-1)
			released = false
	elif Input.is_action_pressed("ui_down"):
		if released:
			increment_selector(1)
			released = false
	elif Input.is_action_pressed("ui_right"):
		if released:
			increment_tab(1)
			released = false
	elif Input.is_action_pressed("ui_left"):
		if released:
			increment_tab(-1)
			released = false
	elif Input.is_action_pressed("ui_accept"):
		if released:
			var upgrade = upgrade_list[selector_index]
			if upgrade.level <= player_upgrade_current.level:
				# if the player already has this upgrade
				status_text = "Err: You already own this upgrade!"
				EffectsPlayer.play("ui_deny")
				update()
			elif upgrade.cost > player.money:
				# not enough cash
				status_text = "Err: Not enough cash!"
				EffectsPlayer.play("ui_deny")
				update()
			else:
				if tab_index == 0:
					player.upgrade_drill(upgrade)
				elif tab_index == 1:
					player.upgrade_hull(upgrade)
				elif tab_index == 2:
					player.upgrade_fuel(upgrade)
				elif tab_index == 3:
					player.upgrade_radiator(upgrade)
				elif tab_index == 4:
					player.upgrade_cargo(upgrade)
		
				player.subtract_money(upgrade.cost)
				
				money_label.set_text("$" + str(player.money))
				
				status_text = "Purchased " + upgrade.name + "!"
				get_upgrade_list()
				EffectsPlayer.play("cash_register")
				update()
			released = false
	elif Input.is_action_pressed("ui_cancel"):
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
	selector_index += amount
	if selector_index < 0:
		selector_index = upgrade_list.size() - 1
	elif selector_index >= upgrade_list.size():
		selector_index = 0
	
	EffectsPlayer.play("ui_hover")
	update()

func increment_tab(amount):
	tab_index += amount
	if tab_index < 0:
		tab_index = 4
	elif tab_index >= 5:
		tab_index = 0
	
	tabs_label.set_text(tab_names[tab_index])
	get_upgrade_list()
	
	selector_index = 0
	
	EffectsPlayer.play("ui_hover")
	update()

func get_upgrade_list():
	if tab_index == 0:
		upgrade_list = drill_upgrades
		player_upgrade_current = player.drill_upgrade
	elif tab_index == 1:
		upgrade_list = hull_upgrades
		player_upgrade_current = player.hull_upgrade
	elif tab_index == 2:
		upgrade_list = fuel_upgrades
		player_upgrade_current = player.fuel_upgrade
	elif tab_index == 3:
		upgrade_list = radiator_upgrades
		player_upgrade_current = player.radiator_upgrade
	elif tab_index == 4:
		upgrade_list = cargo_upgrades
		player_upgrade_current = player.cargo_upgrade

func open():
	show()
	set_process(true)
	
	get_tree().set_pause(true)
	emit_signal("pause_notification")
	emit_signal("screen_toggle", true)
	
	EffectsPlayer.play("ui_maximize")
	player = get_node("/root/World/Player")
	
	money_label.set_text("$" + str(player.money))	
	
	released = false
	status_text = ""
	selector_index = 0
	tab_index = 0
	tabs_label.set_text(tab_names[tab_index])
	get_upgrade_list()
