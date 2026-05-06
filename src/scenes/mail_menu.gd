class_name ChatMenu
extends Control

signal request_switch_screen(screen_name: StringName)

@onready var background: ColorRect = $Background
@onready var back_button: Button = $BackButton
@onready var frame: PanelContainer = $Frame
@onready var title_bar: PanelContainer = $Frame/FrameMargin/FrameVBox/TitleBar
@onready var friend_bar: PanelContainer = $Frame/FrameMargin/FrameVBox/FriendBar
@onready var messages_scroll: ScrollContainer = $Frame/FrameMargin/FrameVBox/ChatArea
@onready var messages_vbox: VBoxContainer = $Frame/FrameMargin/FrameVBox/ChatArea/MessagesVBox

func _ready() -> void:
	_setup_layout()
	set_process_input(true)
	back_button.pressed.connect(_on_back_pressed)
	messages_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	messages_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _setup_layout() -> void:
	background.color = Color(0.07, 0.07, 0.07)

	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0, 0, 0, 0)
	frame_style.border_color = Color.WHITE
	frame_style.border_width_left = 2
	frame_style.border_width_right = 2
	frame_style.border_width_top = 2
	frame_style.border_width_bottom = 2
	frame_style.corner_radius_top_left = 0
	frame_style.corner_radius_top_right = 0
	frame_style.corner_radius_bottom_left = 0
	frame_style.corner_radius_bottom_right = 0
	frame.add_theme_stylebox_override("panel", frame_style)

	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color(0, 0, 0, 0)
	bar_style.border_color = Color.WHITE
	bar_style.border_width_bottom = 2
	bar_style.corner_radius_top_left = 0
	bar_style.corner_radius_top_right = 0
	bar_style.corner_radius_bottom_left = 0
	bar_style.corner_radius_bottom_right = 0

	title_bar.add_theme_stylebox_override("panel", bar_style)
	friend_bar.add_theme_stylebox_override("panel", bar_style)

	title_bar.custom_minimum_size = Vector2(0, 34)
	friend_bar.custom_minimum_size = Vector2(0, 30)

	back_button.text = "← назад"

func add_message(text: String) -> void:
	var line := PanelContainer.new()
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var line_style := StyleBoxFlat.new()
	line_style.bg_color = Color(0, 0, 0, 0)
	line_style.border_color = Color(1, 1, 1, 0.35)
	line_style.border_width_bottom = 1
	line.add_theme_stylebox_override("panel", line_style)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	line.add_child(margin)

	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = text
	margin.add_child(label)

	messages_vbox.add_child(line)

	await get_tree().process_frame
	await get_tree().process_frame
	messages_scroll.scroll_vertical = int(messages_scroll.get_v_scroll_bar().max_value)

func clear_messages() -> void:
	for child in messages_vbox.get_children():
		child.queue_free()
		
func _on_back_pressed() -> void:
	request_switch_screen.emit(&"terminal")

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R or event.physical_keycode == KEY_R:
			request_switch_screen.emit(&"terminal")
			get_viewport().set_input_as_handled()
