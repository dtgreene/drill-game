extends KinematicBody2D

const GlobalValues = preload("res://scripts/global_values.gd")
const Explosion = preload("res://scenes/world/Explosion.tscn")
const DebrisParts = preload("res://scenes/player/DebrisParts.tscn")
const DeathScreen = preload("res://scenes/player/DeathScreen.tscn")

const bounds_x_min = 0
const bounds_x_max = (GlobalValues.col_count - 1) * 32

# rare items
const rare_item_names = ["Settler bones", "Ox Skull", "Snowglobe"]
const rare_item_values = [5000, 10000, 50000]

enum DrillStates {
	IDLE,
	WAITING_ON_H_ANIMATION,
	DRILLING
}

enum TeleportStates {
	IDLE,
	QUANTUM_FADING,
	MATTER_FADING,
	REAPPEAR
}

var DigDirections = GlobalValues.DigDirections
var ShakeDirections = GlobalValues.ShakeDirections

onready var world = get_node("/root/World")
onready var terrain = world.get_node("Terrain")
onready var terrain_background = terrain.get_node("Background")
onready var upgrades_screen = world.get_node("UI/Upgrades")

onready var area = get_node("Area2D")
onready var sprites = get_node("Sprites")
onready var drill_car = get_node("Sprites/DrillCar")
onready var drill_h = get_node("Sprites/DrillH")
onready var drill_v = get_node("Sprites/DrillV")
onready var dirt_particles = get_node("DirtParticles")
onready var ui_status = get_node("Status")
onready var ui_depth = get_node("UI/Depth")
onready var ui_money = get_node("UI/Money")
onready var ui_money_increment = get_node("UI/MoneyIncrement")
onready var inventory_screen = get_node("UI/Inventory")
onready var pause_screen = get_node("UI/Pause")
onready var health_and_fuel = get_node("UI/HealthAndFuel")
onready var fuel_status = get_node("UI/FuelStatus")
onready var loading_screen = get_node("UI/Loading")
onready var teleport_timer = get_node("TeleportTimer")
onready var death_timer = get_node("DeathTimer")
onready var camera = get_node("Camera2D")

var alive = true
var velocity = Vector2()
var on_ground = false
var drill_state = DrillStates.IDLE
var drill_target_col = -1
var drill_target_row = -1
var drill_target = Vector2()
var drill_velocity = Vector2()
var dig_direction = DigDirections.NONE
var sprite_rotation = 0
var flipped = false
var depth_100 = 0
var depth = 0
var depth_100_max = 0
var color_decay = 0
var engine_idle_voice = null
var drill_voice = null
var engine_thrust_voice = null
var engine_thrust_voice_pitch = 0.6
var money = 0
var released = false
var teleport_state = TeleportStates.IDLE
var teleport_scale = 1
var last_damage_reason = "Unknown"
var explosive_cooldown = 0

# drill upgrade
var drill_upgrade = null
var drill_speed = 0

# hull upgrade
var hull_upgrade = null
var hull = 0
var hull_max = 0

# fuel upgrade
var fuel_upgrade = null
var fuel = 0
var fuel_max = 0

# radiator upgrade
var radiator_upgrade = null
var radiator = 0

# cargo upgrade
var cargo_minerals = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
var cargo_upgrade = null
var cargo_count_max = 0
var cargo_count = 0

# equipment
var equipment = [0, 0, 0, 0, 0, 0]

signal depth_change(depth)
signal died()
signal used_explosive(is_plastic)

func _ready():
	area.set_meta("is_player", true)
	
	drill_h.connect("retracted", self, "drill_h_retracted")
	drill_v.connect("extended", self, "drill_v_extended")
	
	engine_idle_voice = EffectsPlayer.get_player("engine_idle")
	engine_idle_voice.play()
	
	var nodes = [
		get_node("/root/World/UI/Transmission"),
		get_node("/root/World/UI/FuelStation"),
		get_node("/root/World/UI/MineralProcessing"),
		get_node("/root/World/UI/Upgrades"),
		get_node("/root/World/UI/ItemShop"),
		get_node("/root/World/UI/Save"),
		inventory_screen,
		pause_screen
	]
	
	for node in nodes:
		node.connect("pause_notification", self, "pause_notification")
	
	get_node("FuelTimer").connect("timeout", self, "update_fuel")
	
	teleport_timer.connect("timeout", self, "teleport_reappear")
	death_timer.connect("timeout", self, "show_death_screen")
	
	drill_upgrade = upgrades_screen.drill_upgrades[0]
	drill_speed = drill_upgrade.value
	
	hull_upgrade = upgrades_screen.hull_upgrades[0]
	hull_max = hull_upgrade.value
	hull = hull_max
	
	fuel_upgrade = upgrades_screen.fuel_upgrades[0]
	fuel = 5
	fuel_max = fuel_upgrade.value
	
	radiator_upgrade = upgrades_screen.radiator_upgrades[0]
	radiator = radiator_upgrade.value
	
	cargo_upgrade = upgrades_screen.cargo_upgrades[0]
	cargo_count_max = cargo_upgrade.value
	
	loading_screen.hide()

	set_physics_process(true)

func earthquake():
	camera.add_shake(120)
	EffectsPlayer.play("earthquake")

func show_death_screen(): 
	emit_signal("died")
	
	var death_screen = DeathScreen.instance()
	get_node("/root/World/UI").add_child(death_screen)
	EffectsPlayer.play("game_over")
	death_screen.open(last_damage_reason)

func drill_h_retracted():
	if drill_state == DrillStates.WAITING_ON_H_ANIMATION:
		drill_v.extend()

func drill_v_extended():
	if drill_state == DrillStates.WAITING_ON_H_ANIMATION:
		drill_state = DrillStates.DRILLING
		sprites.shake(ShakeDirections.VERTICAL)
		dirt_particles.position = Vector2(0, 28)
		dirt_particles.set_emitting(true)
		drill_voice = EffectsPlayer.get_player("drill")
		drill_voice.set_pitch_scale(1 + rand_range(0, 0.1))
		drill_voice.play()

func begin_drilling(position, direction):
	var terrain_col = floor((position.x + 16) / 32)
	var terrain_row = floor((position.y + 16) / 32)
	
	if direction == DigDirections.DOWN:
		terrain_row += 1
	elif direction == DigDirections.LEFT:
		terrain_col -= 1
	elif direction == DigDirections.RIGHT:
		terrain_col += 1
	
	if !terrain.is_block_drillable(terrain_col, terrain_row): return
	
	# set target
	drill_target_col = terrain_col
	drill_target_row = terrain_row
	drill_target = Vector2(terrain_col * 32, terrain_row * 32)
	
	var speed = drill_speed * GlobalValues.remap(terrain_row, 0, GlobalValues.row_count, 1, 2)
	# set velocity needed to reach target
	drill_velocity = Vector2(
		(drill_target.x - position.x) / speed, 
		(drill_target.y - position.y) / speed
	)
	# stop player velocity
	velocity = Vector2()
	# disable collisions on the player
	$CollisionShape2D.disabled = true
	# set dig direction
	dig_direction = direction
	# reset rotation
	sprite_rotation = 0
	
	if direction == DigDirections.DOWN:
		drill_h.retract()
		drill_state = DrillStates.WAITING_ON_H_ANIMATION
	else:
		drill_state = DrillStates.DRILLING
		sprites.shake(ShakeDirections.HORIZONTAL)
		if flipped:
			dirt_particles.position = Vector2(-28, 0)
		else:
			dirt_particles.position = Vector2(28, 0)
		dirt_particles.set_emitting(true)
		drill_voice = EffectsPlayer.get_player("drill")
		drill_voice.set_pitch_scale(1 + rand_range(0, 0.1))
		drill_voice.play()

func stop_drilling():
	# dig out the terrain
	var mineral = terrain.dig(drill_target_col, drill_target_row)
	
	if mineral != null:
		add_mineral(mineral)
	elif depth_100 > 4700:
		# roll for gas pocket
		if rand_range(0, 1) < GlobalValues.remap(depth_100, 4700, 7500, 0, 1):
			# ((Depth in feet + 3000) / 15) x (1 - Radiator's Effectiveness)
			remove_hull((floor(position.y * 0.390625) / 15) * (1 - radiator), "gas pocket")
			terrain.explode(position, 1, false, true)
			EffectsPlayer.play("dynamite")
	
	if dig_direction == DigDirections.DOWN:
		drill_v.retract()
	
	drill_voice.stop()
	
	# reset drill variables
	drill_target_col = -1
	drill_target_row = -1
	drill_target = Vector2()
	drill_velocity = Vector2()
	
	# enable collisions on the player
	$CollisionShape2D.disabled = false
	
	dig_direction = DigDirections.NONE
	drill_state = DrillStates.IDLE
	
	sprites.stop_shaking()
	dirt_particles.set_emitting(false)

func teleport_reappear():
	loading_screen.hide()
	teleport_state = TeleportStates.IDLE

func add_equipment(index):
	equipment[index] += 1

func upgrade_drill(upgrade):
	drill_upgrade = upgrade
	drill_speed = upgrade.value

func upgrade_hull(upgrade):
	hull_upgrade = upgrade
	hull_max = upgrade.value
	hull = hull_max

func upgrade_fuel(upgrade):
	fuel_upgrade = upgrade
	fuel_max = upgrade.value
	fuel = fuel_max

func upgrade_radiator(upgrade):
	radiator_upgrade = upgrade
	radiator = upgrade.value

func upgrade_cargo(upgrade):
	cargo_upgrade = upgrade
	cargo_count_max = upgrade.value

func add_mineral(mineral):
	if mineral < 10:
		# normal mineral
		if cargo_count + 1 <= cargo_count_max:
			cargo_minerals[mineral] += 1
			cargo_count += 1
			
			if cargo_count == cargo_count_max:
				ui_status.update_value("Cargo bay full!")
				EffectsPlayer.play("cargo_full")
			else:
				ui_status.update_value("+1 " + GlobalValues.mineral_names[mineral])
				EffectsPlayer.play("mineral_pickup")
		else:
			ui_status.update_value("Cargo bay full!")
			EffectsPlayer.play("cargo_full")
	if mineral == 11:
		# lava
		var damage = rand_range(20, 40)
		remove_hull(round(damage - damage * radiator), "lava pocket")
		EffectsPlayer.play("blunt_damage")
	elif mineral > 11:
		# special mineral
		ui_status.update_value("Found " + str(rare_item_names[mineral - 12]) + "!")
		add_money(rare_item_values[mineral - 12])
		EffectsPlayer.play("mineral_special_pickup")

func remove_mineral(mineral):
	cargo_minerals[mineral] -= 1
	cargo_count -= 1

func remove_all_minerals():
	cargo_minerals = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	cargo_count = 0

func add_hull(amount):
	hull = clamp(hull + amount, 0, hull_max)

func shake_camera(amount):
	camera.add_shake(amount)

func remove_hull(amount, reason):
	if !alive: return
	
	hull = clamp(hull - amount, 0, hull_max)
	drill_car.set_modulate(Color(1, 0, 0))
	color_decay = 0.5
	health_and_fuel.update()
	last_damage_reason = reason
	
	camera.add_shake(10)
	
	if hull <= 0:
		alive = false
		EffectsPlayer.stop_all()
		engine_thrust_voice = null
		
		drill_state = DrillStates.IDLE
		sprites.stop_shaking()
		dirt_particles.set_emitting(false)
		
		drill_h.retract()
		drill_v.retract()
		
		EffectsPlayer.play("player_death")
		
		$CollisionShape2D.disabled = true
		
		sprites.hide()
		
		remove_child(get_node("UI"))
		
		add_child(Explosion.instance())
		var debris = DebrisParts.instance()
		debris.set_linear_velocity(velocity)
		
		if flipped:
			debris.get_node("Sprite").set_flip_h(true)
			
		add_child(debris)
		
		death_timer.start()

func add_money(amount):
	money += amount
	ui_money.set_text("$" + str(money))
	ui_money_increment.prefix = "+$"
	ui_money_increment.update_value(amount, Color(0, 1, 0))

func subtract_money(amount):
	money = max(money - amount, 0)
	ui_money.set_text("$" + str(money))
	ui_money_increment.prefix = "-$"
	ui_money_increment.update_value(amount, Color(1, 0, 0))

func add_fuel(amount):
	fuel = clamp(fuel + amount, 0, fuel_max)

func subtract_fuel(amount):
	fuel = clamp(fuel - amount, 0, fuel_max)
	
	if fuel <= 0:
		remove_hull(hull_max, "lack of fuel")

func update_fuel():
	if !alive: return
	
	var fuel_percent = float(fuel) / fuel_max

	if fuel_percent < 0.1:
		EffectsPlayer.play("fuel_critical")
		fuel_status.set_text("Fuel Critical!")
	elif fuel_percent < 0.3:
		fuel_status.set_text("Fuel Low")
	else:
		fuel_status.set_text("")
	health_and_fuel.update()

func pause_notification():
	if get_tree().is_paused():
		EffectsPlayer.stop_all()
		engine_thrust_voice = null
		engine_thrust_voice_pitch = 0.6
	elif alive:
		engine_idle_voice = EffectsPlayer.get_player("engine_idle")
		engine_idle_voice.play()
		if drill_state == DrillStates.DRILLING:
			drill_voice = EffectsPlayer.get_player("drill")
			drill_voice.play()
		
		# possibly stop falling when coming back from a pause
		# velocity.y = 0

func _process(delta):
	
	# update terrain background
	terrain_background.update_y(floor(position.y))
	
	# update terrain chunks
	terrain.update_chunks(position)
	
	# calculate depth in feet
	# position.y / 32 * 12.5
	var current_depth = floor(position.y * 0.390625)
	if current_depth != depth:
		depth = current_depth
		if depth < 5800:
			ui_depth.set_text(str(depth) + "ft")
		elif depth < 7200:
			ui_depth.set_text("?" + str(floor(rand_range(5800, 10000))) + "ft")
		else:
			ui_depth.set_text("-666666ft")
	
	# calculate nearest 100 depth
	var current_depth_100 = 100 * floor(current_depth * 0.01)
	if depth_100 != current_depth_100:
		depth_100 = current_depth_100
		if depth_100 > depth_100_max:
			depth_100_max = depth_100
		emit_signal("depth_change", depth_100)
	
	if color_decay > 0:
		color_decay -= delta
		if color_decay <= 0:
			drill_car.set_modulate(Color(1, 1, 1))
	
	if explosive_cooldown > 0:
		explosive_cooldown -= delta
	
	# go no further if dead
	if !alive: return

	# adjust engine pitch
	# max engine idle pitch 1.5
	# min engine idle pitch 1.0
	var engine_idle_voice_pitch = abs(velocity.x) / 300.0 * 0.5 + 1
	engine_idle_voice.set_pitch_scale(engine_idle_voice_pitch)
	engine_idle_voice.set_volume_db(GlobalValues.remap(engine_idle_voice_pitch, 1, 1.5, 0, 4))
	
	# if drilling
	if drill_state != DrillStates.IDLE: 
		if drill_state == DrillStates.DRILLING:
			var x_diff = abs(position.x - drill_target.x)
			var y_diff = abs(position.y - drill_target.y)
			
			if x_diff < 1 && y_diff < 1:
				stop_drilling()
			else:
				position = Vector2(position.x + drill_velocity.x, position.y + drill_velocity.y)
			
			# update fuel specifically for drilling
			subtract_fuel(0.0046)
			
			# stop the thrust sound if playing
			if engine_thrust_voice != null:
				engine_thrust_voice_pitch = 0.6
				engine_thrust_voice.stop()
				engine_thrust_voice = null
		return
	
	# if teleporting
	if teleport_state != TeleportStates.IDLE: 
		if teleport_scale > 0:
			teleport_scale -= 0.1
			var scale = Vector2(1, teleport_scale)
			if flipped:
				scale.x = -1
				
			sprites.set_scale(scale)
		elif teleport_state != TeleportStates.REAPPEAR:
			if teleport_state == TeleportStates.QUANTUM_FADING:
				position = Vector2(rand_range(1, GlobalValues.col_count - 1) * 32, rand_range(2, 4) * -32)
				velocity = Vector2(rand_range(0, 400) - 200, rand_range(200, 400))
			elif teleport_state == TeleportStates.MATTER_FADING:
				position = Vector2(8 * 32, -64)
				velocity = Vector2()
			
			loading_screen.show()
			var scale = Vector2(1, 1)
			if flipped:
				scale.x = -1
			sprites.set_scale(Vector2(scale))
			teleport_state = TeleportStates.REAPPEAR
			teleport_timer.start()
		
		# stop the thrust sound if playing
		if engine_thrust_voice != null:
			engine_thrust_voice_pitch = 0.6
			engine_thrust_voice.stop()
			engine_thrust_voice = null
		return
	
	# input alias
	var right_pressed = Input.is_action_pressed("move_right")
	var left_pressed = Input.is_action_pressed("move_left")
	var up_pressed = Input.is_action_pressed("move_up")
	var down_pressed = Input.is_action_pressed("move_down")
	
	var block_below = false
	var block_left = false
	var block_right = false
	
	# determine if player is on ground
	var used_body_pos
	var used_x_diff
	var used_y_diff
	for body in area.get_overlapping_bodies():
		# only terrain has the is_terrain meta, we don't really care about its value
		if body.has_meta("is_terrain"):
			used_body_pos = body.global_position
			used_x_diff = abs(used_body_pos.x - position.x)
			used_y_diff = abs(used_body_pos.y - position.y)
			
			# establish nearby blocks
			if used_x_diff <= 30 && used_body_pos.y > position.y:
				block_below = true
			elif used_y_diff <= 30:
				if used_body_pos.x < position.x:
					block_left = true
				elif used_body_pos.x > position.x:
					block_right = true
	
	# store the current on ground value
	var previous_on_ground = on_ground
	on_ground = block_below
	
	# set fuel use to default
	var fuel_usage = 0.0012
	
	# horizontal movement
	if right_pressed:
		velocity.x += 6
		# 0.2 * (1 / 60)
		fuel_usage = 0.0033
		if flipped:
			flipped = false
			sprites.set_scale(Vector2(1, 1))
			# flip rotation
			if sprite_rotation > 0:
				sprite_rotation *= -1
	elif left_pressed:
		velocity.x += -6
		# 0.2 * (1 / 60)
		fuel_usage = 0.0033
		if !flipped:
			flipped = true
			sprites.set_scale(Vector2(-1, 1))
			# flip rotation
			if sprite_rotation < 0:
				sprite_rotation *= -1
	
	# vertial movement and thrust sound
	if up_pressed:
		velocity.y -= 8
		# 0.2 * (1 / 60)
		fuel_usage = 0.0033
		
		if engine_thrust_voice == null:
			engine_thrust_voice = EffectsPlayer.get_player("engine_thrust")
			engine_thrust_voice.play()
		
		# adjust thrust pitch
		if engine_thrust_voice_pitch < 1.4:
			engine_thrust_voice_pitch += 0.01
		
		# adjust thrust pitch
		# max thrust pitch 1.4
		# min thrust pitch 0.6
		engine_thrust_voice.set_pitch_scale(engine_thrust_voice_pitch)
		engine_thrust_voice.set_volume_db(GlobalValues.remap(engine_thrust_voice_pitch, 0, 1.4, -16, -12))
	else:
		if engine_thrust_voice != null:
			if engine_thrust_voice_pitch <= 0.6:
				engine_thrust_voice.stop()
				engine_thrust_voice = null
			else:
				# adjust thrust pitch
				engine_thrust_voice_pitch -= 0.01
				engine_thrust_voice.set_pitch_scale(engine_thrust_voice_pitch)
				engine_thrust_voice.set_volume_db(GlobalValues.remap(engine_thrust_voice_pitch, 0, 1.4, -16, -12))
	
	# equipment use
	# check ground equipment
	if Input.is_action_pressed("equipment_0"):
		# reserve fuel tank
		if released:
			if equipment[0] > 0:
				equipment[0] -= 1
				add_fuel(25)
				ui_status.update_value("Used reserve fuel tank")
				EffectsPlayer.play("fuel_glug")
			else:
				EffectsPlayer.play("no_equipment")
			released = false
	elif Input.is_action_pressed("equipment_1"):
		# nano bots
		if released:
			if equipment[1] > 0:
				equipment[1] -= 1
				add_hull(30)
				color_decay = 0.5
				drill_car.set_modulate(Color(0, 1, 0))
				ui_status.update_value("Used nano bots")
				EffectsPlayer.play("nanobots")
			else:
				EffectsPlayer.play("no_equipment")
			released = false
	elif Input.is_action_pressed("equipment_2"):
		# dynamite
		if released:
			if equipment[2] > 0 && on_ground && explosive_cooldown <= 0:
				equipment[2] -= 1
				explosive_cooldown = 0.5
				ui_status.update_value("Used dynamite")
				camera.add_shake(10)
				terrain.explode(position, 1, true)
				EffectsPlayer.play("dynamite")
				emit_signal("used_explosive", false)
			else:
				EffectsPlayer.play("no_equipment")
			released = false
	elif Input.is_action_pressed("equipment_3"):
		# plastic explosives
		if released:
			if equipment[3] > 0 && on_ground && explosive_cooldown <= 0:
				equipment[3] -= 1
				explosive_cooldown = 0.5
				ui_status.update_value("Used plastic explosives")
				camera.add_shake(20)
				terrain.explode(position, 2, true)
				var voice = EffectsPlayer.get_player("dynamite")
				voice.set_volume_db(-8)
				voice.play()
				emit_signal("used_explosive", true)
			else:
				EffectsPlayer.play("no_equipment")
			released = false
	elif Input.is_action_pressed("equipment_4"):
		# quantum teleporter
		if released:
			if equipment[4] > 0 && depth_100 < 7200:
				equipment[4] -= 1
				teleport_state = TeleportStates.QUANTUM_FADING
				teleport_scale = 1
				EffectsPlayer.play("teleport")
				ui_status.update_value("Used quantum teleporter")
			else:
				EffectsPlayer.play("no_equipment")
			released = false
	elif Input.is_action_pressed("equipment_5"):
		# matter transmitter
		if released:
			if equipment[5] > 0 && depth_100 < 7200:
				equipment[5] -= 1
				teleport_state = TeleportStates.MATTER_FADING
				teleport_scale = 1
				EffectsPlayer.play("teleport")
				ui_status.update_value("Used matter transmitter")
			else:
				EffectsPlayer.play("no_equipment")
			released = false
	elif Input.is_action_pressed("inventory"):
		if released:
			inventory_screen.open()
			released = false
	elif Input.is_action_pressed("ui_pause"):
		if released:
			pause_screen.open()
			released = false
	else:
		released = true
	
	# subtract fuel
	subtract_fuel(fuel_usage)
	
	# on ground
	if on_ground:
		# extend horizontal drill
		if (!previous_on_ground || !drill_h.extended) && !drill_v.extended:
			drill_h.extend()
		
		# handle drilling
		if abs(velocity.x) < 40 && abs(velocity.y) < 40:
			if down_pressed && block_below:
				begin_drilling(position, DigDirections.DOWN)
			elif drill_h.extended:
				if left_pressed && block_left:
					begin_drilling(position, DigDirections.LEFT)
				elif right_pressed && block_right:
					begin_drilling(position, DigDirections.RIGHT)
		
		# dampen x if not trying to move
		if !left_pressed && !right_pressed:
			# dampen x on ground
			velocity.x *= 0.95
	else:
		# retract horizontal drill
		if previous_on_ground || drill_h.extended:
			drill_h.retract()
		
		# dampen x in air if not trying to move
		if !left_pressed && !right_pressed:
			velocity.x *= 0.98
		
		# rotate if left or right pressed
		if left_pressed:
			sprite_rotation -= 0.01
		elif right_pressed:
			sprite_rotation += 0.01
	
	# return rotation
	if on_ground || (!left_pressed && !right_pressed):
		if abs(sprite_rotation) > 0.01:
			if sprite_rotation < 0:
				sprite_rotation += 0.01
			else:
				sprite_rotation -= 0.01
		else:
			sprite_rotation = 0
	
	# apply gravity
	velocity.y += 5
	
	# clamp x and y velocities
	velocity.x = clamp(velocity.x, -300, 300)
	velocity.y = clamp(velocity.y, -300, 300)
	
	# clamp rotation
	sprite_rotation = clamp(sprite_rotation, -0.2, 0.2)
	
	# apply rotation
	sprites.rotation = sprite_rotation

func _physics_process(_delta):
	
	# if dead
	if !alive: return
	
	# if drilling
	if drill_state != DrillStates.IDLE: return
	
	# if teleporting
	if teleport_state != TeleportStates.IDLE: return
	
	# store y velocity 
	var y_velocity_previous = velocity.y
	
	# apply movement
	velocity = move_and_slide(velocity, Vector2(0, -1))
	
	# apply invisible walls
	if position.x < bounds_x_min:
		position = Vector2(bounds_x_min, position.y)
		velocity.x = 0
	elif position.x > bounds_x_max:
		position = Vector2(bounds_x_max, position.y)
		velocity.x = 0
	
	var fall_impact = y_velocity_previous - velocity.y
	if fall_impact > 50:
		var voice = EffectsPlayer.get_player("landing")
		voice.set_volume_db(GlobalValues.remap(fall_impact, 50, 350, -8, 0))
		voice.play()
	if fall_impact > 200:
		# round(fall_impact - 200) / 12.5
		remove_hull(round((fall_impact - 200) * 0.1), "gravity")
		EffectsPlayer.play("fall_damage")

