class_name Logger extends Label

signal log_updated

func log(txt: String):
	text += txt
	text += "\n"
	log_updated.emit()

func clear() -> void:
	text = ""
