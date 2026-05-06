extends Node

const SAVE_PATH := "user://progress.json"

var highest_unlocked_level: int = 1
var selected_level: int = 1

func _ready() -> void:
	load_progress()

func is_level_unlocked(level_index: int) -> bool:
	return level_index <= highest_unlocked_level

func unlock_level(level_index: int) -> void:
	if level_index > highest_unlocked_level:
		highest_unlocked_level = level_index
		save_progress()

func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		highest_unlocked_level = 1
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		highest_unlocked_level = 1
		return

	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) == TYPE_DICTIONARY and data.has("highest_unlocked_level"):
		highest_unlocked_level = int(data["highest_unlocked_level"])
	else:
		highest_unlocked_level = 1

func save_progress() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return

	file.store_string(JSON.stringify({
		"highest_unlocked_level": highest_unlocked_level
	}))
