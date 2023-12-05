extends Node

# Enum for traffic states
enum TrafficState { RED_LIGHT, GREEN_LIGHT }

# Current state
var current_state: TrafficState = TrafficState.GREEN_LIGHT

# Reference to the UI label
var ui_label: Label
var num_switches: int = 0

# Variables for random timing
var min_time_between_switches: float = 5.0  # Minimum time in seconds
var max_time_between_switches: float = 30.0  # Maximum time in seconds
var time_to_next_switch: float = 0  # Time until the next state switc
var time_left_to_next_spawn: float = 1.0
var time_between_spawns: float = 3.0

var main: Node3D

func enemy_manager_synch():
	main = get_node("/root/Main2")

func _ready():
	ui_label = get_node("/root/Main2/Map/FpPlayer/FpHud/MousePassHud/Top/LightStatus")  # Adjust the path to your label
	update_label()
	time_to_next_switch = randf_range(min_time_between_switches, max_time_between_switches)
	
func _process(delta):
	time_to_next_switch -= delta
	if time_to_next_switch <= 0:
		switch_state()
		time_to_next_switch = randf_range(min_time_between_switches, max_time_between_switches)
	if is_green_light():
		time_left_to_next_spawn -= delta
		if time_left_to_next_spawn <= 0:
			time_left_to_next_spawn = time_between_spawns
			main.spawn_zombie()
	else:
		main.reset()

# Function to update label text
func update_label():
	ui_label.text = get_state_name()
	# to do: update number of switches in ui

# Function to switch states
func switch_state():
	if current_state == TrafficState.RED_LIGHT:
		current_state = TrafficState.GREEN_LIGHT
	else:
		current_state = TrafficState.RED_LIGHT
	num_switches += 1
	update_label()

# Helper function to get state name
func get_state_name() -> String:
	return "Green Light" if current_state == TrafficState.GREEN_LIGHT else "Red Light"

# Function to check if it's green light
func is_green_light() -> bool:
	return current_state == TrafficState.GREEN_LIGHT

# Function to check if it's red light
func is_red_light() -> bool:
	return current_state == TrafficState.RED_LIGHT
