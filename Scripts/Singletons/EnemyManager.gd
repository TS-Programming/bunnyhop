extends Node

@onready var spawns = $Map/Spawns
@onready var navigation_region = $Map/NavigationRegion3D

var zombie = preload("res://Scenes/Zombie.tscn")
var spawn_point_queue = []
var cooldown_queue = []

var time_left_to_next_spawn: float = 1.0
var time_between_spawns: float = 3.0

func _ready():
	LightManager.enemy_manager_synch()
	initialize_queue()
	
func _process(delta):
	if LightManager.is_green_light():
		time_left_to_next_spawn -= delta
	if time_left_to_next_spawn - LightManager.num_switches * 0.05 <= 0:
		time_left_to_next_spawn = time_between_spawns
		spawn_zombie()
	else:
		reset()

func initialize_queue():
	for i in range(spawns.get_child_count()):
		spawn_point_queue.append(spawns.get_child(i))

func spawn_zombie():
	if spawn_point_queue.size() == 0:
		print("No available spawn points")
		return

	var spawn_point_node = spawn_point_queue.pop_front()
	var spawn_point = spawn_point_node.global_position
	var instance = zombie.instantiate()
	instance.position = spawn_point
	instance.visible = false
	instance.zombie_hit.connect(_on_enemy_hit)
	navigation_region.add_child(instance)

	cooldown_queue.append(spawn_point_node)



func _on_enemy_hit():
	print("Replace this print with a signal for zombie on hit")

# Resets the queue by moving all items from the cooldown queue back to the main queue
func reset():
	while cooldown_queue.size() > 0:
		var spawn_point_node = cooldown_queue.pop_front()
		spawn_point_queue.append(spawn_point_node)




#extends Node
#
#@onready var spawns = $Map/Spawns
#@onready var navigation_region = $Map/NavigationRegion3D
#
#
#var zombie = load("res://Scenes/Zombie.tscn")
#var instance
#
#func _ready():
#	LightManager.enemy_manager_synch()
#
#
#func _get_random_child(parent_node):
#	var random_id = randi() % parent_node.get_child_count()
#	return parent_node.get_child(random_id)
#
#func spawn_zombie():
#	var spawn_point = _get_random_child(spawns).global_position
#	instance = zombie.instantiate()
#	instance.position = spawn_point
#	instance.visible = false
#	instance.zombie_hit.connect(_on_enemy_hit)
#	navigation_region.add_child(instance)
#
#func _on_enemy_hit():
#	print("Replace this print with a signal for zombie on hit")
