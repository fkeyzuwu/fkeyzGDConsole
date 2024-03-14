extends Control

@onready var logger: Logger = %Logger
@onready var command_runner: CommandRunner = %CommandRunner
@onready var debug_info: DebugInfo = $DebugInfo
@onready var view: PanelContainer = %ConsoleView

var settings: DebugSettings = preload("res://debug/debug_settings.tres")

var properties := {} # String(node_name.property_name), Property
var node_refs := {} # String(node_name), Node

var member_pointer := -1
var member_list: Array[String]

var command_pointer := -1
var command_history: Array[String]

const ADD_COMMAND = "add"
const DELETE_COMMAND = "del"
const RUN_COMMAND = "run"
const CLEAR_COMMAND = "clear"

var show_debug_info := false

func _ready() -> void:
	await get_tree().process_frame
	
	LevelManager.switched_level.connect(change_console_state)
	
	for command: String in settings.commands:
		parse_command(command, true)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("hide_debug_info"):
		show_debug_info = !show_debug_info
		debug_info.visible = show_debug_info
	
	if not show_debug_info: return
	
	for full_property_name: String in properties:
		var property: Property = properties[full_property_name]
		if not is_instance_valid(property.p_label): return
		
		var value = property.p_node.get(property.p_name)
		
		if property.p_class_name.contains("."): #enum
			var enum_as_dict = Utils.get_enum(property.p_class_name)
			value = enum_as_dict.find_key(property.p_node.get(property.p_name)) # enum value as string
		elif typeof(value) == TYPE_FLOAT:
			value = &"%.2f" % value
		elif typeof(value) == TYPE_VECTOR3:
			value = &"%.2v" % value
		elif typeof(TYPE_OBJECT):
			value = str(value).get_slice(":", 0)
			
		property.p_label.text = full_property_name + ": " + str(value)

func change_console_state(is_gameplay_level: bool) -> void:
	if not is_gameplay_level:
		properties.clear()
		node_refs.clear()
		debug_info.clear_ui()
	else:
		await get_tree().process_frame
		for command: String in settings.commands:
			parse_command(command, true)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("console"): toggle()
	if !is_on(): return
	
	if event.is_action_pressed("ui_up") and command_history.size() > 0:
		get_viewport().set_input_as_handled()
		command_pointer = clampi(command_pointer - 1, -1, command_history.size() - 1)
		if command_pointer == -1:
			command_runner.text = ""
		else:
			command_runner.text = command_history[command_pointer]
		command_runner.caret_column = command_runner.text.length()
	elif event.is_action_pressed("ui_down") and command_history.size() > 0:
		get_viewport().set_input_as_handled()
		command_pointer = clampi(command_pointer + 1, 0, command_history.size())
		if command_pointer == command_history.size():
			command_runner.text = ""
		else:
			command_runner.text = command_history[command_pointer]
		command_runner.caret_column = command_runner.text.length()
	elif event.is_action_pressed("ui_text_completion_replace"): # Tab
		get_viewport().set_input_as_handled()
		if member_list.size() > 0:
			member_pointer += 1
			member_pointer %= member_list.size()
			var member_name = member_list[member_pointer]
			var command_plus_node = command_runner.text.substr(0, command_runner.text.find(".") + 1)
			command_runner.text = command_plus_node + member_name
			command_runner.caret_column = command_runner.text.length()

func _on_command_runner_text_changed(text: String) -> void:
	reset_autocomplete()
	
	if !text.contains("."): return
	var command_args_split = text.split(" ")
	if command_args_split.size() != 2: return
	var command_name = command_args_split[0]
	var command_args = command_args_split[1]
	var node_and_member = command_args.split(".")
	var node_name = node_and_member[0]
	var member := ""
	if node_and_member.size() > 1:
		member = node_and_member[1]
	var node := get_node_ref(node_name)
	if !node: return
	
	match command_name:
		ADD_COMMAND:
			var property_names = node.get_property_list().map(func(property): return property.name)
			update_autocomplete_members(node, member, property_names)
		DELETE_COMMAND:
			var valid_properties = properties.values().filter(func(property: Property): return node_name == property.p_node.name)
			var property_names = valid_properties.map(func(property: Property): return property.p_name)
			update_autocomplete_members(node, member, property_names)
		RUN_COMMAND:
			var method_names = node.get_method_list().map(func(method): return method.name)
			update_autocomplete_members(node, member, method_names)

func update_autocomplete_members(node: Node, text: String, members: Array) -> void:
	reset_autocomplete()
	for member in members:
		if member.begins_with(text):
			member_list.append(member)

func reset_autocomplete() -> void:
	member_list.clear()
	member_pointer = -1

func parse_command(command: String, init := false) -> void:
	if command == CLEAR_COMMAND:
		clear()
		return
	
	if !command.match("* *.*"):
		logger.log("Invalid command.")
		return
	
	var command_split = command.split(" ")
	var command_type = command_split[0]
	var command_args = command_split[1]
	var args_split = command_args.split(".")
	var node_name = args_split[0]
	var args = args_split[1]
	
	var node := get_node_ref(node_name)
	if !node:
		logger.log("Couldn't find node with name: " + node_name)
		return
	
	var command_succesfull := true
	
	match command_type:
		ADD_COMMAND:
			var property_name = args
			if property_name in node:
				if (init == false and !settings.has_command(command)) or init == true:
					var label = Label.new()
					debug_info.property_container.add_child(label)
					var prop = (node.get_property_list().filter(func(p): return p.name == property_name))[0]
					var property = Property.new(property_name, node, prop.class_name, label)
					properties[command_args] = property
					if init == false:
						settings.add_command(command)
						ResourceSaver.save(settings, settings.resource_path)
			else:
				logger.log("Unknown variable named: " + property_name + " in node " + node_name)
				command_succesfull = false
		DELETE_COMMAND:
			var property_name = args
			var node_plus_property = command_args
			if properties.has(node_plus_property):
				var property =  properties[node_plus_property] as Property
				property.p_label.queue_free()
				properties.erase(node_plus_property)
				settings.remove_command(ADD_COMMAND + " " + command_args)
				ResourceSaver.save(settings, settings.resource_path)
			else:
				logger.log("Unknown variable named: " + property_name + " in node " + node_name)
				command_succesfull = false
		RUN_COMMAND:
			var method_name = args
			if node.has_method(method_name):
				node.call(method_name)
			else:
				logger.log("Unknown method named: " + method_name + " in node " + node_name)
				command_succesfull = false
		_:
			logger.log("Unknown command of type: " + command_type)
			command_succesfull = false
	
	if init == false:
		if command_succesfull:
			logger.log(command)
		
		if command_history.size() == 0 or command_history[-1] != command:
			command_history.append(command)
		command_pointer = command_history.size()

func toggle() -> void:
	view.visible = !view.visible
	if visible: command_runner.grab_focus()
	else: command_runner.release_focus()

func is_on() -> bool:
	return view.visible

func get_node_ref(node_name: String) -> Node:
	if node_name == "": return null
	
	if !node_refs.has(node_name) or !is_instance_valid(node_refs[node_name]):
		var node = get_tree().current_scene.find_child(node_name, true, false)
		if node:
			node_refs[node_name] = node
			return node
		else:
			return null
	else:
		return node_refs[node_name]	

func clear() -> void:
	settings.clear_commands()
	ResourceSaver.save(settings, settings.resource_path)
	debug_info.clear_ui()
	properties.clear()
	logger.clear()

class Property:
	var p_name: String
	var p_node: Node
	var p_class_name: StringName
	var p_label: Label
	
	func _init(_name: String, _node: Node, _class_name: StringName, _label: Label) -> void:
		p_name = _name
		p_node = _node
		p_class_name = _class_name
		p_label = _label


