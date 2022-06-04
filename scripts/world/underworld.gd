extends Node2D

const GlobalValues = preload("res://scripts/global_values.gd")
const UnderworldBlockScene = preload("res://scenes/terrain/UnderworldBlock.tscn")
const BlockScene = preload("res://scenes/terrain/Block.tscn")

func _ready():
	hide()
	
	# add stalactites
	var used_instance
	var used_y = 0
	
	used_y = GlobalValues.row_count * 32
	for col in range(GlobalValues.col_count - 3):
		used_instance = UnderworldBlockScene.instance()
		used_instance.position = Vector2(col * 32, used_y)
		used_instance.set_frame(floor(rand_range(0, 3)))
		add_child(used_instance)
	
	# add corner piece
	used_instance = BlockScene.instance()
	used_instance.position = Vector2((GlobalValues.col_count - 3) * 32, used_y)
	used_instance.un_fill()
	used_instance.set_dirt_textures([16])
	add_child(used_instance)
	
	# add ground
	used_y = (GlobalValues.row_count + 6) * 32
	for col in range(GlobalValues.col_count):
		for row in range(4):
			used_instance = BlockScene.instance()
			used_instance.position = Vector2(col * 32, used_y + row * 32)
			used_instance.drillable = false
			
			if row == 0:
				used_instance.solidify()
				
			add_child(used_instance)
	
	# add ground edges
	used_y = (GlobalValues.row_count + 5) * 32
	for col in range(GlobalValues.col_count):
		used_instance = BlockScene.instance()
		used_instance.position = Vector2(col * 32, used_y)
		used_instance.un_fill()
		used_instance.set_dirt_textures([6])
		add_child(used_instance)
