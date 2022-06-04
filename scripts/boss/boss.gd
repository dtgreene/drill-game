extends Area2D

const GlobalValues = preload("res://scripts/global_values.gd")
const GroundSlam = preload("res://scenes/boss/GroundSlam.tscn")
const BulletSpawner = preload("res://scenes/boss/BulletSpawner.tscn")

onready var sprite = get_node("Sprite")
onready var underworld = get_node("/root/World/Underworld")
onready var player = get_node("/root/World/Player")
onready var collision_shape = get_node("CollisionShape2D")
onready var boss_health = get_node("UI/Health")
onready var ui_layer = get_node("UI")

enum States {
	EMERGE,
	DIE,
	BIG_REVEAL,
	WALK,
	ATTACK_BLAST,
	ATTACK_SLAM
}

var player_present = false
var state = States.EMERGE
var last_step_frame = 0
var touch_damage_cooldown = 0
var state_start_delay = 0
var state_stop_delay = 0
var state_stopping = false
var walk_stop_delay = 0
var flipped = false
var health = 800
var color_decay = 0
var y_base = (GlobalValues.row_count + 4) * 32 - 12

signal died()

func _ready():
	connect("area_entered", self, "area_entered")
	connect("area_exited", self, "area_exited")
	
	sprite.connect("animation_finished", self, "animation_finished")
	player.connect("used_explosive", self, "player_used_explosive")
	
	position = Vector2(15 * 32, y_base + 128)
	change_state(States.EMERGE)

func _process(delta):
	
	if player_present && health > 0:
		if touch_damage_cooldown > 0:
			touch_damage_cooldown -= delta
		
		if touch_damage_cooldown <= 0:
			damage_player(8)
			touch_damage_cooldown = 0.5
	
	if color_decay > 0:
		color_decay -= delta
		if color_decay <= 0:
			sprite.set_modulate(Color(1, 1, 1))
	
	if state == States.EMERGE:
		if position.y > y_base:
			position = Vector2(position.x, position.y - delta * 32)
		else:
			position = Vector2(position.x, y_base)
			change_state(States.WALK)
	elif state == States.DIE:
		if state_stop_delay > 0:
			state_stop_delay -= delta
		else:
			change_state(States.BIG_REVEAL)
	elif state == States.WALK:
		var player_position = player.position
		flip_sprite(position, player_position, 16)
		
		var walk_sign = -1 if !flipped else 1
		position = Vector2(position.x + delta * 96 * walk_sign, position.y)
		
		# play stomp sound
		var current_frame = sprite.get_frame()
		if (current_frame == 3 || current_frame == 11) && current_frame != last_step_frame:
			last_step_frame = current_frame
			var voice = EffectsPlayer.get_player("boss_stomp")
			voice.set_pitch_scale(1 + rand_range(0, 0.4) - 0.2)
			EffectsPlayer.play("boss_stomp")
		
		if walk_stop_delay > 0:
			walk_stop_delay -= delta
		else:
			# check for attack
			if abs(position.x - player_position.x) < 96:
				# slam attack if player is towards the ground
				change_state(States.ATTACK_SLAM)
			else:
				# blast move if player is above
				change_state(States.ATTACK_BLAST)
	elif state == States.ATTACK_BLAST:
		if !state_stopping:
			if state_start_delay > 0:
				state_start_delay -= delta
			elif !sprite.is_playing():
				sprite.play("attack_blast")
		else:
			if state_stop_delay > 0:
				state_stop_delay -= delta
			else:
				if health > 0:
					change_state(States.WALK)
				else:
					change_state(States.DIE)
	elif state == States.ATTACK_SLAM:
		if !state_stopping:
			if state_start_delay > 0:
				state_start_delay -= delta
			elif !sprite.is_playing():
				sprite.play("attack_slam")
		else:
			if state_stop_delay > 0:
				state_stop_delay -= delta
			else:
				if health > 0:
					change_state(States.WALK)
				else:
					change_state(States.DIE)

func change_state(value):
	state = value
	
	state_stopping = false
	state_start_delay = 0
	state_stop_delay = 0
	
	walk_stop_delay = 0
	
	sprite.stop()
	sprite.set_frame(0)
	
	if value == States.EMERGE:
		collision_shape.position = Vector2(0, 4)
		collision_shape.get_shape().set_extents(Vector2(24, 56))
		
		sprite.set_animation("emerge")
		player.shake_camera(180)
	elif value == States.DIE:
		collision_shape.position = Vector2(0, 4)
		collision_shape.get_shape().set_extents(Vector2(24, 56))
		
		sprite.set_animation("emerge")
		player.shake_camera(180)
		state_start_delay = 0
		state_stop_delay = 3
		state_stopping = true
	elif value == States.BIG_REVEAL:
		collision_shape.position = Vector2(0, 4)
		collision_shape.get_shape().set_extents(Vector2(24, 56))
		
		sprite.set_animation("big_reveal")
		set_process(false)
		ui_layer.queue_free()
		emit_signal("died")
	elif value == States.WALK:
		collision_shape.position = Vector2(0, 4)
		collision_shape.get_shape().set_extents(Vector2(24, 56))
		
		sprite.play("walk")
		walk_stop_delay = floor(rand_range(1, 5))
	elif value == States.ATTACK_BLAST:
		var player_position = player.position
		flip_sprite(position, player_position, 1)
		
		collision_shape.position = Vector2(20 if flipped else -20, 8)
		collision_shape.get_shape().set_extents(Vector2(32, 50))
		
		sprite.set_animation("attack_blast")
		EffectsPlayer.play("boss_charge_up")
		state_start_delay = 0.5
		state_stop_delay = 4
	elif value == States.ATTACK_SLAM:
		collision_shape.position = Vector2(0, 32)
		collision_shape.get_shape().set_extents(Vector2(24, 28))
		
		sprite.set_animation("attack_slam")
		EffectsPlayer.play("ho_ho_ho")
		state_start_delay = 1
		state_stop_delay = 3

func remove_health(amount):
	if health > 0:
		health = clamp(health - amount, 0, 800)
		sprite.set_modulate(Color(1, 0, 0))
		color_decay = 0.5
		boss_health.update()
		
		if health <= 0 && state == States.WALK:
			change_state(States.DIE)
	elif state == States.BIG_REVEAL:
		queue_free()

func player_used_explosive(is_plastic):
	if state == States.EMERGE: return
	
	var player_position = player.position
	var x_diff = abs(position.x - player_position.x)
	
	if state == States.ATTACK_BLAST:
		position.x += 20 if flipped else -20
	
	if is_plastic:
		# 64 + 16 + 64
		if x_diff < 144:
			# ((n-start1)/(stop1-start1))*(stop2-start2)+start2
			remove_health(float(x_diff / 144.0) * -25 + 50)
	else:
		# 32 + 16 + 64
		if x_diff < 112:
			# ((n-start1)/(stop1-start1))*(stop2-start2)+start2
			remove_health(float(x_diff / 112.0) * -12.5 + 25)

func play_effect(effect):
	EffectsPlayer.play(effect)

func damage_player(amount):
	if player.alive:
		player.remove_hull(amount, "Santa")
		EffectsPlayer.play("blunt_damage")

func flip_sprite(position, player_position, min_distance):
	var x_diff = position.x - player_position.x
	if abs(x_diff) > min_distance:
		if x_diff < 0:
			if !flipped:
				flipped = true
				sprite.set_flip_h(true)
		else:
			if flipped:
				flipped = false
				sprite.set_flip_h(false)

func animation_finished():
	if state == States.ATTACK_BLAST:
		var spawner = BulletSpawner.instance()
		var x_offset = -56 if !flipped else 56
		spawner.position = Vector2(position.x + x_offset, position.y)
		spawner.flipped = flipped
		underworld.add_child(spawner)
		state_stopping = true
	elif state == States.ATTACK_SLAM:
		var player_position = player.position
		var x_diff = position.x - player_position.x
		
		var slam = GroundSlam.instance()
		slam.position = Vector2(position.x, position.y + 44)
		underworld.add_child(slam)
		
		if abs(x_diff) < 8:
			player.remove_hull(32, "Santa")
		
		player.shake_camera(10)
		EffectsPlayer.play("dynamite")
		state_stopping = true

func area_entered(body):
	if body.has_meta("is_player") && health > 0:
		player_present = true
		touch_damage_cooldown = 0.5
		
		damage_player(8)

func area_exited(body):
	if body.has_meta("is_player"):
		player_present = false
