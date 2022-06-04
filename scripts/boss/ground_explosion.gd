extends Area2D

onready var sprite = get_node("Sprite")

var boss_ref = null

func _ready():
	sprite.connect("animation_finished", self, "animation_finished")
	connect("area_entered", self, "area_entered")
	
	sprite.play("default")
	
	boss_ref = weakref(get_node("/root/World/Underworld/Boss"))

func animation_finished():
	queue_free()

func area_entered(body):
	if body.has_meta("is_player"):
		var boss = boss_ref.get_ref()
		if boss != null:
			boss.damage_player(16)
