const col_count = 30
const row_count = 576
const chunk_size = 6
const chunk_col_count = col_count / chunk_size
const chunk_row_count = row_count / chunk_size

enum DigDirections {
	NONE,
	LEFT,
	DOWN,
	RIGHT
}

enum ShakeDirections {
	NONE,
	HORIZONTAL,
	VERTICAL
}

const mineral_names = [
	"Carbonium",
	"Copperium",
	"Silverium",
	"Goldium",
	"Platinum",
	"Sulfurium",
	"Emerald",
	"Ruby",
	"Diamond",
	"Unobtanium"
]


const ui_primary = Color(0.15294, 0.66667, 0.82745)
const ui_secondary = Color(0.41176, 0.38039, 0.40392)

static func get_save_slots():
	var save_slots = []
	var i = 0
	while i < 3:
		var save_file = File.new()
		var file_name = "user://save" + str(i) + ".save"
		var save_slot_time = "None"
		if save_file.file_exists(file_name):
			save_file.open(file_name, File.READ)
			var parse_result = JSON.parse(save_file.get_as_text())
			if parse_result.error == OK:
				
				var save_data = parse_result.get_result()
				if !save_data.has("timestamp"):
					save_slots.append("Unknown")
					continue
				
				var datetime = OS.get_datetime_from_unix_time(save_data.timestamp)
				save_slot_time = str(datetime.month) + "/" + str(datetime.day)
			else:
				print("Error parsing save; path: %s" % file_name)
			save_file.close()
			
		save_slots.append(save_slot_time)
		i += 1
	return save_slots

static func load_save_slot(slot):
	var save_file = File.new()
	var name = "user://save" + str(slot) + ".save"
	if save_file.file_exists(name):
		save_file.open(name, File.READ)
		var parse_result = JSON.parse(save_file.get_as_text())
		if parse_result.error == OK:
			return parse_result.get_result()
		
		save_file.close()
	return null

static func remap(n, start1, stop1, start2, stop2):
	return (float(n - start1) / float(stop1 - start1)) * float(stop2 - start2) + start2
