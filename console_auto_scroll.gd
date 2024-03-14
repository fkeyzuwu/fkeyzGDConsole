extends ScrollContainer

@onready var scroll_bar := get_v_scroll_bar()

func _on_logger_log_updated() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	set_deferred("scroll_vertical", scroll_bar.max_value)
