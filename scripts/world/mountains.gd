extends Node2D

const NoiseScript = preload("res://scripts/noise.gd")

var noise = NoiseScript.SoftNoise.new()
var mountains_far = LargeTexture.new()
var mounts_near = LargeTexture.new()

func _ready():
	generate_mountain(mountains_far, 128, 0.005, Color(0.39608, 0.44706, 0.52157))
	generate_mountain(mounts_near, 64, 0.01, Color(0.30588, 0.36078, 0.44706))

func _draw():
	draw_texture(mountains_far, Vector2(-160, -128))
	draw_texture(mounts_near, Vector2(-160, -64))

func generate_mountain(large_texture, height, frequency_scale, color):
	var i = 0
	var y = rand_range(0, 100)
	var half_height = height * 0.5
	while i < 4:
		var image = Image.new()
		# create new image
		image.create(320, height, true, 5)
		# lock image for pixel editing
		image.lock()
		
		var used_y = 0
		var offset = i * 320
		for x in range(320):
			# get noise value
			used_y = floor(noise.openSimplex2D((x + offset) * frequency_scale, y) * half_height + half_height)
			# fill in pixels 
			while used_y < height:
				image.set_pixel(x, used_y, color)
				used_y += 1
		
		# unlock image after pixel editing
		image.unlock()
		
		var texture = ImageTexture.new()
		texture.create_from_image(image, 0)
		
		# add the texture piece
		large_texture.add_piece(Vector2(offset, 0), texture)
		
		i += 1
