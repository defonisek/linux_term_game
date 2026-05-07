extends Control
signal chat_opened
@onready var terminal_screen: Control = $VBoxContainer/Terminal
@onready var other_screen: Control = $MailMenu
@onready var terminal: Terminal = $VBoxContainer/Terminal
@onready var menu_layer: Control = $MainMenu

@onready var transition_layer: CanvasLayer = $TransitionLayer
@onready var black_flash: ColorRect = $TransitionLayer/Overlay/BlackFlash
@onready var static_rect: ColorRect = $TransitionLayer/Overlay/StaticRect
@onready var static_material: ShaderMaterial = static_rect.material as ShaderMaterial

var _transitioning: bool = false

var levels_data = {
	1: [
		{
			"type": "send_mail",
			"messages": [
				"привет.",
				"собственно добро пожаловать. это терминал.",
                "Твоё первое задание: изучи команду echo. Введи 'echo' в терминале."
			]
		},
		{ "type": "wait_for_chat_read" },
		{
			"type": "wait_command",
			"command": "echo",
			"on_fail": "minigame",
			"minigame_id": "echo_tutorial"
		},
		{
			"type": "send_mail",
			"messages": [
				"echo выводит то, что ты пишешь после неё.",
				"Теперь попробуй вывести текст, например: 'echo привет!'"
			]
		},
		{ "type": "wait_for_chat_read" },
		{
			"type": "wait_command",
			"command": "echo",
			"args": ["привет!"],
			"on_fail": "retry_message",
			"retry_text": "нет, попробуй ещё.."
		},
		{
			"type": "send_mail",
			"messages": ["Поздравляю! Уровень пройден."]
		}
	]
}

var current_level: int = 0
var current_stage_index: int = 0
var stages: Array = []   # текущий массив этапов уровня

@export var transition_in_time: float = 0.2
@export var hold_time: float = 0.2   # сколько держим пик статики
@export var transition_out_time: float = 0.25

func _ready() -> void:
	terminal.request_switch_screen.connect(_on_terminal_request_switch_screen)
	other_screen.request_switch_screen.connect(_on_chat_request_switch_screen)
	if menu_layer.has_signal("level_selected"):
		menu_layer.level_selected.connect(_on_level_selected)
	show_menu()

func start_level(level: int):
	current_level = level
	current_stage_index = 0
	stages = levels_data.get(level, [])
	other_screen.clear_messages() # очищаем старые сообщения
	terminal.set_other_screen_pending(false) # на всякий случай
	advance_stage()

func advance_stage():
	while current_stage_index < stages.size():
		var stage = stages[current_stage_index]
		match stage["type"]:
			"send_mail":
				handle_send_mail(stage)
				current_stage_index += 1
			"wait_for_chat_read":
				await chat_opened # ждём, пока игрок откроет чат
				current_stage_index += 1
			"wait_command":
				# Внутренний цикл: ждём правильную команду
				await _process_wait_command(stage)
				# После выхода из _process_wait_command индекс уже увеличен,
				# поэтому просто переходим к следующей итерации while
				# (не увеличиваем current_stage_index здесь, это сделано внутри)
			"minigame":
				await handle_minigame(stage)
				current_stage_index += 1
	finish_level()


func handle_send_mail(stage: Dictionary) -> void:
	var messages: Array = stage.get("messages", [])
	for msg in messages:
		other_screen.add_message(msg)
	terminal.set_other_screen_pending(true)   # зажигаем badge


func show_chat_messages(messages: Array, delays: Array) -> void:
	if not other_screen.visible:
		await _play_static_transition(show_other)
	other_screen.clear_messages()
	for i in range(messages.size()):
		other_screen.add_message(messages[i])
		var delay = delays[i] if i < delays.size() else 1.0
		await get_tree().create_timer(delay).timeout
		
signal command_processed(result: bool)

func handle_wait_for_chat_read() -> void:
	# Ждём, пока игрок откроет чат (show_other вызовет chat_opened)
	await chat_opened

func _process_wait_command(stage: Dictionary) -> void:
	var required_command: StringName = stage["command"]
	var expected_args: Array = stage.get("args", [])
	var on_fail: String = stage.get("on_fail", "retry_message")

	while true:
		var result = await terminal.command_submitted
		var cmd_name: StringName = result[0]
		var argv: PackedStringArray = result[1]
		var full_command: String = result[2]

		if str(cmd_name) == str(required_command):
			# Проверяем аргументы, если они заданы
			if expected_args.is_empty():
				# Неважно, с какими аргументами, подходит любой вызов команды
				current_stage_index += 1
				return
			else:
				# Нужно точное совпадение аргументов
				if Array(argv) == expected_args:
					current_stage_index += 1
					return
				else:
					# Аргументы не совпадают – обрабатываем как ошибку
					_handle_fail(on_fail, stage)
		else:
			_handle_fail(on_fail, stage)

func _handle_fail(on_fail: String, stage: Dictionary) -> void:
	match on_fail:
		"minigame":
			await run_minigame(stage.get("minigame_id", "default"))
		"retry_message":
			var retry_text = stage.get("retry_text", "Неверная команда. Попробуй ещё раз.")
			other_screen.add_message(retry_text)
			terminal.set_other_screen_pending(true)
		_:
			pass   # ничего не делаем

func handle_minigame(stage: Dictionary) -> void:
	var minigame_id = stage.get("minigame_id", "default")
	terminal.print_on_terminal("Запущена мини-игра: " + minigame_id, Color.YELLOW)
	await get_tree().create_timer(2.0).timeout   # имитация

func wait_for_command(required_command: String, stage_data: Dictionary) -> void:
	# Просим игрока переключиться в терминал (можно и принудительно)
	terminal.set_other_screen_pending(true)
	terminal.print_on_terminal("Введите команду: " + required_command, Color.YELLOW)
	
	# Ждём сигнал от терминала (команда введена)
	var awaited_command = required_command
	var success = false
	while not success:
		var entered = await terminal.command_submitted
		var cmd_name = entered[0]   # command_name
		if cmd_name == awaited_command:
			success = true
			terminal.print_on_terminal("Верно!", Color.GREEN)
			current_stage_index += 1
			advance_stage()
			return
		else:
			# Действие при ошибке
			match stage_data.get("on_fail"):
				"minigame":
					await run_minigame(stage_data["minigame_id"])
				"retry_message":
					terminal.print_on_terminal(stage_data["retry_text"], Color.RED)
					
func run_minigame(minigame_id: String) -> void:
	terminal.print_on_terminal("Запущена мини-игра: " + minigame_id, Color.YELLOW)
	await get_tree().create_timer(2.0).timeout   # имитация

func finish_level() -> void:
	var completed_level = GameState.selected_level
	var next_level = completed_level + 1
	if next_level <= 5:
		GameState.unlock_level(next_level)
		terminal.print_on_terminal("Уровень %d открыт!" % next_level, Color.GREEN)
	else:
		terminal.print_on_terminal("Поздравляем! Все уровни пройдены.", Color.GREEN)

	await get_tree().create_timer(2).timeout
	await _play_static_transition(show_menu)
	menu_layer.update_buttons()
	# Сброс состояния уровня
	current_level = 0
	current_stage_index = 0
	stages.clear()
	
func show_menu() -> void:
	terminal_screen.visible = false
	other_screen.visible = false
	transition_layer.visible = false
	menu_layer.visible = true


func show_terminal() -> void:
	terminal_screen.visible = true
	transition_layer.visible = false
	other_screen.visible = false
	menu_layer.visible = false
	terminal.set_other_screen_pending(false)
	if current_level == 0:
		start_level(GameState.selected_level)


func show_other() -> void:
	terminal_screen.visible = false
	transition_layer.visible = false
	menu_layer.visible = false
	other_screen.visible = true
	terminal.set_other_screen_pending(false)
	chat_opened.emit()


func _on_terminal_request_switch_screen(screen_name: StringName) -> void:
	if _transitioning:
		return

	if screen_name == &"other":
		await _play_static_transition(show_other)

func _on_chat_request_switch_screen(screen_name: StringName) -> void:
	if _transitioning:
		return

	if screen_name == &"terminal":
		await _play_static_transition(show_terminal)
	
func _on_level_selected(level: int) -> void:
	if _transitioning:
		return
	
	GameState.selected_level = level
	# Используем тот же переход, что и между терминалом/чатом
	await _play_static_transition(show_terminal)

func _play_static_transition(switch_callback: Callable) -> void:
	_transitioning = true
	transition_layer.visible = true

	black_flash.modulate.a = 0.0
	static_material.set_shader_parameter("strength", 0.0)

	# Вход (разгон статики)
	var tween_in := create_tween()
	tween_in.tween_property(black_flash, "modulate:a", 0.9, transition_in_time)
	tween_in.parallel().tween_method(_set_static_strength, 0.0, 1.0, transition_in_time)
	await tween_in.finished

	await get_tree().create_timer(hold_time).timeout
	switch_callback.call()
	var tween_out := create_tween()
	tween_out.tween_property(black_flash, "modulate:a", 0.0, transition_out_time)
	tween_out.parallel().tween_method(_set_static_strength, 1.0, 0.0, transition_out_time)
	await tween_out.finished

	transition_layer.visible = false
	_transitioning = false

func _set_static_strength(value: float) -> void:
	static_material.set_shader_parameter("strength", value)
