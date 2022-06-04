extends Label

var decay = 0
var decay_length = 5
var suffix = ""
var prefix = ""

func _ready():
	hide()
	set_process(false)

func update_value(value, color = null):
	if color != null:
		add_color_override("font_color", color)

	set_text(prefix + str(value) + suffix)
	show()
	set_process(true)
	decay = decay_length

func _process(delta):
	if decay > 0:
		decay -= delta
		if decay < 0.01:
			hide()
			set_process(false)
