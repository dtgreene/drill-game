extends "res://scripts/ui_screen.gd"

const FuelPump = preload("res://assets/images/fuel_pump.png")
const Background = preload("res://assets/images/screen_background.png")

const mineral_values = [
	30,
	60,
	100,
	250,
	750,
	2000,
	5000,
	20000,
	50000,
	100000
]

onready var money_label = get_node("Money")

var mineral_names = GlobalValues.mineral_names

var player = null
var released = false
var status_text = ""
var has_minerals = false

func _ready():
	hide()
	set_process(false)

func _draw():
	draw_texture(Background, Vector2())
	draw_rect(Rect2(Vector2(), Vector2(320, 14)), Color(0, 0, 0))
	
	draw_string(M5X7, Vector2(8, 25), "Mineral")
	draw_string(M5X7, Vector2(156, 25), "Ct")
	draw_string(M5X7, Vector2(260, 25), "Value")
	draw_line(Vector2(4, 29), Vector2(316, 29), Color(1, 1, 1))
	
	if has_minerals:
		var i = 0
		var y = 41
		var mineral_list = player.cargo_minerals
		while i < mineral_list.size():
			if mineral_list[i] > 0:
				draw_string(M5X7, Vector2(8, y), mineral_names[i])
				draw_string(M5X7, Vector2(156, y), "x" + str(mineral_list[i]))
				draw_string(M5X7, Vector2(260, y), "$" + str(mineral_values[i] * mineral_list[i]))
				draw_line(Vector2(4, y + 4), Vector2(316, y + 4), Color(1, 1, 1))
				y += 16
			i += 1
	else:
		draw_string(M5X7, Vector2(8, 41), "Cargo bay empty")
	
	if status_text.length() > 0:
		draw_rect(Rect2(Vector2(4, 197), Vector2(312, 18)), GlobalValues.ui_secondary)
		draw_string(M5X7, Vector2(8, 209), status_text)
	
	draw_icon_string(0, Vector2(244, 219), "Sell All", -38)
	draw_icon_string(1, Vector2(299, 219), "Close", -30)

func _process(_delta):
	if Input.is_action_pressed("ui_accept"):
		if released:
			if !has_minerals:
				# if there's no minerals
				status_text = "Err: No minerals to sell!"
				EffectsPlayer.play("ui_deny")
				update()
			else:
				var amount = 0
				var i = 0
				var minerals = player.cargo_minerals
				while i < minerals.size():
					if minerals[i] > 0:
						amount += mineral_values[i] * minerals[i]
					i += 1
				player.add_money(amount)
				player.remove_all_minerals()
				
				money_label.set_text("$" + str(player.money))
				
				status_text = "Sold all minerals!"
				
				check_minerals()
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

func check_minerals():
	has_minerals = false
	for mineral in player.cargo_minerals:
		if mineral > 0:
			has_minerals = true
			break

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
	check_minerals()
