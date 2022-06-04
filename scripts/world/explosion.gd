extends AnimatedSprite

var delay = 0
onready var start_timer = get_node("Timer")

func _ready():
	connect("animation_finished", self, "animation_finished")
	if delay > 0:
		start_timer.set_wait_time(delay)
		start_timer.connect("timeout", self, "play_animation")
		start_timer.start()
		hide()
	else:
		play("default")

func play_animation():
	show()
	play("default")

func animation_finished():
	queue_free()
