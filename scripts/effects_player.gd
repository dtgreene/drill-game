extends Node

const effects_path = "res://assets/effects"

var effect_players = {}

func _ready() -> void:
	# manually set pause mode
	pause_mode = Node.PAUSE_MODE_PROCESS
	
	# https://godotengine.org/qa/59637/cannot-traverse-asset-directory-in-android?show=59637#q59637
	
	# load effects
	var used_player
	var dir = Directory.new()
	
	# open our effects path
	if dir.open(effects_path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		# read each file
		while file_name != "":
			# skip over any directories
			if !dir.current_is_dir():
				
				file_name = file_name.replace(".import", "")
				
				if(file_name.ends_with(".wav")):
					var effect_name = file_name.split(".wav", false)[0]
					var effect_stream = load("res://assets/effects/%s" % file_name) as AudioStreamSample
					
					# create an audio stream player for each sound
					used_player = AudioStreamPlayer.new()
					used_player.stream = effect_stream
					used_player.set_bus("Effects")
					
					# add the player to scene tree
					add_child(used_player)
					# store the player keyed by the name
					effect_players[effect_name] = used_player
			# read the next file
			file_name = dir.get_next()
	else:
		print("Failed to load sound effects.")

func play(name: String) -> void:
	effect_players[name].play()

func get_player(name: String) -> AudioStreamPlayer:
	return effect_players[name]

func stop_all() -> void:
	var keys = effect_players.keys()
	for key in keys:
		effect_players[key].stop()
