extends Node2D

const SunTexture = preload("res://assets/images/sun.png")
const MoonTexture = preload("res://assets/images/moon.png")

const color_0 = Color(0.26275, 0.73725, 1.00000)
const color_1 = Color(0.02745, 0.02745, 0.15294)

var sin_value = PI * 1.5
var cycles = 0

func _ready():
	get_node("UpdateTimer").connect("timeout", self, "sun_update")

func _draw():
	draw_texture(SunTexture, Vector2(cos(sin_value) * 300 - 16, sin(sin_value) * 300 - 16))
	draw_texture(MoonTexture, Vector2(-cos(sin_value) * 300 - 16, -sin(sin_value) * 300 - 16))

func sun_update():
	VisualServer.set_default_clear_color(color_0.linear_interpolate(color_1, sin(sin_value) * 0.5 + 0.5))
	sin_value += 0.005
	if sin_value >= 10.995574:
		sin_value = PI * 1.5
		cycles += 1
	update()
