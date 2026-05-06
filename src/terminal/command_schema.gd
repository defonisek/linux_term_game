class_name TerminalCommandSchema
extends RefCounted


class Option:
	var name: String
	var short_name: String
	var description: String
	var type: TerminalArguments.OptionType = TerminalArguments.OptionType.VALUE
	var default_value: Variant


class Positional:
	var name: String
	var description: String
	var default_value: Variant
	var required: bool = true


var allowed_options: Dictionary = {} # name/short_name -> Option
var positional_definitions: Array[Positional] = []


func has_options() -> bool:
	return not allowed_options.is_empty()


func add_option(
	name: String,
	short_name: String = "",
	description: String = "",
	default_value: Variant = null,
	type: TerminalArguments.OptionType = TerminalArguments.OptionType.VALUE,
) -> void:
	assert(name != "help", "Option name 'help' is reserved.")
	assert(short_name != "h", "Short option 'h' is reserved for --help.")

	var option: Option = Option.new()
	option.name = name
	option.short_name = short_name
	option.description = description
	option.type = type

	if default_value == null:
		match type:
			TerminalArguments.OptionType.VALUE: option.default_value = ""
			TerminalArguments.OptionType.INT: option.default_value = 0
			TerminalArguments.OptionType.FLAG: option.default_value = false
	else:
		option.default_value = default_value

	allowed_options[name] = option
	if short_name != "":
		allowed_options[short_name] = option


func add_positional(name: String, description: String = "", default_value: Variant = null) -> void:
	var pos: Positional = Positional.new()
	pos.name = name
	pos.description = description
	pos.default_value = default_value
	pos.required = (default_value == null)
	positional_definitions.append(pos)


func get_option_data(key: String) -> Option:
	return allowed_options.get(key)
