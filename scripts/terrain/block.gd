extends Node2D

const ColliderScene = preload("res://scenes/terrain/BlockCollider.tscn")
const TerrainTexture = preload("res://assets/images/terrain.png")
const MineralTexture = preload("res://assets/images/minerals.png")

const texture_size = Vector2(32, 32)
const pos_rect = Rect2(Vector2(-16, -16), Vector2(32, 32))

var solid = false
var filled = true
var dirt_textures = null
var mineral_texture = null
var drillable = true

func _draw():
	if filled:
		if mineral_texture == null:
			draw_texture_rect_region(TerrainTexture, pos_rect, Rect2(Vector2(), texture_size))
		else:
			draw_texture_rect_region(MineralTexture, pos_rect, Rect2(Vector2(mineral_texture * 32, 0), texture_size))
	else:
		if dirt_textures != null:
			for index in dirt_textures:
				draw_texture_rect_region(TerrainTexture, pos_rect, Rect2(Vector2(index * 32, 0), texture_size))

func un_fill():
	if !filled: return
	
	filled = false
	solid = false
	dirt_textures = null
	mineral_texture = null
	# reset drillable
	drillable = true
	
	for child in get_children():
		child.queue_free()
	
	update()

func solidify():
	if solid: return
	
	solid = true
	var collider = ColliderScene.instance()
	collider.set_meta("is_terrain", true)
	add_child(collider)

func set_mineral_texture(texture):
	if texture == 10:
		drillable = false
		
	mineral_texture = texture
	update()

func set_dirt_textures(textures):
	dirt_textures = textures
	update()
