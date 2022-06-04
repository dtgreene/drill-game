extends "res://scripts/ui_screen.gd"

const FuelPump = preload("res://assets/images/fuel_pump.png")
const Background = preload("res://assets/images/screen_background.png")

onready var money_label = get_node("Money")

class Item:
	var name = ""
	var cost = 0
	func _init(_name, _cost):
		name = _name
		cost = _cost

var fuel_list = [
	Item.new("$5", 5),
	Item.new("$10", 10),
	Item.new("$25", 25),
	Item.new("$50", 50),
	Item.new("Fill Tank", 0)
]

var player = null
var released = false
var selector_index = 0
var status_text = ""

func _ready():
	hide()
	set_process(false)

func _draw():
	draw_texture(Background, Vector2())
	draw_rect(Rect2(Vector2(), Vector2(320, 14)), Color(0, 0, 0))
	
	draw_string(M5X7, Vector2(8, 25), "Amount")
	draw_line(Vector2(4, 29), Vector2(158, 29), Color(1, 1, 1))
	
	draw_rect(Rect2(Vector2(4, 29 + 16 * selector_index), Vector2(154, 16)), GlobalValues.ui_secondary)
	
	var i = 0
	while i < fuel_list.size():
		var y = 41 + i * 16
		draw_string(M5X7, Vector2(8, y), fuel_list[i].name)
		draw_line(Vector2(4, y + 4), Vector2(158, y + 4), Color(1, 1, 1))
		i += 1
	
	if status_text.length() > 0:
		draw_rect(Rect2(Vector2(4, 197), Vector2(312, 18)), GlobalValues.ui_secondary)
		draw_string(M5X7, Vector2(8, 209), status_text)
	
	draw_texture(FuelPump, Vector2(242, 39))
	
	draw_string(M5X7, Vector2(166, 25), "Fuel Level")
	# ((n-start1)/(stop1-start1))*(stop2-start2)+start2
	var bar_width = float(player.fuel / player.fuel_max) * 154
	draw_rect(Rect2(Vector2(162, 29), Vector2(154, 8)), GlobalValues.ui_secondary)
	draw_rect(Rect2(Vector2(162, 29), Vector2(bar_width, 8)), GlobalValues.ui_primary)
	
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
	elif Input.is_action_pressed("ui_accept"):
		if released:
			if player.fuel == player.fuel_max:
				# if the fuel tank is full
				status_text = "Err: Fuel tank already full!"
				EffectsPlayer.play("ui_deny")
				update()
			else:
				# determine the amount
				var amount = 0
				if selector_index < 4:
					var selected_fuel = fuel_list[selector_index]
					amount = selected_fuel.cost
				else:
					amount = ceil(player.fuel_max - player.fuel)
				
				# check if player can afford it
				if player.money < amount:
					# not enough cash
					status_text = "Err: Not enough cash!"
					EffectsPlayer.play("ui_deny")
					update()
				else:
					if player.fuel + amount > player.fuel_max:
						# if buying this much fuel goes over fuel max
						amount = ceil(player.fuel_max - player.fuel)
					
					player.add_fuel(amount)
					player.subtract_money(amount)
					
					money_label.set_text("$" + str(player.money))
					
					status_text = "Purchased $" + str(amount) + " of fuel!"
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
	EffectsPlayer.play("ui_hover")
	selector_index += amount
	if selector_index < 0:
		selector_index = 4
	elif selector_index >= 5:
		selector_index = 0
	update()

func open():
	show()
	set_process(true)
	
	get_tree().set_pause(true)
	emit_signal("pause_notification")
	emit_signal("screen_toggle", true)
	
	EffectsPlayer.play("ui_maximize")
	player = get_node("/root/World/Player")
	
	money_label.set_text("$" + str(player.money))
	
	selector_index = 0
	released = false
	status_text = ""
