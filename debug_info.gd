class_name DebugInfo extends Control

@export var property_container: VBoxContainer

func clear_ui() -> void:
	for child in property_container.get_children():
		child.queue_free()

#@onready var player_state: Label = %PlayerState
#@onready var current_speed: Label = %CurrentSpeed
#@onready var current_max_speed: Label = %CurrentMaxSpeed
#@onready var is_on_floor: Label = %IsOnFloor
#@onready var current_wall: Label = %CurrentWall
#@onready var can_wallrun: Label = %CanWallrun
#@onready var current_wall_normal: Label = %CurrentWallNormal
#@onready var last_wall_normal: Label = %LastWallNormal
#@onready var current_orientation: Label = %CurrentOrientation
#@onready var current_player_rotation: Label = %CurrentPlayerRotation
#@onready var current_raycasts_rotation: Label = %CurrentRaycastsRotation
#
#@onready var player: Player = get_parent() as Player
#
#func _process(delta: float) -> void:
	#player_state.text = &"Player State: " + player.state_machine.state.name
	#current_speed.text = &"Speed: " + &"%.2f" % player.current_speed
	#current_max_speed.text = &"Max Speed: " + &"%.2f" % player.current_max_speed
	#is_on_floor.text = &"Is On Floor: " + str(player.is_on_floor())
	#current_wall.text = &"Current Wall: " + str(player.Wall.find_key(player.current_wall))
	#last_wall_normal.text = &"Last Wall Normal " + str(player.last_wall_normal)
	#current_wall_normal.text = &"Current Wall Normal " + str(player.current_wall_normal)
	#can_wallrun.text = &"Can Wallrun: " + str(player.can_wallrun())
	#current_orientation.text = &"Current Orientation: " + str(player.orientation.rotation_degrees) 
	#current_player_rotation.text = &"Current Player Rotation: " + str(player.rotation_degrees) 
	#current_raycasts_rotation.text = &"Current Raycasts Rotation: " + str(player.raycasts.rotation_degrees)
	##if player.state is PlayerStateWallrun:
		##current_wall_direction.text = &"Current Wall Direction: " + str(player.state.wallrun_direction)
	##else:
		##current_wall_direction.text = &""
