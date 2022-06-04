extends Area2D

var boss_ref = null
var velocity = Vector2(256, rand_range(0, 128) - 64)

func _ready():
	connect("area_entered", self, "area_entered")
	
	boss_ref = weakref(get_node("/root/World/Underworld/Boss"))

func _process(delta):
	position = Vector2(position.x + velocity.x * delta, position.y + velocity.y * delta)
	
	if position.x < 0 || position.x > 960:
		queue_free()

func area_entered(body):
	if body.has_meta("is_player"):
		var boss = boss_ref.get_ref()
		if boss != null:
			boss.damage_player(8)
			queue_free()
