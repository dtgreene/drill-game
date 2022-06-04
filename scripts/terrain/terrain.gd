extends Node2D

const GlobalValues = preload("res://scripts/global_values.gd")
const Explosion = preload("res://scenes/world/Explosion.tscn")
const GasExplosion = preload("res://scenes/world/GasExplosion.tscn")
const BlockScene = preload("res://scenes/terrain/Block.tscn")

const void_count = 1000
const void_shape_count = 1000
const void_shapes = []

var mineral_rates = []

var col_count = GlobalValues.col_count
var row_count = GlobalValues.row_count
var chunk_size = GlobalValues.chunk_size
var chunk_width = chunk_size * 32
var chunk_col_count = GlobalValues.chunk_col_count
var chunk_row_count = GlobalValues.chunk_row_count

var blocks = []
var chunks = []
var chunks_active = []
var last_chunk_col = 0
var last_chunk_row = 0
var terrain_step = 0
var load_data = null

signal terrain_ready()

func _ready():
	# define void shapes
	void_shapes.resize(13)
	# two piece
	void_shapes[0] = [1, 0]
	void_shapes[1] = [0, 1]
	# four piece
	void_shapes[2] = [1, 0, 2, 0, 3, 0]
	void_shapes[3] = [0, 1, 0, 2, 0, 3]
	# corner
	void_shapes[4] = [1, 0, 1, 1]
	void_shapes[5] = [0, 1, -1, 1]
	void_shapes[6] = [-1, 0, -1, -1]
	void_shapes[7] = [0, -1, 1, -1]
	# t-shape
	void_shapes[8] = [1, -1, 1, 0,1, 1]
	void_shapes[9] = [-1, 1, 0, 1, 1, 1]
	void_shapes[10] = [-1, -1, -1, 0, -1, 1]
	void_shapes[11] = [1, -1, 0, -1, 1, -1]
	# square
	void_shapes[12] = [1, 0, 0, 1, 1, 1]
	
	# carbonium
	mineral_rates.append(get_mineral_rates([0, 40, 8, 5]))
	# copperium
	mineral_rates.append(get_mineral_rates([0, 30, 8, 5]))
	# silverium
	mineral_rates.append(get_mineral_rates([0, 20, 8, 5]))
	# goldium
	mineral_rates.append(get_mineral_rates([0, 10, 4, 20, 8, 10]))
	# platinum
	mineral_rates.append(get_mineral_rates([0, 0, 1, 5, 3, 15, 8, 15]))
	# sulfurium
	mineral_rates.append(get_mineral_rates([0, 0, 2, 2, 5, 10, 8, 15]))
	# emerald
	mineral_rates.append(get_mineral_rates([0, 0, 3, 0, 4, 5, 8, 15]))
	# ruby
	mineral_rates.append(get_mineral_rates([0, 0, 4, 0, 5, 2, 8, 10]))
	# diamond
	mineral_rates.append(get_mineral_rates([0, 0, 4, 0, 5, 3, 8, 10]))
	# unobtainium
	mineral_rates.append(get_mineral_rates([0, 0, 6, 0, 7, 3, 8, 5]))
	# boulders
	mineral_rates.append(get_mineral_rates([0, 0, 1, 0, 8, 150]))
	# lava
	mineral_rates.append(get_mineral_rates([0, 0, 3, 0, 8, 150]))
	set_process(false)

func _process(_delta):
	if load_data == null:
		generate_terrain_process()
	else:
		load_terrain_process()

func load_terrain_process():
	if terrain_step == 0:
		# create instances of blocks
		blocks = []
		var used_instance
		var used_load_block
		for col in range(col_count):
			for row in range(row_count):
				used_instance = BlockScene.instance()
				used_instance.position = Vector2(col * 32, row * 32)
				blocks.append(used_instance)
				
				used_load_block = load_data[get_block_index(col, row)]
				
				if row == 0 || !used_load_block.filled:
					used_instance.un_fill()
				elif used_load_block.mineral_texture != null:
					used_instance.set_mineral_texture(used_load_block.mineral_texture)
		
		lock_static_blocks()
	elif terrain_step == 1:
		create_chunks()
	elif terrain_step == 2:
		# fix edges and solidify blocks
		for col in range(col_count):
			for row in range(row_count):
				update_block(col, row)
	
	terrain_step += 1
	
	if terrain_step >= 3:
		emit_signal("terrain_ready")
		get_node("Background").show()
		set_process(false)

func generate_terrain_process():
	if terrain_step == 0:
		# create instances of blocks
		blocks = []
		var used_instance
		for col in range(col_count):
			for row in range(row_count):
				used_instance = BlockScene.instance()
				used_instance.position = Vector2(col * 32, row * 32)
				blocks.append(used_instance)
		
		for col in range(col_count):
			blocks[get_block_index(col, 0)].un_fill()
		
		blocks[get_block_index(col_count - 1, row_count - 1)].un_fill()
		blocks[get_block_index(col_count - 2, row_count - 1)].un_fill()
		blocks[get_block_index(col_count - 3, row_count - 1)].un_fill()
		
		lock_static_blocks()
	elif terrain_step == 1:
		create_chunks()
	elif terrain_step == 2:
		# generate single voids
		for _i in range(void_count):
			var col = floor(rand_range(0, 1) * col_count)
			var row = floor(rand_range(0, 1) * (row_count - 4)) + 2
			
			blocks[get_block_index(col, row)].un_fill()
	elif terrain_step == 3:
		# generate void shapes
		for _i in range(void_shape_count):
			var col = floor(rand_range(0, 1) * col_count)
			var row = floor(rand_range(0, 1) * (row_count - 8)) + 4
			
			blocks[get_block_index(col, row)].un_fill()
			
			var shape_index = floor(rand_range(0, 1) * void_shapes.size())
			var shape = void_shapes[shape_index]
	
			var j = 0
			while j < shape.size():
				var other_col = col + shape[j]
				var other_row = row + shape[j + 1]
				
				j += 2
				
				if(other_col < 0 || other_col >= col_count || other_row < 0 || other_row >= row_count):
					continue
				
				var other_block = blocks[get_block_index(other_col, other_row)]
				other_block.un_fill()
	elif terrain_step == 4:
		# add minerals
		for i in range(12):
			add_mineral(mineral_rates[i], i)
		
		# settler bones
		add_mineral_special(12)
		# ox skull
		add_mineral_special(13)
		# snow globe
		add_mineral_special(14)
	elif terrain_step == 5:
		# fix edges and solidify blocks
		for col in range(col_count):
			for row in range(row_count):
				update_block(col, row)
	
	terrain_step += 1
	
	if terrain_step >= 6:
		emit_signal("terrain_ready")
		get_node("Background").show()
		set_process(false)

func create_chunks():
	# chunk the blocks
	chunks = []
	var used_node
	for col in range(chunk_col_count):
		for row in range(chunk_row_count):
			used_node = Node2D.new()
			used_node.hide()
			
			# add to the terrain
			add_child(used_node)
			
			# add to the chunks array
			chunks.append(used_node)
			
			# add appropriate blocks to chunk
			var start_col = col * chunk_size
			var start_row = row * chunk_size
			
			var block
			for block_col in range(chunk_size):
				for block_row in range(chunk_size):
					block = blocks[get_block_index(start_col + block_col, start_row + block_row)]
					used_node.add_child(block)

func generate_terrain(data = null):
	terrain_step = 0
	load_data = data
	set_process(true)

func earthquake():
	var used_block
	for col in range(col_count):
		for row in range(row_count - 4):
			row = row + 2
			used_block = blocks[get_block_index(col, row)]
			if !used_block.filled && floor(rand_range(0, 10)) == 0:
				used_block.filled = true
				used_block.set_dirt_textures([0])
				
				update_block(col, row)
				
				# update neighbors
				# upper left
				update_block(col - 1, row - 1, true)
				# upper
				update_block(col, row - 1, true)
				# upper right
				update_block(col + 1, row - 1, true)
				# left
				update_block(col - 1, row, true)
				# right
				update_block(col + 1, row, true)
				# lower left
				update_block(col - 1, row + 1, true)
				# lower
				update_block(col, row + 1, true)
				# lower right
				update_block(col + 1, row + 1, true)

func update_chunks(position):
	var col = floor((position.x) / chunk_width)
	var row = floor((position.y) / chunk_width)
	
	if col != last_chunk_col || row != last_chunk_row:
		last_chunk_col = col
		last_chunk_row = row
		
		var chunks_new = []
		
		# activate valid chunks
		# this chunk
		if is_chunk_valid(col, row):
			chunks_new.append(get_chunk_index(col, row))
		# upper left
		if is_chunk_valid(col - 1, row - 1):
			chunks_new.append(get_chunk_index(col - 1, row - 1))
		# upper
		if is_chunk_valid(col, row - 1):
			chunks_new.append(get_chunk_index(col, row - 1))
		# upper right
		if is_chunk_valid(col + 1, row - 1):
			chunks_new.append(get_chunk_index(col + 1, row - 1))
		# left
		if is_chunk_valid(col - 1, row):
			chunks_new.append(get_chunk_index(col - 1, row))
		# right
		if is_chunk_valid(col + 1, row):
			chunks_new.append(get_chunk_index(col + 1, row))
		# lower left
		if is_chunk_valid(col - 1, row + 1):
			chunks_new.append(get_chunk_index(col - 1, row + 1))
		# lower
		if is_chunk_valid(col, row + 1):
			chunks_new.append(get_chunk_index(col, row + 1))
		# lower right
		if is_chunk_valid(col + 1, row + 1):
			chunks_new.append(get_chunk_index(col + 1, row + 1))
		
		# activate chunks
		for chunk_index in chunks_new:
			chunks[chunk_index].show()
		
		# de-activate previously active chunks
		for chunk_index in chunks_active:
			# if chunk is not part of the just activated chunks
			if !chunks_new.has(chunk_index):
				# deactivate chunk
				chunks[chunk_index].hide()
		
		chunks_active = chunks_new

func lock_static_blocks():
	blocks[get_block_index(3, 1)].drillable = false
	blocks[get_block_index(4, 1)].drillable = false
	blocks[get_block_index(5, 1)].drillable = false
	
	blocks[get_block_index(13, 1)].drillable = false
	blocks[get_block_index(14, 1)].drillable = false
	blocks[get_block_index(15, 1)].drillable = false
	blocks[get_block_index(16, 1)].drillable = false
	
	blocks[get_block_index(21, 1)].drillable = false
	blocks[get_block_index(22, 1)].drillable = false
	blocks[get_block_index(23, 1)].drillable = false
	
	blocks[get_block_index(25, 1)].drillable = false
	blocks[get_block_index(26, 1)].drillable = false
	blocks[get_block_index(27, 1)].drillable = false
	
	var used_block
	for i in range(col_count - 3):
		used_block = blocks[get_block_index(i, row_count - 1)]
		used_block.drillable = false
		used_block.solidify()

func explode(pos, half_width_height, unfill, gas = false): 
	# pos / 32
	var terrain_col = round(pos.x * 0.03125)
	var terrain_row = round(pos.y * 0.03125)
	var start_col = terrain_col - half_width_height
	var start_row = terrain_row - half_width_height
	var col = start_col
	var row = start_row
	var stop_col = terrain_col + half_width_height
	var stop_row = terrain_row + half_width_height
	var used_instance
	var explosion_scene = Explosion
	
	if gas:
		explosion_scene = GasExplosion
	
	var used_block
	while col <= stop_col:
		while row <= stop_row:
			# add explosion
			used_instance = explosion_scene.instance()
			used_instance.position = Vector2(col * 32 + rand_range(0, 8) - 4, row * 32 + rand_range(0, 8) - 4)
			used_instance.delay = rand_range(0, 0.2)
			add_child(used_instance)
			
			if unfill:
				if col >= 0 && col < col_count && row >= 0 && row < row_count:
					used_block = blocks[get_block_index(col, row)]
					if used_block.drillable || used_block.mineral_texture == 10:
						used_block.un_fill()
			
			row += 1
		col += 1
		row = start_row
	
	if unfill:
		# fix affected block edges
		col = start_col
		row = start_row
		while col <= stop_col:
			while row <= stop_row:
				if col >= 0 && col < col_count && row >= 0 && row < row_count:
					fix_block_edges(col, row, blocks[get_block_index(col, row)])
				row += 1
			col += 1
			row = start_row
		
		# fix top neighbors
		col = start_col - 1
		row = start_row - 1
		while col <= stop_col + 1:
			update_block(col, row)
			col += 1
		
		# fix left neighbors
		col = start_col - 1
		row = start_row
		while row <= stop_row:
			update_block(col, row)
			row += 1
		
		# fix right neighbors
		col = stop_col + 1
		row = start_row
		while row <= stop_row:
			update_block(col, row)
			row += 1
		
		# fix bottom neighbors
		col = start_col - 1
		row = stop_row + 1
		while col <= stop_col + 1:
			update_block(col, row)
			col += 1

func dig(col, row):
	var block = blocks[get_block_index(col, row)]
	
	var mineral = block.mineral_texture
	
	# unfill 
	block.un_fill()
	# fix edges
	fix_block_edges(col, row, block)
	
	# update neighbors
	# upper left
	update_block(col - 1, row - 1, true)
	# upper
	update_block(col, row - 1)
	# upper right
	update_block(col + 1, row - 1, true)
	# left
	update_block(col - 1, row)
	# right
	update_block(col + 1, row)
	# lower left
	update_block(col - 1, row + 1, true)
	# lower
	update_block(col, row + 1)
	# lower right
	update_block(col + 1, row + 1, true)
	
	return mineral

func update_block(col, row, skip_solidify = false):
	if !is_block_valid(col, row): return
	
	var block = blocks[get_block_index(col, row)]
	
	# either try to solidify the block or fix edges
	if !skip_solidify && block.filled && !block.solid:
		if (
			is_block_un_filled(col, row - 1) || 
			is_block_un_filled(col - 1, row) || 
			is_block_un_filled(col + 1, row) || 
			is_block_un_filled(col, row + 1)
		):
			
			block.solidify()
	else:
		fix_block_edges(col, row, block)

func get_chunk_group_name(col, row):
	return "chunk_" + str(col) + str(row)

func get_block_chunk_index(col, row):
	return (floor(col / chunk_size) * chunk_row_count) + floor(row / chunk_size)

func get_chunk_index(col, row):
	return (col * chunk_row_count) + row

func get_block_index(col, row):
	return (col * row_count) + row

func is_chunk_valid(col, row):
	return col >= 0 && col < chunk_col_count && row >= 0 && row < chunk_row_count

func is_block_valid(col, row):
	return col >= 0 && col < col_count && row >= 0 && row < row_count

func is_block_filled(col, row):
	if col >= 0 && col < col_count && row >= 0 && row < row_count:
		return blocks[get_block_index(col, row)].filled
	return false

func is_block_dirt(col, row):
	if col >= 0 && col < col_count && row >= 0 && row < row_count:
		var block = blocks[get_block_index(col, row)]
		return block.filled && block.mineral_texture == null
	return false

func is_block_drillable(col, row):
	if is_block_valid(col, row):
		var block = blocks[get_block_index(col, row)]
		return block.filled && block.drillable
	return false
	
func is_block_un_filled(col, row):
	return is_block_valid(col, row) && !blocks[get_block_index(col, row)].filled

func add_mineral(rates, mineral):
	var used_tries = 0
	for i in range(rates.size()):
		var count = rates[i]
		var startRow = i * 64
		
		for _j in range(count):
			var col = floor(rand_range(0, col_count))
			var row = floor(rand_range(0, 64)) + startRow
			
			used_tries = 0
			
			while (!is_block_dirt(col, row) || row == 1 || row == row_count - 1) && used_tries < 5:
				row = floor(rand_range(0, 64)) + startRow
				used_tries += 1
			
			if used_tries < 5:
				blocks[get_block_index(col, row)].set_mineral_texture(mineral)

func add_mineral_special(mineral):
	var count = floor(rand_range(2, 5))
	for _j in range(count):
		var startRow = floor(rand_range(2, 8)) * 64
		var col = floor(rand_range(0, col_count))
		var row = floor(rand_range(0, 64)) + startRow

		while !is_block_dirt(col, row) || row == 1 || row == row_count - 1:
			row = floor(rand_range(0, 64) + startRow)
		
		blocks[get_block_index(col, row)].set_mineral_texture(mineral)

func fix_block_edges(col, row, block):
	if block.filled: return
	
	var upper_left = is_block_filled(col - 1, row - 1)
	var upper = is_block_filled(col, row - 1)
	var upper_right = is_block_filled(col + 1, row - 1)
	var left = is_block_filled(col - 1, row)
	var right = is_block_filled(col + 1, row)
	var lower_left = is_block_filled(col - 1, row + 1)
	var lower = is_block_filled(col, row + 1)
	var lower_right = is_block_filled(col + 1, row + 1)

	# four sides
	if upper && right && left && lower:
		block.set_dirt_textures([1])
	# three sides
	elif !upper && right && left && lower:
		block.set_dirt_textures([2])
	elif upper && right && left && !lower:
		block.set_dirt_textures([3])
	elif upper && !right && left && lower:
		block.set_dirt_textures([4])
	elif upper && right && !left && lower:
		block.set_dirt_textures([5])
	# two sides
	elif upper && !right && !left && lower:
		block.set_dirt_textures([6, 7])
	elif !upper && right && left && !lower:
		block.set_dirt_textures([8, 9])
	# other
	else:
		var sprites = []
		if upper && !right && !left && !lower:
			sprites.append(7)
			if lower_left:
				sprites.append(17)
			if lower_right:
				sprites.append(14)
		elif !upper && !right && !left && lower:
			sprites.append(6)
			if upper_left:
				sprites.append(16)
			if upper_right:
				sprites.append(15)
		elif !upper && right && !left && !lower:
			sprites.append(9)
			if upper_left:
				sprites.append(16)
			if lower_left:
				sprites.append(17)
		elif !upper && !right && left && !lower:
			sprites.append(8)
			if upper_right:
				sprites.append(15)
			if lower_right:
				sprites.append(14)
		elif !upper && right && !left && lower:
			sprites.append(10)
			if upper_left:
				sprites.append(16)
		elif upper && !right && left && !lower:
			sprites.append(11)
			if lower_right:
				sprites.append(14)
		elif upper && right && !left && !lower:
			sprites.append(12)
			if lower_left:
				sprites.append(17)
		elif !upper && !right && left && lower:
			sprites.append(13)
			if upper_right:
				sprites.append(15)
		
		# this is our standalone corners check if we haven't added any sprites yet
		if sprites.size() == 0:
			if lower_left:
				sprites.append(17)
			if lower_right:
				sprites.append(14)
			if upper_left:
				sprites.append(16)
			if upper_right:
				sprites.append(15)
		
		block.set_dirt_textures(sprites)

func get_mineral_rates(points):
	var result = []
	for i in range(9):
		var value = -1
		var j = 0
		# if we find a value for this x, add that without interpolating
		while j < points.size():
			if points[j] == i:
				value = points[j + 1]
				break
			j += 2
		
		if value != -1:
			result.append(round(value))
			continue
		
		# find where this value lies between the points
		var start_index = 0
		j = 0
		while j < points.size():
			if points[j] < i:
				start_index = j
			j += 2
		
		var stop_index = points.size() - 2
		j = stop_index
		while j >= 0:
			if points[j] > i:
				stop_index = j
			j -= 2
		
		value = GlobalValues.remap(
			i, 
			points[start_index], 
			points[stop_index], 
			points[start_index + 1], 
			points[stop_index + 1]
		)
		result.append(round(value))
	
	return result
