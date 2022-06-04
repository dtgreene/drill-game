extends "res://scripts/ui_screen.gd"

const Background = preload("res://assets/images/screen_background.png")

const tab_names = [
	"Items",
	"Repair"
]

onready var money_label = get_node("Money")
onready var tabs_label = get_node("Tabs")
onready var description_label = get_node("Description")

var player = null
var released = false
var status_text = ""
var selector_index = 0
var tab_index = 0

class Item:
	var name = ""
	var cost = 0
	var description = ""
	func _init(_name, _cost, _description = ""):
		name = _name
		cost = _cost
		description = _description

var items_list = [
	Item.new("Reserve Fuel Tank", 2000, "Portable Backup - Refills up to 25 liters instantly."),
	Item.new("Hull Repair Nanobots", 7500, "Repairs 30 hull damage anywhere, anytime."),
	Item.new("Dynamite", 2000, "Blasts clear a small area around your pod."),
	Item.new("Plastic Explosives", 5000, "Creates an enormous explosion, clearing a large area around your pod."),
	Item.new("Quantum Teleporter", 2000, "Teleports you somewhere above the surface. (results may vary)"),
	Item.new("Matter Transmitter", 10000, "Safely and accurately returns you above ground.")
]

var repairs_list = [
	Item.new("$50", 50),
	Item.new("$100", 100),
	Item.new("$200", 200),
	Item.new("$500", 500),
	Item.new("Total Repair", 0)
]

func _ready():
	hide()
	set_process(false)

func _draw():
	draw_texture(Background, Vector2())
	draw_rect(Rect2(Vector2(), Vector2(320, 14)), Color(0, 0, 0))
	
	if tab_index == 0:
		draw_string(M5X7, Vector2(8, 36), "Item")
		draw_string(M5X7, Vector2(180, 36), "Own")
		draw_string(M5X7, Vector2(260, 36), "Cost")
		draw_line(Vector2(4, 40), Vector2(316, 40), Color(1, 1, 1))
		
		draw_rect(Rect2(Vector2(4, 40 + 16 * selector_index), Vector2(312, 16)), GlobalValues.ui_secondary)
		
		var y = 52
		var i = 0
		for item in items_list:
			draw_string(M5X7, Vector2(8, y), item.name)
			draw_string(M5X7, Vector2(180, y), "x" + str(player.equipment[i]))
			draw_string(M5X7, Vector2(260, y), "$" + str(item.cost))
			draw_line(Vector2(4, y + 4), Vector2(316, y + 4), Color(1, 1, 1))
			y += 16
			i += 1
		
	elif tab_index == 1:
		draw_string(M5X7, Vector2(8, 36), "Amount")
		draw_line(Vector2(4, 40), Vector2(316, 40), Color(1, 1, 1))
		
		draw_rect(Rect2(Vector2(4, 40 + 16 * selector_index), Vector2(312, 16)), GlobalValues.ui_secondary)
		
		var y = 52
		for repair in repairs_list:
			draw_string(M5X7, Vector2(8, y), repair.name)
			draw_line(Vector2(4, y + 4), Vector2(316, y + 4), Color(1, 1, 1))
			y += 16
		
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
			if tab_index == 0:
				var item = items_list[selector_index]
				if item.cost > player.money:
					# not enough cash
					status_text = "Err: Not enough cash!"
					EffectsPlayer.play("ui_deny")
					update()
				else:
					player.add_equipment(selector_index)
					player.subtract_money(item.cost)
					
					money_label.set_text("$" + str(player.money))
					
					status_text = "Purchased " + item.name + "!"
					EffectsPlayer.play("cash_register")
					update()
			elif tab_index == 1:
				if player.hull == player.hull_max:
					# if the hull doesn't need repairs
					status_text = "Err: Hull already repaired!"
					EffectsPlayer.play("ui_deny")
					update()
				else:
					var cost = 0
					var amount = 0
					if selector_index < 4:
						var item = repairs_list[selector_index]
						cost = item.cost
						amount = cost * 0.06
					else:
						amount = player.hull_max - player.hull
						cost = ceil(float(amount) / 0.06)
						
					if cost > player.money:
						# not enough cash
						status_text = "Err: Not enough cash!"
						EffectsPlayer.play("ui_deny")
						update()
					else:
						if player.hull + amount > player.hull_max:
							# if buying this much repair goes over hull max
							amount = ceil(player.hull_max - player.hull)
							cost = ceil(float(amount) / 0.06)
						
						player.add_hull(amount)
						player.subtract_money(cost)
						
						money_label.set_text("$" + str(player.money))
						
						status_text = "Purchased $" + str(cost) + " of repairs!"
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
	
	var selector_index_max = 0
	if tab_index == 0:
		selector_index_max = items_list.size()
	elif tab_index == 1:
		selector_index_max = repairs_list.size()
		
	selector_index += amount
	if selector_index < 0:
		selector_index = selector_index_max - 1
	elif selector_index >= selector_index_max:
		selector_index = 0
	
	if tab_index == 0:
		description_label.set_text(items_list[selector_index].description)
	
	update()

func increment_tab(amount):
	EffectsPlayer.play("ui_hover")
	tab_index += amount
	if tab_index < 0:
		tab_index = 1
	elif tab_index >= 2:
		tab_index = 0
	
	if tab_index == 0:
		description_label.show()
	elif tab_index == 1:
		description_label.hide()
	
	tabs_label.set_text(tab_names[tab_index])
	
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
	
	description_label.show()
	description_label.set_text(items_list[0].description)
	
	released = false
	status_text = ""
	selector_index = 0
	tab_index = 0
	tabs_label.set_text(tab_names[tab_index])
