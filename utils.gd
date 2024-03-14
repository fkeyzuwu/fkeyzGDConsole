class_name Utils extends RefCounted

static var enums := {
	&"Player.Wall": Player.Wall
}

static func get_enum(enum_class_name: StringName) -> Dictionary:
	return enums[enum_class_name]
