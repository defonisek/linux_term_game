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
				"так. сообщения идут? test.",
				"агент 02? отлично, рад, что ты успешно проник на базу.",
				"я слышал, что ты отличный шпион. видимо, говорят правду.",
				"моё позывное - друг. мы не знакомы.",
				"не будем тратить много времени. мне известно, что ты ничего не смыслишь в таких компьютерах. ничего страшного, меня поставили помочь обнаружить секреты, которые прячет эта система.",
				"это - терминал. способ взаимодействия с компьютером, с файлами и системой в целом. оно принимает *команды* и выполняет их.",
				"давай попробуем что-нибудь ввести в терминал. компьютер примет это и выполнит.",
                "вернись туда, нажав на R, и попробуй написать \"help\". это должно выдать тебе список всех доступных команд."
			]
		},
		{ "type": "wait_for_chat_read" },
		{
			"type": "wait_command",
			"command": "help",
			"on_fail": "retry_message",
			"retry_text": "не торопись. просто введи help и нажми enter."
		},
		{
			"type": "send_mail",
			"messages": [
				"отлично. ты увидел список команд. их действительно много. не беспокойся, мы пойдем от простого к сложному.",
				"help это хорошо, но что если надо узнать подробности о конкретной команде?",
				"почти каждая команда поддерживает флаг -h (или --help). он показывает краткую справку о том, как её использовать.",
				"что такое флаг? это какой-то указатель на необходимость включить часть функционала команды. например, в случае передачи -h, команда читает этот -h и понимает, что нужно вывести краткую справку.",
				"давай проверим и заодно перейдем к следующей команде: введи \"echo -h\"."
			]
		},
		{ "type": "wait_for_chat_read" },
		{
			"type": "wait_command",
			"command": "echo",
			"args": ["-h"],
			"on_fail": "retry_message",
			"retry_text": "именно: echo -h (через пробел). попробуй ещё раз, без этого мы ничего толком тут не найдем."
		},
		{
			"type": "send_mail",
			"messages": [
				"видишь? система выдала описание. полезный трюк, если ты вдруг забудешь, что делает команда.",
				"теперь собственно используем саму команду echo: она повторяет всё, что ты ей передашь. действительно как эхо.",
				"попробуй вывести, например, \"echo hello\"."
			]
		},
		{ "type": "wait_for_chat_read" },
		{
			"type": "wait_command",
			"command": "echo",
			"args": ["hello"],
			"on_fail": "retry_message",
			"retry_text": "02, выполняй поручения точно. \"echo hello\". у тебя еще появится возможность поделать что-то другое, когда научишься основам."
		},
		{
			"type": "send_mail",
			"messages": [
				"отлично. в принципе основы работы с терминалом ты, думаю, понял. вводишь команду - получаешь результат.",
    	        "теперь к работе. нам нужно узнать, за тем ли ты компьютером. проверь с помощью команды hostname и выведи с помощью echo только номер компьютера."
			]
		},
		{ "type": "wait_for_chat_read" },
		{
			"type": "wait_command",
			"command": "echo",
			"args": ["34"]
		},
		{
			"type": "send_mail",
			"messages": [
				"34, ага, хорошо... я попробую выяснить, что потенциально скрывается на системе 34.",
				"пока продолжим. для наших целей нужно выяснить, правильно ли система отслеживает дату и время по UTC. это команда date с флагом. с каким - выясни сам."
			]
		},
		{ "type": "wait_for_chat_read" },
		{
			"type": "wait_command",
			"command": "date",
			"args": ["-u"]
		},
		{
			"type": "send_mail",
			"messages": [
				"отлично... так, отмена, к тебе кто-то движется!",
				"очисти экран командой clear, быстро!"
			]
		},
		{ "type": "wait_for_chat_read" },
		{
			"type": "wait_command",
			"command": "clear",
			"on_fail": "retry_message",
			"retry_text": "просто \"clear\", это зачистит все, что на экране."
		},
		{
			"type": "send_mail",
			"messages": ["историю чата я сотру сам. уходи."]
		}
	],
	2: [
		{
			"type": "send_mail",
			"messages": [
				"02, рад, что ты в порядке. что-то они точно подозревают.",
				"ладно, продолжим. в общем, сейчас поговорим о файловой системе. вся система - это дерево: есть корень /, от него отходят папки (директории). например, путь /home/player стоит читать как папка \"/\" над которой папка \"home\", над которой папка \"player\".",
	            "команда pwd покажет, где внутри файловой системы ты находишься. pwd - print working directory, буквально напечатать рабочую директорию."
			]
		},
		{ "type": "wait_for_chat_read" },
		{
			"type": "wait_command",
			"command": "pwd",
			"on_fail": "retry_message",
			"retry_text": "просто pwd."
		},
		{
			"type": "send_mail",
			"messages": [
				"ты в /home/player, что логично.",
				"ls выводит содержимое текущей директории, то есть player. осмотрись: ls."
			]
		},
		{ "type": "wait_for_chat_read" },
		{
			"type": "wait_command",
			"command": "ls",
			"on_fail": "retry_message",
			"retry_text": "ls, без флагов."
		},
		{
			"type": "send_mail",
			"messages": [
				"у рабочего этой системы много файлов.",
				"но не факт, что мы видим их все. у ls есть полезные флаги. узнай их через ls -h."
			]
		},
		{ "type": "wait_for_chat_read" },
		{
			"type": "wait_command",
			"command": "ls",
			"args": ["-h"],
			"on_fail": "retry_message",
			"retry_text": "ls -h"
		},
		{
			"type": "send_mail",
			"messages": [
	            "видишь флаг -a? он показывает скрытые файлы (имена начинаются с точки). используй ls -a и выведи мне название скрытого файла через echo."
			]
		},
		{ "type": "wait_for_chat_read" },
		{
			"type": "wait_command",
			"command": "echo",
			"args": [".notes.txt"]
		},
		{
			"type": "send_mail",
			"messages": [
	            "отлично, с ним поработаем позже. теперь команда cd (change directory), которая меняет папку. ему можно передавать как и полный путь, так и одну папку, которая находится в одной директории с тобой (в директории, которая выводится при pwd). передаваемая папка называется аргументом команды. попробуй: перейди в personal, там может что-то быть."
			]
		},
		{ "type": "wait_for_chat_read" },
		{
			"type": "wait_command",
			"command": "cd",
			"args": ["personal"]
		},
		{
			"type": "send_mail",
			"messages": [
	            "отлично. помни, что в любой папке работает команда ls, позволяющая посмотреть её содержимое. теперь про cat - она берет аргументом название файла и выводит его содержимое в терминал. попробуй вывести содержимое файла этой папки в терминал."
			]
		},
		{ "type": "wait_for_chat_read" },
		{
			"type": "wait_command",
			"command": "cat",
			"args": ["photos_list.txt"]
		},
		{
			"type": "send_mail",
			"messages": [
	            "ну, чтож, ничего ценного. возвращаемся назад: cd .. поднимает на уровень выше, в директории над текущей. условно из \"/home/player\" перенесет в \"/home\". введи cd .."
			]
		},
		{ "type": "wait_for_chat_read" },
		{
			"type": "wait_command",
			"command": "cd",
			"args": [".."],
			"on_fail": "retry_message",
			"retry_text": "cd .."
		},
		{
			"type": "send_mail",
			"messages": [
				"есть данные, что агент 99, работающий на нас, на самом деле двойной агент. печально, но нам придется его подловить. для этого нужен их местный код, который используется для встречи. найди в этой системе секретный код встречи с ним (в формате ###-###) и выведи его через echo.",
	            "ищи в файлах, используй cd, ls и cat. когда найдёшь - выведи код командой echo <код>."
			]
		},
		{ "type": "wait_for_chat_read" },
		{
			"type": "wait_command",
			"command": "echo",
			"args": ["X7G-PL9"]
		},
		{
			"type": "send_mail",
			"messages": [
				"отличная работа!"
			]
		},
		{ "type": "wait_for_chat_read" }
	],
	3: [
		{
			"type": "send_mail",
			"messages": [
				"агент 02, начинаем управлять файлами. не будем долго разглагольствовать. rm удаляет файлы. будь осторожен, их восстановить не получится.",
	            "удали, например, скрытый файл .notes.txt. можешь посмотреть rm -h"
			]
		},
		{ "type": "wait_for_chat_read" },
		{
			"type": "wait_command",
			"command": "rm",
			"args": [".notes.txt"]
		},
		{
			"type": "send_mail",
			"messages": [
	            "ок. теперь команда mkdir, она создаёт новую папку. создай в текущей директории временную папку temp: mkdir temp"
			]
		},
		{ "type": "wait_for_chat_read" },
		{
			"type": "wait_command",
			"command": "mkdir",
			"args": ["temp"]
		},
		{
			"type": "send_mail",
			"messages": [
	            "cp копирует файлы. скопируй readme.txt в папку temp."
			]
		},
		{ "type": "wait_for_chat_read" },
		{
			"type": "wait_command",
			"command": "cp",
			"args": ["readme.txt", "temp"],
			"on_fail": "retry_message",
			"retry_text": "для помощи почитай cp -h, все как раньше"
		},
		{
			"type": "send_mail",
			"messages": [
				"mv перемещает (или переименовывает!) файлы. перемести temp/readme.txt в текущую папку с именем copy.txt:",
	            "тут задание чуть посложнее, поэтому помогу: mv temp/readme.txt copy.txt"
			]
		},
		{ "type": "wait_for_chat_read" },
		{
			"type": "wait_command",
			"command": "mv",
			"args": ["temp/readme.txt", "copy.txt"]
		},
		{
			"type": "send_mail",
			"messages": [
	            "молодец. теперь полезные дела: подготовим пакет для отправки к нам. создай в домашней директории папку send."
			]
		},
		{ "type": "wait_for_chat_read" },
		{
			"type": "wait_command",
			"command": "mkdir",
			"args": ["send"]
		},
		{
			"type": "send_mail",
			"messages": [
	            "скопируй туда файл contacts.txt"
			]
		},
		{ "type": "wait_for_chat_read" },
		{
			"type": "wait_command",
			"command": "cp",
			"args": ["configs/contacts.txt", "send"],
			"on_fail": "retry_message",
			"retry_text": "cp configs/contacts.txt send из директории /home/player"
		},
		{
			"type": "send_mail",
			"messages": [
	            "проверь, что всё на месте: ls send."
			]
		},
		{ "type": "wait_for_chat_read" },
		{
			"type": "wait_command",
			"command": "ls",
			"args": ["send"]
		},
		{
			"type": "send_mail",
			"messages": [
				"класс, я сам перехвачу эти файлы."
			]
		},
		{ "type": "wait_for_chat_read" }
	],
	4: [
		{
			"type": "send_mail",
			"messages": [
				"агент 02, остался последний рывок. команда grep ищет строки по шаблону в файлах.",
	            "проверим: введи grep \"Агент\" todo.txt"
			]
		},
		{ "type": "wait_for_chat_read" },
		{
			"type": "wait_command",
			"command": "grep",
			"args": ["Агент", "todo.txt"]
		},
		{
			"type": "send_mail",
			"messages": [
				"видишь строку? команда grep показала все вхождения 'Агент' в файле.",
	            "теперь поищем рекурсивно во всех файлах и папках: grep -r \"Агент\" . что значит рекурсивно? это значит, что grep будет заходить во все папки и файлы последовательно, в том числе во вложенные друг в друга."
			]
		},
		{ "type": "wait_for_chat_read" },
		{
			"type": "wait_command",
			"command": "grep",
			"args": ["-r", "Агент", "."],
			"on_fail": "retry_message",
			"retry_text": "grep -r \"Агент\" . (точка означает текущую папку)"
		},
		{
			"type": "send_mail",
			"messages": [
				"флаг -r прошёл по всем вложенным папкам.",
				"еще полезные флаги из grep -h: -i (игнорировать регистр), -n (показать номера строк).",
	            "Проверь: grep -in \"связаться\" todo.txt"
			]
		},
		{ "type": "wait_for_chat_read" },
		{
			"type": "wait_command",
			"command": "grep",
			"args": ["-in", "связаться", "todo.txt"],
			"on_fail": "retry_message",
			"retry_text": "grep -in \"связаться\" todo.txt"
		},
		{
			"type": "send_mail",
			"messages": [
				"отлично. теперь ты знаешь основы grep.",
				"и теперь само финальное задание. в папке /var/log горы логов, и в одном файле скрыт секретный код. на этот раз - это ключ доступа ко всем системам с этой базы, который позволит использовать все компьютеры удаленно.",
				"найди его с помощью grep, а когда найдёшь - выведи полученное слово командой echo. он может быть выделен каким-то словом, например \"code\" или что-то подобное. поперебирай с помощью grep.",
	            "этот код критически важен. с ним твоя миссия будет почти завершена. найди его поскорее. он должен быть выделен ЗАГЛАВНЫМИ БУКВАМИ."
			]
		},
		{ "type": "wait_for_chat_read" },
		{
			"type": "wait_command",
			"command": "echo",
			"args": ["GHOSTWHALE"]
		},
		{
			"type": "send_mail",
			"messages": [
				"GHOSTWHALE.",
	            "ты быстро учишься. последний шаг - полная зачистка этой системы."
			]
		},
		{ "type": "wait_for_chat_read" }
	],
	5: [
	{
			"type": "send_mail",
			"messages": [
				"агент 02, ты отлично отработал. мы добыли секретный код, но противник не должен этого узнать.",
				"ты должен уничтожить все данные. полностью. без следа.",
				"для этого можно использовать команду rm, которую ты уже знаешь, с двумя флагами: -r (recursive - удалять папки с содержимым) и -f (force - не спрашивать, игнорировать ошибки).",
				"если передать ей корень системы /, она сотрёт всё: файлы, папки, системные конфиги - абсолютно всё.",
				"это команда rm -rf /. она необратима. после неё система превратится в пустоту.",
    	        "понял? уничтожай, 02. с тобой было приятно работать."
			]
		},
		{ "type": "wait_for_chat_read" },
		{
			"type": "wait_command",
			"command": "rm",
			"args": ["-rf", "/"]
		},
		{
			"type": "send_mail",
			"messages": [
				"увидимся.",
    	        "миссия завершена."
			]
		},
		{ "type": "wait_for_chat_read" }
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
			var retry_text = stage.get("retry_text", "")
			if retry_text != null and retry_text != "":
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
