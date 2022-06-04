extends Node2D

const GlobalValues = preload("res://scripts/global_values.gd")
const DrillTexture = preload("res://assets/images/drill.png")

const texture_size = Vector2(32, 32)
const pos_rect = Rect2(Vector2(-16, -16), Vector2(32, 32))

signal extended()
signal retracted()

var frame = 0
var frame_tick = 0
var frame_increment = 0
var playing = false
var extended = false

func _draw():
	draw_texture_rect_region(DrillTexture, pos_rect, Rect2(Rect2(Vector2(frame * 32, 0), texture_size)))

func extend():
	start_animation(1)

func retract():
	start_animation(-1)

func start_animation(increment):
	if frame_increment == increment: return
	
	# clamp the frame
	frame = clamp(frame, 0, 6)
	playing = true
	frame_increment = increment
	
	set_process(true)

func _process(delta):
	if playing:
		frame_tick += 60 * delta
		if frame_tick >= 2:
			frame += frame_increment
			frame_tick = 0
			
			if frame == 7 || frame == -1:
				if frame_increment == 1:
					emit_signal("extended")
					extended = true
				else:
					emit_signal("retracted")
					extended = false
				playing = false
				frame_increment = 0
				set_process(false)
			else:
				update()
