class_name DebugSettings extends Resource

@export var commands: Array[String] 

func has_command(command: String) -> bool:
	return commands.has(command)
	
func add_command(command: String) -> void:
	commands.append(command)
	
func remove_command(command: String) -> void:
	if has_command(command):
		commands.erase(command)
	else:
		push_warning("Couldn't find command " + command + " in DebugSettings")

func clear_commands() -> void:
	commands.clear()
