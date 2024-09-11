extends Node

const PlayerScene = preload("res://scenes/player/Player.tscn")
const GlobalValues = preload("res://scripts/global_values.gd")
const MainMusicStream = preload("res://assets/music/main_music.ogg")
const BossMusicStream = preload("res://assets/music/boss_music.ogg")
const BossScene = preload("res://scenes/boss/Boss.tscn")

onready var terrain = get_node("Terrain")
onready var overworld = get_node("Overworld")
onready var underworld = get_node("Underworld")
onready var initial_transmission_timer = get_node("InitialTransmissionTimer")
onready var transmission_screen = get_node("UI/Transmission")
onready var fuel_station_screen = get_node("UI/FuelStation")
onready var mineral_processing_screen = get_node("UI/MineralProcessing")
onready var upgrades_screen = get_node("UI/Upgrades")
onready var item_shop_screen = get_node("UI/ItemShop")
onready var save_screen = get_node("UI/Save")
onready var building_music = get_node("BuildingMusic")
onready var transmission_music = get_node("TransmissionMusic")
onready var main_music = get_node("GameMusic")

var overworld_hidden = false
var underworld_hidden = true
var player = null
var loaded_data = null
var main_music_pos = 0
var boss_fight_started = false
var boss_defeated = false
var message_god_5000_sent = false
var message_god_10000_sent = false
var message_god_100000_sent = false
var message_500_sent = false
var message_1000_sent = false
var message_1700_sent = false
var message_2100_sent = false
var message_2500_sent = false
var message_3100_sent = false
var message_3500_sent = false
var message_4100_sent = false
var message_4500_sent = false
var message_6200_sent = false
var message_7000_sent = false
var earthquake_happened = false

func _ready():
	randomize()
	
	terrain.connect("terrain_ready", self, "terrain_ready")
	initial_transmission_timer.connect("timeout", self, "send_initial_transmission")
	
	fuel_station_screen.connect("screen_toggle", self, "ui_building_toggle")
	mineral_processing_screen.connect("screen_toggle", self, "ui_building_toggle")
	upgrades_screen.connect("screen_toggle", self, "ui_building_toggle")
	item_shop_screen.connect("screen_toggle", self, "ui_building_toggle")
	save_screen.connect("screen_toggle", self, "ui_screen_toggle")
	
	transmission_screen.connect("screen_toggle", self, "ui_transmission_toggle")
	
	var load_slot = Globals.get("load_slot")
	if load_slot == -1:
		terrain.call_deferred("generate_terrain")
	else:
		loaded_data = GlobalValues.load_save_slot(load_slot)
		if loaded_data == null:
			terrain.call_deferred("generate_terrain")
		else:
			terrain.call_deferred("generate_terrain", loaded_data.terrain)
		Globals.set("load_slot", -1)

func terrain_ready():
	get_node("UI/Loading").queue_free()
	
	player = PlayerScene.instance()
	player.position = Vector2(8 * 32, -32)
	add_child(player)
	
	player.connect("depth_change", self, "player_depth_change")
	player.connect("died", self, "player_died")
	
	player.get_node("UI/Inventory").connect("screen_toggle", self, "ui_screen_toggle")
	player.get_node("UI/Pause").connect("screen_toggle", self, "ui_pause_toggle")
	
	if loaded_data == null:
		# give player some money
		player.add_money(20)
		
		# only show the first transmission if not seen yet this playthrough
		if(!Globals.seen_initial_transmission):
			# send initial transmission
			initial_transmission_timer.start()
	else: 
		player.add_money(loaded_data.player.money)
		
		player.cargo_minerals = loaded_data.player.cargo_minerals
		player.hull = loaded_data.player.hull
		
		if "has_guardian" in loaded_data.player:
			if loaded_data.player.has_guardian:
				player.grant_guardian()
		
		player.equipment = loaded_data.player.equipment
		
		# drill upgrade
		player.upgrade_drill(
			upgrades_screen.drill_upgrades[
				loaded_data.player.drill_upgrade_level
			]
		)
		# hull upgrade
		player.upgrade_hull(
			upgrades_screen.hull_upgrades[
				loaded_data.player.hull_upgrade_level
			]
		)
		# fuel upgrade
		player.upgrade_fuel(
			upgrades_screen.fuel_upgrades[
				loaded_data.player.fuel_upgrade_level
			]
		)
		# radiator upgrade
		player.upgrade_radiator(
			upgrades_screen.radiator_upgrades[
				loaded_data.player.radiator_upgrade_level
			]
		)
		# cargo upgrade
		player.upgrade_cargo(
			upgrades_screen.cargo_upgrades[
				loaded_data.player.cargo_upgrade_level
			]
		)
		
		if "message_god_5000_sent" in loaded_data.world:
			message_god_5000_sent = loaded_data.world.message_god_5000_sent
		if "message_god_10000_sent" in loaded_data.world:
			message_god_10000_sent = loaded_data.world.message_god_10000_sent
		if "message_god_100000_sent" in loaded_data.world:
			message_god_100000_sent = loaded_data.world.message_god_100000_sent
		
		message_500_sent = loaded_data.world.message_500_sent
		message_1000_sent = loaded_data.world.message_1000_sent
		message_1700_sent = loaded_data.world.message_1700_sent
		message_2100_sent = loaded_data.world.message_2100_sent
		message_2500_sent = loaded_data.world.message_2500_sent
		message_3100_sent = loaded_data.world.message_3100_sent
		message_3500_sent = loaded_data.world.message_3500_sent
		message_4100_sent = loaded_data.world.message_4100_sent
		message_4500_sent = loaded_data.world.message_4500_sent
		message_6200_sent = loaded_data.world.message_6200_sent
		message_7000_sent = loaded_data.world.message_7000_sent
		earthquake_happened = loaded_data.world.earthquake_happened
		boss_defeated = loaded_data.world.boss_defeated
	
	main_music.play()

func enter_fuel_station():
	fuel_station_screen.open()

func enter_mineral_processing():
	mineral_processing_screen.open()

func enter_upgrades():
	upgrades_screen.open()

func enter_item_shop():
	item_shop_screen.open()

func enter_save():
	save_screen.open()

func roll_for_earthquake():
	if !earthquake_happened:
		if player.depth_100_max > 3000:
			if floor(rand_range(0, 20)) == 0:
				player.earthquake()
				terrain.call_deferred("earthquake")
				earthquake_happened = true

func ui_screen_toggle(open):
	if open:
		building_music.play()
		main_music_pos = main_music.get_playback_position()
		main_music.stop()
	else: 
		building_music.stop()
		main_music.play(main_music_pos)

func ui_pause_toggle(open):
	if open:
		main_music_pos = main_music.get_playback_position()
		main_music.stop()
	else:
		main_music.play(main_music_pos)

func ui_building_toggle(open):
	if open:
		building_music.play()
		main_music_pos = main_music.get_playback_position()
		main_music.stop()
	else: 
		building_music.stop()
		main_music.play(main_music_pos)
		roll_for_earthquake()

func ui_transmission_toggle(open):
	if open:
		transmission_music.play()
		main_music_pos = main_music.get_playback_position()
		main_music.stop()
	else: 
		transmission_music.stop()
		main_music.play(main_music_pos)

func player_died():
	if boss_fight_started:
		stop_boss_fight()
	
	main_music.stop()

func boss_died():
	main_music.set_stream(MainMusicStream)
	main_music.play()
	boss_fight_started = false
	boss_defeated = true
	
	player.add_money(2000000)
	transmission_screen.transmit([
		"** Transmission Received **",
		"",
		"Sender: Evil Elf",
		"",
		"Ahhhhh! How can this be?!",
		"",
		"Santa's been on vacation these past few weeks",
		"and well... I thought I could fill his shoes",
		"while he's gone.",
		"",
		"** Transmission Terminated **"
	])

func start_boss_fight():
	main_music.set_stream(BossMusicStream)
	main_music.play()
	boss_fight_started = true
	
	var boss = BossScene.instance()
	boss.connect("died", self, "boss_died")
	underworld.add_child(boss)

func stop_boss_fight():
	main_music.set_stream(MainMusicStream)
	
	if player.alive:
		main_music.play()
	
	boss_fight_started = false
	
	underworld.get_node("Boss").queue_free()

func stop_all_music():
	main_music.stop()
	transmission_music.stop()
	building_music.stop()

func player_depth_change(depth):
	# toggle surface visibility
	if !overworld_hidden: 
		if depth > 0:
			overworld_hidden = true
			overworld.hide()
	else:
		if depth <= 100:
			overworld_hidden = false
			overworld.show()
	
	if !underworld_hidden:
		if depth < 7000:
			underworld_hidden = true
			underworld.hide()
	else:
		if depth >= 7000:
			underworld_hidden = false
			underworld.show()
	
	if depth < 7100:
		if boss_fight_started:
			stop_boss_fight()
	
	if depth == -5100:
		if !message_god_5000_sent:
			message_god_5000_sent = true
			player.add_money(5000)
			transmission_screen.transmit([
				"** Transmission Received **",
				"",
				"Sender: Mr.Dog",
				"",
				"Hark, what strange thing is this? Make haste",
				"from my domain, Human, for you tread in the",
				"realm of the divine! Thine foul machinery",
				"creates much distaste among my choirs.",
				"",
				"You are still here? Fine, take this and GET OUT.",
				"",
				"** Transmission Terminated **"
			])
	elif depth == -10100:
		if !message_god_10000_sent:
			message_god_10000_sent = true
			player.grant_guardian()
			transmission_screen.transmit([
				"** Transmission Received **",
				"",
				"Sender: GOD",
				"",
				"Hast thou tired of tunneling the depths before",
				"thy time? Seek ye instead to soar the highest",
				"reaches of my heavens?",
				"",
				"Return now to thy rightly domain - carry with",
				"thee this guardian to aide thy journey.",
				"",
				"** Transmission Terminated **"
			])
	elif depth == -100100:
		if !message_god_100000_sent:
			message_god_100000_sent = true
			transmission_screen.transmit([
				"** Transmission Received **",
				"",
				"Sender: GOD",
				"",
				"Thou has too much time on thy hands.",
				"",
				"** Transmission Terminated **"
			])
	
	if depth == 500:
		if !message_500_sent:
			message_500_sent = true
			player.add_money(1000)
			transmission_screen.transmit([
				"** Transmission Received **",
				"",
				"Sender: Santa",
				"",
				"Good! I see you're adapting well to the North",
				"Pole soil!",
				"",
				"Here's a little something to help you along",
				"your way.",
				"",
				"** Transmission Terminated **"
			])
	elif depth == 1000:
		if !message_1000_sent:
			message_1000_sent = true
			player.add_money(3000)
			transmission_screen.transmit([
				"** Transmission Received **",
				"",
				"Sender: Santa",
				"",
				"Congratulations on reaching a depth of 1000",
				"ft! I've wired you a bonus for your excellent",
				"work.",
				"",
				"We're picking up some heavy vibrations from",
				"the planet core - They seem to be causing some",
				"earthquakes. They also seem to be causing some",
				"garbled and misdirected transmissions - just",
				"ignore them.",
				"",
				"Keep up the good work!",
				"",
				"** Transmission Terminated **"
			])
	elif depth == 1700:
		if !message_1700_sent:
			message_1700_sent = true
			transmission_screen.transmit([
				"** Transmission Received **",
				"",
				"Sender: Unknown",
				"",
				"The eyes... Oh my god, THE EYES!!!",
				"",
				"** Transmission Terminated **"
			])
	elif depth == 2100:
		if !message_2100_sent:
			message_2100_sent = true
			transmission_screen.transmit([
				"** Transmission Received **",
				"",
				"Sender: Elf Digging Pod #122521",
				"",
				"I'm surprised to find another signal around",
				"here...",
				"",
				"I'm one of the few miners who hasn’t",
				"disappeared in the past few months. Next",
				"week, I finally get to retire, wealthy, to the",
				"South Pole with my wife and three daughters.",
				"",
				"** Transmission Terminated **"
			])
	elif depth == 2500:
		if !message_2500_sent:
			message_2500_sent = true
			transmission_screen.transmit([
				"** Transmission Received **",
				"",
				"Sender: Unknown",
				"",
				"Is anyone there?! I need help badly!! I can't",
				"feel my legs - Oh god, he's coming back..",
				"",
				"OH NO!! PLEASE HELP ME!!! AAAHHHHGGGK!",
				"",
				"** Transmission Terminated **"
			])
	elif depth == 3100:
		if !message_3100_sent:
			message_3100_sent = true
			transmission_screen.transmit([
				"** Transmission Received **",
				"",
				"Sender: Elf Digging Pod #122521",
				"",
				"How are you making out, kid? I know you're new",
				"here, so I thought I'd give you a tip; make",
				"sure you don't neglect your radiator.",
				"",
				"I ran into a Lava pocket a few moments ago,",
				"but my twin turbines dissipated the heat",
				"amazingly and my hull was barely damaged -",
				"Probably saved my life.",
				"",
				"** Transmission Terminated **"
			])
	elif depth == 3500:
		if !message_3500_sent:
			message_3500_sent = true
			player.add_money(25000)
			transmission_screen.transmit([
				"** Transmission Received **",
				"",
				"Sender: Santa",
				"",
				"Once again, congratulations! You've made it",
				"farther than even I anticipated...",
				"",
				"Anyways, I've sent you another bonus. Watch",
				"out for natural gas pockets after around",
				"4700ft - they're undetectable and highly",
				"explosive!",
				"",
				"One more thing - your altimeter is only rated",
				"for a depth of around 6000 ft. After that,",
				"you'll need to turn back. Really - it's just",
				"too dangerous.",
				"",
				"** Transmission Terminated **"
			])
	elif depth == 4100:
		if !message_4100_sent:
			message_4100_sent = true
			transmission_screen.transmit([
				"** Transmission Received **",
				"",
				"Sender: Elf Digging Pod #122521",
				"",
				"Trapped... In a crevasse.",
				"",
				"Earthquake damaged my drill and I'm out of",
				"fuel.",
				"",
				"This will probably be my last transmission.",
				"",
				"Tell my kids.. I love them.. I-",
				"",
				"what? YOU!?? what are you doing dow-AAARGH!",
				"",
				"** Transmission Terminated **"
			])
	elif depth == 4500:
		if !message_4500_sent:
			message_4500_sent = true
			transmission_screen.transmit([
				"** Transmission received **",
				"",
				"Sender: Elf Digging Pod #100419",
				"",
				"Oh BABY!!! THIS IS IT!!! I HIT THE",
				"MOTHERLOAD!!!!! I'm rich, I’m FILTHY rich!!",
				"",
				"Hey, what the!?? NO! IT CAN'T BE!!!! OH GOD!!",
				"",
				"** Transmission Terminated **"
			])
	elif depth == 6200:
		if !message_6200_sent:
			message_6200_sent = true
			transmission_screen.transmit([
				"** Transmission Received **",
				"",
				"Sender: Santa",
				"",
				"You are violating the terms of your",
				"employment! Turn back immediately or you'll",
				"get coal in your stocking for sure!",
				"",
				"** Transmission Terminated **"
			])
	elif depth == 7000:
		if !message_7000_sent:
			message_7000_sent = true
			transmission_screen.transmit([
				"** Transmission Received **",
				"",
				"Sender: Santa",
				"",
				"Return to the surface immediately or you'll be",
				"terminated... er... as in fired!",
				"",
				"** Transmission Terminated **"
			])
	elif depth == 7200:
		if !boss_defeated && !boss_fight_started:
			transmission_screen.transmit([
				"** Transmission Received **",
				"",
				"Sender: Santa",
				"",
				"FOOLISH CHILD!!!",
				"I told you to turn back... now you must die!",
				"",
				"Your days of drilling are through!",
				"",
				"** Transmission Terminated **"
			])
			start_boss_fight()

func send_initial_transmission():
	# indicate that we've seen the first transmission
	Globals.seen_initial_transmission = true
	
	transmission_screen.transmit([
		"** Transmission Received **",
		"",
		"Sender: Santa",
		"",
		"We forgot to refuel you on the way over! Drive",
		"over to the fuel station (left) and fill 'er",
		"up!",
		"",
		"It's been almost impossible to hire decent elf",
		"miners since all the strange activity started",
		"happening around here. That's why we’re",
		"willing to pay you at a premium for your",
		"services!",
		"",
		"I've given you a basic mining machine to get",
		"started with. Unfortunately, you'll be on your",
		"own from this point forward.",
		"",
		"Remember - your job is to collect minerals and",
		"bring them back to the surface for processing.",
		"The deeper you dig, the more valuable the",
		"minerals you'll encounter.",
		"",
		"Don't forget to refuel - Good Luck!",
		"",
		"** Transmission Terminated **"
	])
