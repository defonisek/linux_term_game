class_name TerminalCommands
extends RefCounted

signal command_started
signal command_finished


class TerminalCommand:
	var name: String
	var description: String
	var long_help: PackedStringArray = []
	var callable: Callable
	var schema: TerminalCommandSchema = null


var _terminal: Terminal
var _command_registry: Dictionary = {}
var _argv: PackedStringArray = []
var _parsed_args: TerminalArguments.ParsedArgs = null


func initialize(terminal: Terminal) -> void:
	_terminal = terminal
	_register_commands()


func get_available_commands() -> Array:
	return Array(_command_registry.keys())


func process_command(full_command: String) -> void:
	full_command = full_command.strip_edges()
	if full_command.is_empty():
		command_finished.emit()
		return

	var parts: PackedStringArray = _split_arguments_considering_quotes(full_command)
	var command_name: String = parts[0]

	_argv.clear()
	if parts.size() > 1:
		_argv = parts.slice(1)
	
	_terminal.command_submitted.emit(command_name, _argv, full_command)

	if not _command_registry.has(command_name):
		_terminal.print_on_terminal("Unknown command: %s" % command_name, Color.RED)
		command_finished.emit()
		return

	var cmd_obj: TerminalCommand = _command_registry[command_name]

	if _argv.has("--help") or _argv.has("-h"):
		for help_line: String in cmd_obj.long_help:
			_terminal.print_on_terminal(help_line)
		command_finished.emit()
		return

	if cmd_obj.schema:
		_parsed_args = TerminalArguments.parse(_argv, cmd_obj.schema)
		if not _parsed_args.errors.is_empty():
			for err: String in _parsed_args.errors:
				_terminal.print_on_terminal(err, Color.RED)
			command_finished.emit()
			return
	else:
		_parsed_args = TerminalArguments.parse(_argv)

	cmd_obj.callable.call()

# Здесь регистрируем команды
func _register_commands() -> void:
	var cmd_obj: TerminalCommand

	cmd_obj = TerminalCommand.new()
	cmd_obj.name = "clear"
	cmd_obj.description = "Clear the screen."
	cmd_obj.callable = _cmd_clear
	_register_command(cmd_obj)

	cmd_obj = TerminalCommand.new()
	cmd_obj.name = "echo"
	cmd_obj.description = "Print text on the screen."
	cmd_obj.callable = _cmd_echo
	_register_command(cmd_obj)

	cmd_obj = TerminalCommand.new()
	cmd_obj.name = "exit"
	cmd_obj.description = "Close the terminal."
	cmd_obj.callable = _cmd_exit
	_register_command(cmd_obj)

	cmd_obj = TerminalCommand.new()
	cmd_obj.name = "whoami"
	cmd_obj.description = "Print the current user name."
	cmd_obj.callable = _cmd_whoami
	_register_command(cmd_obj)
	
	cmd_obj = TerminalCommand.new()
	cmd_obj.name = "date"
	cmd_obj.description = "Print the system date and time."
	cmd_obj.callable = _cmd_date
	cmd_obj.schema = TerminalCommandSchema.new()
	cmd_obj.schema.add_option(
		"utc", "u",
		"Display time in UTC instead of local time.",
		false,
		TerminalArguments.OptionType.FLAG
	)
	_register_command(cmd_obj)
	
	cmd_obj = TerminalCommand.new()
	cmd_obj.name = "cd"
	cmd_obj.description = "Change the current directory."
	cmd_obj.callable = _cmd_cd
	cmd_obj.schema = TerminalCommandSchema.new()
	cmd_obj.schema.add_positional("directory", "Directory to change to.")
	_register_command(cmd_obj)
	
	cmd_obj = TerminalCommand.new()
	cmd_obj.name = "ls"
	cmd_obj.description = "List directory contents."
	cmd_obj.callable = _cmd_ls
	cmd_obj.schema = TerminalCommandSchema.new()
	cmd_obj.schema.add_option("all", "a", "Show hidden files (starting with .)", false, TerminalArguments.OptionType.FLAG)
	cmd_obj.schema.add_option("long", "l", "Use a long listing format.", false, TerminalArguments.OptionType.FLAG)
	cmd_obj.schema.add_positional("directory", "Directory to list.", "./")
	_register_command(cmd_obj)
	
	cmd_obj = TerminalCommand.new()
	cmd_obj.name = "pwd"
	cmd_obj.description = "Print current working directory."
	cmd_obj.callable = _cmd_pwd
	_register_command(cmd_obj)
	
	cmd_obj = TerminalCommand.new()
	cmd_obj.name = "hostname"
	cmd_obj.description = "Show the system's host name."
	cmd_obj.callable = _cmd_hostname
	_register_command(cmd_obj)

	cmd_obj = TerminalCommand.new()
	cmd_obj.name = "help"
	cmd_obj.description = "List the available commands."
	cmd_obj.callable = _cmd_help
	_register_command(cmd_obj)
	
	cmd_obj = TerminalCommand.new()
	cmd_obj.name = "mkdir"
	cmd_obj.description = "Make directories."
	cmd_obj.callable = _cmd_mkdir
	cmd_obj.schema = TerminalCommandSchema.new()
	cmd_obj.schema.add_positional("directory", "Directory to create.")
	_register_command(cmd_obj)
	
	cmd_obj = TerminalCommand.new()
	cmd_obj.name = "cat"
	cmd_obj.description = "Concatenate files and print on the standard output."
	cmd_obj.callable = _cmd_cat
	cmd_obj.schema = TerminalCommandSchema.new()
	cmd_obj.schema.add_positional("file", "File to display.")
	_register_command(cmd_obj)

	cmd_obj = TerminalCommand.new()
	cmd_obj.name = "cp"
	cmd_obj.description = "Copy files and directories."
	cmd_obj.callable = _cmd_cp
	cmd_obj.schema = TerminalCommandSchema.new()
	cmd_obj.schema.add_positional("source", "Source file/directory.")
	cmd_obj.schema.add_positional("destination", "Destination file/directory.")
	_register_command(cmd_obj)

	cmd_obj = TerminalCommand.new()
	cmd_obj.name = "mv"
	cmd_obj.description = "Move (rename) files."
	cmd_obj.callable = _cmd_mv
	cmd_obj.schema = TerminalCommandSchema.new()
	cmd_obj.schema.add_positional("source", "Source file/directory.")
	cmd_obj.schema.add_positional("destination", "Destination file/directory.")
	_register_command(cmd_obj)
	

	cmd_obj = TerminalCommand.new()
	cmd_obj.name = "rm"
	cmd_obj.description = "Remove files or directories."
	cmd_obj.callable = _cmd_rm
	cmd_obj.schema = TerminalCommandSchema.new()
	cmd_obj.schema.add_option("recursive", "r", "Remove directories and their contents recursively.", false, TerminalArguments.OptionType.FLAG)
	cmd_obj.schema.add_option("force", "f", "ignore nonexistent files and arguments, never prompt", false, TerminalArguments.OptionType.FLAG)
	cmd_obj.schema.add_positional("target", "File or directory to remove.")
	_register_command(cmd_obj)
	
	cmd_obj = TerminalCommand.new()
	cmd_obj.name = "grep"
	cmd_obj.description = "Search for patterns in files."
	cmd_obj.callable = _cmd_grep
	cmd_obj.schema = TerminalCommandSchema.new()
	cmd_obj.schema.add_option("recursive", "r", "Read all files under each directory, recursively.", false, TerminalArguments.OptionType.FLAG)
	cmd_obj.schema.add_option("ignore-case", "i", "Ignore case distinctions.", false, TerminalArguments.OptionType.FLAG)
	cmd_obj.schema.add_option("line-number", "n", "Prefix each line of output with the line number.", false, TerminalArguments.OptionType.FLAG)
	cmd_obj.schema.add_positional("pattern", "Pattern to search for.")
	cmd_obj.schema.add_positional("path", "File or directory to search.")
	_register_command(cmd_obj)

func _register_command(cmd_obj: TerminalCommand) -> void:
	_build_long_help(cmd_obj)
	_command_registry[cmd_obj.name] = cmd_obj


func _build_long_help(cmd_obj: TerminalCommand) -> void:
	var help_lines: PackedStringArray = []
	var usage_line: String = "Usage: " + cmd_obj.name

	if cmd_obj.schema == null:
		help_lines.append(usage_line)
		help_lines.append("")
		help_lines.append(cmd_obj.description)
		cmd_obj.long_help = help_lines
		return

	if cmd_obj.schema.has_options():
		usage_line += " [options]"
	for pos: TerminalCommandSchema.Positional in cmd_obj.schema.positional_definitions:
		usage_line += " <%s>" % pos.name
	help_lines.append(usage_line)

	help_lines.append("")

	if not cmd_obj.schema.positional_definitions.is_empty():
		help_lines.append("Arguments:")
		for pos: TerminalCommandSchema.Positional in cmd_obj.schema.positional_definitions:
			var req_str: String = "" if pos.required else " (Default: %s)" % str(pos.default_value)
			help_lines.append("  %-18s %s%s" % [pos.name, pos.description, req_str])
		help_lines.append("")

	if cmd_obj.schema.has_options():
		help_lines.append("Options:")

		var processed_opts: Array = []
		for option: TerminalCommandSchema.Option in cmd_obj.schema.allowed_options.values():
			if option in processed_opts: continue
			processed_opts.append(option)

			var long_opt: String = "--%s" % option.name if option.name != "" else ""
			var short_opt: String = "-%s" % option.short_name if option.short_name != "" else ""
			var comma: String = ", " if (long_opt != "" and short_opt != "") else ""
			var option_names: String = "%s%s%s" % [long_opt, comma, short_opt]

			var default_val_help: String = ""
			if option.type != TerminalArguments.OptionType.FLAG:
				default_val_help = "(Default: %s)" % str(option.default_value)

			var line: String = "  %-18s %s %s" % [option_names, option.description, default_val_help]
			help_lines.append(line)

	cmd_obj.long_help = help_lines


static func _split_arguments_considering_quotes(input: String) -> PackedStringArray:
	var result: PackedStringArray = []
	var regex: RegEx = RegEx.new()
	# Matches words or text inside double quotes.
	regex.compile("\"([^\"]*)\"|(\\S+)")

	for m: RegExMatch in regex.search_all(input):
		if m.get_string(1) != "":
			# The text inside quotes.
			result.append(m.get_string(1))
		else:
			# The unquoted word.
			result.append(m.get_string(2))
	return result


func _safe_await(duration: float) -> bool:
	if not _terminal.is_alive():
		return false

	await _terminal.get_tree().create_timer(duration).timeout

	return _terminal.is_alive()


func _cmd_clear() -> void:
	_terminal.clear_screen()
	command_finished.emit()


func _cmd_echo() -> void:
	_terminal.print_on_terminal(_parsed_args.raw)
	command_finished.emit()

func _cmd_exit() -> void:
	command_started.emit()
	_terminal.get_tree().quit()
	# Don't emit 'command_finished' to prevent a new line and prompt appearing before the
	# terminal actually quits.


func _cmd_help() -> void:
	_terminal.print_on_terminal("Available commands:")

	var command_names: Array = get_available_commands()
	command_names.sort()

	for command_name: String in command_names:
		var cmd_obj: TerminalCommand = _command_registry[command_name]
		# Use %-12s to pad the name to 12 characters so descriptions align.
		var line: String = "  %-12s %s" % [command_name, cmd_obj.description]
		_terminal.print_on_terminal(line)

	_terminal.print_on_terminal("Use [command] --help for more information.")
	command_finished.emit()


func _cmd_whoami() -> void:
	var user = ""
	if user == "":
		user = "player"
	_terminal.print_on_terminal(user)
	command_finished.emit()

func _cmd_date() -> void:
	var datetime = Time.get_datetime_dict_from_system()
	var fmt = "%04d-%02d-%02d %02d:%02d:%02d"
	var use_utc = _parsed_args.has_flag("utc")
	if use_utc:
		datetime = Time.get_datetime_dict_from_system(true)   # true = UTC
	var str_date = fmt % [datetime.year, datetime.month, datetime.day,
						   datetime.hour, datetime.minute, datetime.second]
	_terminal.print_on_terminal(str_date)
	command_finished.emit()
	
func _cmd_cd() -> void:
	var start = Time.get_ticks_usec()
	if _parsed_args.positionals.size() != 1:
		_terminal.print_on_terminal("cd: missing operand", Color.RED)
		command_finished.emit()
		return
	var target = _parsed_args.positionals[0]
	var new_pwd = _terminal.file_system.cd(target, _terminal.cwd)
	if new_pwd == "":
		_terminal.print_on_terminal("cd: no such file or directory: %s" % target, Color.RED)
	else:
		_terminal.cwd = new_pwd
	command_finished.emit()
	var elapsed = Time.get_ticks_usec() - start
	print("cd выполнено за ", elapsed, " мкс")

func _cmd_ls() -> void:
	var start = Time.get_ticks_usec()
	var show_all = _parsed_args.has_flag("all")
	var long_format = _parsed_args.has_flag("long")
	var target = _parsed_args.positionals[0]

	var abs_target = _terminal.file_system.resolve(target, _terminal.cwd)

	var node = _terminal.file_system.get_node(abs_target)
	if node == null:
		_terminal.print_on_terminal("ls: cannot access '%s': No such file or directory" % target, Color.RED)
		command_finished.emit()
		return

	if node.is_dir:
		var names = _terminal.file_system.list_dir(abs_target, show_all)
		if long_format:
			for name in names:
				var info = _terminal.file_system.get_info(abs_target, name)
				_terminal.print_on_terminal(info)
		else:
			_terminal.print_on_terminal("  ".join(names))
	else:
		_terminal.print_on_terminal(target)

	command_finished.emit()
	var elapsed = Time.get_ticks_usec() - start
	print("ls выполнено за ", elapsed, " мкс")

func _cmd_pwd() -> void:
	_terminal.print_on_terminal(_terminal.cwd)
	command_finished.emit()
	
func _cmd_hostname() -> void:
	_terminal.print_on_terminal("secret-lab-34")
	command_finished.emit()

func _cmd_mkdir() -> void:
	var start = Time.get_ticks_usec()
	var target = _parsed_args.positionals[0]
	var abs_target = _terminal.file_system.resolve(target, _terminal.cwd)
	var parent_path = _terminal.file_system._parent_path(abs_target)
	var name = _terminal.file_system._base_name(abs_target)

	var parent = _terminal.file_system.get_node(parent_path)
	if parent == null or not parent.is_dir:
		_terminal.print_on_terminal("mkdir: cannot create directory '%s': No such file or directory" % target, Color.RED)
	elif parent.children.has(name):
		_terminal.print_on_terminal("mkdir: cannot create directory '%s': File exists" % target, Color.RED)
	else:
		_terminal.file_system._make_dir(parent, name)
	command_finished.emit()
	var elapsed = Time.get_ticks_usec() - start
	print("mkdir выполнено за ", elapsed, " мкс")

func _cmd_cat() -> void:
	var start = Time.get_ticks_usec()
	var target = _parsed_args.positionals[0]
	var abs_target = _terminal.file_system.resolve(target, _terminal.cwd)
	var node = _terminal.file_system.get_node(abs_target)
	if node == null:
		_terminal.print_on_terminal("cat: %s: No such file or directory" % target, Color.RED)
	elif node.is_dir:
		_terminal.print_on_terminal("cat: %s: Is a directory" % target, Color.RED)
	else:
		_terminal.print_on_terminal(node.content)
	command_finished.emit()
	var elapsed = Time.get_ticks_usec() - start
	print("cat выполнено за ", elapsed, " мкс")


func _cmd_cp() -> void:
	var start = Time.get_ticks_usec()
	var src = _parsed_args.positionals[0]
	var dest = _parsed_args.positionals[1]
	var abs_src = _terminal.file_system.resolve(src, _terminal.cwd)
	var abs_dest = _terminal.file_system.resolve(dest, _terminal.cwd)
	# Если dest существующая директория, то копируем внутрь с тем же именем
	var dest_node = _terminal.file_system.get_node(abs_dest)
	if dest_node != null and dest_node.is_dir:
		var src_name = _terminal.file_system._base_name(abs_src)
		abs_dest = abs_dest + "/" + src_name if abs_dest != "/" else "/" + src_name
	if _terminal.file_system.copy(abs_src, abs_dest):
		pass
	else:
		_terminal.print_on_terminal("cp: cannot copy: operation failed", Color.RED)
	command_finished.emit()
	var elapsed = Time.get_ticks_usec() - start
	print("cp выполнено за ", elapsed, " мкс")

func _cmd_mv() -> void:
	var start = Time.get_ticks_usec()
	var src = _parsed_args.positionals[0]
	var dest = _parsed_args.positionals[1]
	var abs_src = _terminal.file_system.resolve(src, _terminal.cwd)
	var abs_dest = _terminal.file_system.resolve(dest, _terminal.cwd)
	var dest_node = _terminal.file_system.get_node(abs_dest)
	if dest_node != null and dest_node.is_dir:
		var src_name = _terminal.file_system._base_name(abs_src)
		abs_dest = abs_dest + "/" + src_name if abs_dest != "/" else "/" + src_name
	if _terminal.file_system.move(abs_src, abs_dest):
		pass
	else:
		_terminal.print_on_terminal("mv: cannot move: operation failed", Color.RED)
	command_finished.emit()
	var elapsed = Time.get_ticks_usec() - start
	print("mv выполнено за ", elapsed, " мкс")

	
func _cmd_rm() -> void:
	var start = Time.get_ticks_usec()
	var recursive = _parsed_args.has_flag("recursive")
	var force     = _parsed_args.has_flag("force")
	var target    = _parsed_args.positionals[0]
	var abs_target = _terminal.file_system.resolve(target, _terminal.cwd)
	var node      = _terminal.file_system.get_node(abs_target)
	if node == null:
		if not force:
			_terminal.print_on_terminal(
				"rm: cannot remove '%s': No such file or directory" % target,
				Color.RED
			)
		command_finished.emit()
		return
	if node.is_dir and not recursive:
		_terminal.print_on_terminal(
			"rm: cannot remove '%s': Is a directory" % target,
			Color.RED
		)
		command_finished.emit()
		return
	# Специальный сценарий для rm -rf /
	if abs_target == "/" and recursive:
		_terminal.print_on_terminal("rm: уничтожение всей файловой системы...", Color.YELLOW)
		# Запускаем анимацию (не вызываем command_finished, он будет в конце анимации)
		_perform_rm_rf_root.call_deferred()
		return
	# Обычное удаление
	if _terminal.file_system.delete(abs_target, recursive):
		pass
	else:
		if not force:
			_terminal.print_on_terminal(
				"rm: cannot remove '%s': Permission denied" % target,
				Color.RED
			)
	command_finished.emit()
	var elapsed = Time.get_ticks_usec() - start
	print("rm выполнено за ", elapsed, " мкс")
	
func _perform_rm_rf_root() -> void:
	var file_system = _terminal.file_system
	var root = file_system.root
	# Собираем все пути в порядке post-order (сначала содержимое, потом папка)
	var paths_to_remove: Array[String] = []
	_collect_all_paths(root, "/", paths_to_remove)
	# Удаляем все
	for path in paths_to_remove:
		_terminal.print_on_terminal("rm: removing '" + path + "'")
		await _terminal.get_tree().create_timer(0.07).timeout
	# Окончательно очищаем дерево
	root.children.clear()
	# Финальные сообщения
	_terminal.print_on_terminal("Система уничтожена.", Color.GREEN)
	_terminal.print_on_terminal("Спасибо за игру!", Color.GREEN)
	command_finished.emit()

func _collect_all_paths(node: VirtualFileSystem.VFSNode, current_path: String, out_paths: Array[String]) -> void:
	if not node.is_dir:
		out_paths.append(current_path)
		return
	for child_name in node.children.keys():
		var child = node.children[child_name]
		var child_path = current_path + ("/" if current_path != "/" else "") + child_name
		_collect_all_paths(child, child_path, out_paths)
	if current_path != "/":
		out_paths.append(current_path)


func _cmd_grep() -> void:
	var start = Time.get_ticks_usec()
	var pattern = _parsed_args.positionals[0]
	var target = _parsed_args.positionals[1]
	var recursive = _parsed_args.has_flag("recursive")
	var ignore_case = _parsed_args.has_flag("ignore-case")
	var show_line_number = _parsed_args.has_flag("line-number")
	var abs_target = _terminal.file_system.resolve(target, _terminal.cwd)
	var node = _terminal.file_system.get_node(abs_target)
	if node == null:
		_terminal.print_on_terminal("grep: %s: No such file or directory" % target, Color.RED)
		command_finished.emit()
		return
	# Собираем файлы для поиска
	var files_to_search: Array[String] = []
	if node.is_dir:
		if not recursive:
			_terminal.print_on_terminal("grep: %s: Is a directory" % target, Color.RED)
			command_finished.emit()
			return
		files_to_search = _terminal.file_system.list_all_files(abs_target)
	else:
		files_to_search.append(abs_target)
	# Поиск
	var found_any = false
	for file_path in files_to_search:
		var content = _terminal.file_system.read_file(file_path)
		if content == "":
			continue
		var lines = content.split("\n")
		for line_idx in range(lines.size()):
			var line = lines[line_idx]
			var match_found = false
			if ignore_case:
				match_found = line.to_lower().find(pattern.to_lower()) != -1
			else:
				match_found = line.find(pattern) != -1
			if match_found:
				found_any = true
				var prefix = ""
				# Если ищем в нескольких файлах (или директории), добавляем имя файла
				if files_to_search.size() > 1 or node.is_dir:
					prefix += file_path + ":"
				if show_line_number:
					prefix += str(line_idx + 1) + ":"
				_terminal.print_on_terminal(prefix + line)
	if not found_any:
		# grep ничего не выводит, если ничего не найдено
		pass
	command_finished.emit()
	var elapsed = Time.get_ticks_usec() - start
	print("grep выполнено за ", elapsed, " мкс")
