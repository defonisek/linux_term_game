# menu.gd (on your menu scene root)
extends Control

signal level_selected(level: int)

@onready var buttons = [
	$Levels/Level1,
	$Levels/Level2,
	$Levels/Level3,
	$Levels/Level4,
	$Levels/Level5
]

func _ready():
	update_buttons()
	for i in range(5):
		var level = i + 1
		buttons[i].pressed.connect(_on_level_pressed.bind(level))

func update_buttons():
	for i in range(5):
		var level = i + 1
		var unlocked = GameState.is_level_unlocked(level)
		buttons[i].disabled = not unlocked
		if unlocked:
			buttons[i].modulate = Color.WHITE
		else:
			buttons[i].modulate = Color(0.5, 0.5, 0.5, 1)

func _on_level_pressed(level: int):
	print("Нажата кнопка уровня ", level)
	level_selected.emit(level)
