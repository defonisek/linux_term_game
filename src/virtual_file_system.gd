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
	_make_file(player_dir, "readme.txt", "Добро пожаловать, игрок!\nИспользуй команды терминала.")
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
