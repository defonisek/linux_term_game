class_name VirtualFileSystem
extends RefCounted

class VFSNode:
	var name: String
	var is_dir: bool
	var children: Dictionary = {}
	var content: String = ""

	func _init(p_name: String, p_is_dir: bool):
		name = p_name
		is_dir = p_is_dir

var root: VFSNode

func _init():
	root = VFSNode.new("/", true)
	_build_default_tree()
	print_tree()

func _build_default_tree():
	var home = _make_dir(root, "home")
	var player_dir = _make_dir(home, "player")
	_make_file(player_dir, "readme.txt", "Добро пожаловать, игрок!\nИспользуй команды терминала. терминала терминала терминала терминала терминала терминала терминала терминала терминала \n терминала терминала терминала терминала терминалатерминала терминала")
	var docs = _make_dir(player_dir, "documents")
	_make_file(docs, "notes.txt", "Заметки: выучить ls и cd.")
	_make_dir(player_dir, "downloads")

	var etc = _make_dir(root, "etc")
	_make_file(etc, "passwd", "root:x:0:0:root:/root:/bin/bash\nplayer:x:1000:1000::/home/player:/bin/sh")

	var usr = _make_dir(root, "usr")
	var bin = _make_dir(usr, "bin")
	_make_file(bin, "placeholder", "")

func _make_dir(parent: VFSNode, name: String) -> VFSNode:
	assert(parent.is_dir, "Нельзя создать подкаталог в файле")
	var dir = VFSNode.new(name, true)
	parent.children[name] = dir
	return dir

func _make_file(parent: VFSNode, name: String, content: String) -> VFSNode:
	var file = VFSNode.new(name, false)
	file.content = content
	parent.children[name] = file
	return file

func get_node(abs_path: String) -> VFSNode:
	if abs_path == "/" or abs_path == "":
		return root
	# Убираем начальный "/" и разбиваем
	var clean = abs_path.trim_prefix("/")
	var parts = clean.split("/")
	var current: VFSNode = root
	for part in parts:
		if part == "":
			continue
		if not current.children.has(part):
			return null
		current = current.children[part]
	return current

func resolve(path: String, current_abs: String) -> String:
	if path.begins_with("/"):
		return _clean_path(path)
	else:
		var base = current_abs
		if base != "/":
			base += "/"
		return _clean_path(base + path)

func _clean_path(path: String) -> String:
	var parts = path.split("/")
	var stack: Array[String] = []
	for part in parts:
		if part == "" or part == ".":
			continue
		elif part == "..":
			if stack.size() > 0:
				stack.pop_back()
		else:
			stack.append(part)
	if stack.is_empty():
		return "/"
	return "/" + "/".join(stack)

func cd(target: String, current_abs: String) -> String:
	var new_abs = resolve(target, current_abs)
	var node = get_node(new_abs)
	if node == null or not node.is_dir:
		return ""
	return new_abs

func list_dir(abs_path: String, show_all: bool = false) -> Array[String]:
	var node = get_node(abs_path)
	if node == null or not node.is_dir:
		return []
	var names: Array[String] = []
	for key in node.children.keys():
		if not show_all and key.begins_with("."):
			continue
		names.append(key)
	names.sort()
	return names

func get_info(abs_path: String, name: String) -> String:
	var node = get_node(abs_path)
	if node == null or not node.children.has(name):
		return ""
	var child = node.children[name]
	var type_char = "d" if child.is_dir else "-"
	var size = child.content.length() if not child.is_dir else 0
	var perms = "rwxr-xr-x" if child.is_dir else "rw-r--r--"
	var date = "Jan 1 00:00"
	return "%s%s 1 player player %5d %s %s" % [type_char, perms, size, date, name]

func print_tree():
	print("Состояние псевдофайловой системы")
	_print_node(root, 0)

func _print_node(node: VFSNode, depth: int):
	var indent = "  ".repeat(depth)
	var type = "directory/" if node.is_dir else "file"
	print("%s%s %s" % [indent, type, node.name])
	if node.is_dir:
		for child in node.children.values():
			_print_node(child, depth + 1)
			

func create_file(parent_abs: String, name: String) -> bool:
	var parent = get_node(parent_abs)
	if parent == null or not parent.is_dir:
		return false
	if parent.children.has(name):
		return false          # уже существует
	_make_file(parent, name, "")
	return true


func create_dir(parent_abs: String, name: String) -> bool:
	var parent = get_node(parent_abs)
	if parent == null or not parent.is_dir:
		return false
	if parent.children.has(name):
		return false
	_make_dir(parent, name)
	return true


func delete(abs_path: String, recursive: bool = false) -> bool:
	if abs_path == "/":
		return false   # нельзя удалить корень
	var node = get_node(abs_path)
	if node == null:
		return false
	if node.is_dir and not recursive:
		# не удаляем непустую папку без -r
		if node.children.size() > 0:
			return false
	# Находим родителя и удаляем
	var parent_path = _parent_path(abs_path)
	var parent = get_node(parent_path)
	if parent == null:
		return false
	var name = _base_name(abs_path)
	if parent.children.has(name):
		parent.children.erase(name)
		return true
	return false

func copy(src_abs: String, dest_abs: String) -> bool:
	var src_node = get_node(src_abs)
	if src_node == null:
		return false
	var dest_parent_path = _parent_path(dest_abs)
	var dest_name = _base_name(dest_abs)
	var dest_parent = get_node(dest_parent_path)
	if dest_parent == null or not dest_parent.is_dir:
		return false
	if dest_parent.children.has(dest_name):
		return false   # уже существует
	var new_node = _deep_copy_node(src_node, dest_name)
	dest_parent.children[dest_name] = new_node
	return true

func move(src_abs: String, dest_abs: String) -> bool:
	var src_node = get_node(src_abs)
	if src_node == null:
		return false
	var src_parent_path = _parent_path(src_abs)
	var src_name = _base_name(src_abs)
	if src_parent_path == dest_abs:
		return false   # нельзя переместить в себя
	if not delete(src_abs, true):   # удаляем источник (рекурсивно)
		return false
	# Создаём копию в новом месте (по сути перемещение = скопировать + удалить)
	return _place_node(src_node, dest_abs)

func file_exists(abs_path: String) -> bool:
	return get_node(abs_path) != null

func is_dir(abs_path: String) -> bool:
	var node = get_node(abs_path)
	return node != null and node.is_dir

func read_file(abs_path: String) -> String:
	var node = get_node(abs_path)
	if node == null or node.is_dir:
		return ""
	return node.content

func write_file(abs_path: String, content: String) -> bool:
	var node = get_node(abs_path)
	if node == null or node.is_dir:
		return false
	node.content = content
	return true

func _parent_path(abs_path: String) -> String:
	if abs_path == "/":
		return "/"
	var last_slash = abs_path.rfind("/")
	if last_slash == 0:
		return "/"
	return abs_path.substr(0, last_slash)

func _base_name(abs_path: String) -> String:
	if abs_path == "/":
		return "/"
	return abs_path.split("/")[-1]

func _deep_copy_node(src: VFSNode, new_name: String) -> VFSNode:
	var new_node = VFSNode.new(new_name, src.is_dir)
	new_node.content = src.content
	if src.is_dir:
		for child_name in src.children:
			var child_copy = _deep_copy_node(src.children[child_name], child_name)
			new_node.children[child_name] = child_copy
	return new_node

func _place_node(node: VFSNode, dest_abs: String) -> bool:
	var parent_path = _parent_path(dest_abs)
	var name = _base_name(dest_abs)
	var parent = get_node(parent_path)
	if parent == null or not parent.is_dir:
		return false
	if parent.children.has(name):
		return false
	parent.children[name] = node
	return true

func list_all_files(dir_abs: String) -> Array[String]:
	var out: Array[String] = []
	_collect_files_recursive(dir_abs, out)
	return out

func _collect_files_recursive(dir_abs: String, out: Array[String]) -> void:
	var node = get_node(dir_abs)
	if node == null or not node.is_dir:
		return
	for child_name in node.children:
		var child = node.children[child_name]
		var child_path = dir_abs + "/" + child_name if dir_abs != "/" else "/" + child_name
		if child.is_dir:
			_collect_files_recursive(child_path, out)
		else:
			out.append(child_path)
