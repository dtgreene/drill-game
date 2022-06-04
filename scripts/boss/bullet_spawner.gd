extends Node2D

const BulletScene = preload("res://scenes/boss/Bullet.tscn")

onready var underworld = get_node("/root/World/Underworld")

var boss_ref = null
var flipped = false
var bullets_created = 0
var time_elapsed = 0

func _ready():	
	boss_ref = weakref(get_node("/root/World/Underworld/Boss"))

func _process(delta):
	time_elapsed += delta
	if time_elapsed > 0.2:
		if bullets_created < 15:
			time_elapsed = 0
			bullets_created += 1
			
			var bullet = BulletScene.instance()
			bullet.velocity.x *= 1 if flipped else -1
			bullet.position = position
			underworld.add_child(bullet)
			
			var boss = boss_ref.get_ref()
			if boss != null:
				boss.play_effect("boss_shoot")
		else:
			queue_free()
		
