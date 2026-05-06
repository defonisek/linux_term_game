class_name TerminalInput
extends Object

var _terminal: Terminal

func initialize(terminal: Terminal) -> void:
	_terminal = terminal

func handle_key_event(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		_terminal.caret.reset_timer()
		match event.keycode:
			Key.KEY_ENTER, Key.KEY_KP_ENTER:
				_terminal.run_command()
			Key.KEY_LEFT:
				_key_left()
			Key.KEY_RIGHT:
				_key_right()
			Key.KEY_BACKSPACE:
				_key_backspace()
			Key.KEY_DELETE:
				_key_delete()
			Key.KEY_TAB:
				_terminal.invoke_autocompletion()
			_:
				_insert_printable_character(event)


func _insert_printable_character(event: InputEvent) -> void:
	if event.unicode != 0:
		_terminal.insert_char_at_caret(char(event.unicode))


func _key_backspace() -> void:
	if _terminal.caret_logical_index_x > _terminal.primary_prompt_text.length():
		_terminal.get_active_logical_line().delete_char(_terminal.caret_logical_index_x - 1)
		_terminal.caret_logical_index_x -= 1
		_terminal.recreate_display_lines_since_last_input_only()


func _key_delete() -> void:
	if _terminal.caret_logical_index_x < _terminal.get_active_logical_line().length():
		_terminal.get_active_logical_line().delete_char(_terminal.caret_logical_index_x)
		_terminal.recreate_display_lines_since_last_input_only()


func _key_left() -> void:
	if _terminal.caret_logical_index_x > _terminal.primary_prompt_text.length():
		_terminal.caret_logical_index_x -= 1
		_terminal.update_caret_position()


func _key_right() -> void:
	if _terminal.caret_logical_index_x < _terminal.get_active_logical_line().length():
		_terminal.caret_logical_index_x += 1
		_terminal.update_caret_position()
