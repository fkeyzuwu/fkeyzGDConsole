class_name CommandRunner extends LineEdit

signal entered_command(command: String)

func _on_text_submitted(new_text: String) -> void:
	entered_command.emit(new_text)
	clear()
