extends Camera2D

const shake_tick = (1 / float(60))

var original_offset = Vector2()
var tick = 0
var shake_amount = 0

func _ready():
	original_offset = get_offset()
	set_process(false)

func _process(delta):
	tick += delta
	if tick > shake_tick:
		tick = 0
		set_offset(
			Vector2(
				original_offset.x + rand_range(0, 4) - 2, 
				original_offset.y + rand_range(0, 4) - 2
			)
		)
		shake_amount -= 1
		if shake_amount <= 0:
			set_process(false)
			set_offset(original_offset)

func add_shake(amount):
	set_process(true)
	shake_amount = amount
