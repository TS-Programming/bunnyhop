extends Node3D

# Adjustable variables
var detection_radius: float = 5  # Radius within which the collectible will start moving towards the player
var move_speed: float = 12  # Speed at which the collectible moves towards the player
var arc_height: float = 0.2 # Height of the arc

# Internal variables
var is_moving: bool = false
var is_falling: bool = true
var start_position: Vector3
var player_path := "/root/Main2/Map/FpPlayer"
var player_target: Node3D


# New variables for randomness
var random_arc_height_min: float = 0.3
var random_arc_height_max: float = 1.2
var random_angle_variance: float = 2  # Max deviation in radians for side-to-side variance

# Internal variables for trajectory calculation
var side_angle: float = 0.0
var actual_arc_height: float = 2.0

var value: int = 5


# Ready function
func _ready():
	var area = Area3D.new()
	area.collision_layer = 2
	area.collision_mask = 1
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = SphereShape3D.new()
	collision_shape.shape.radius = detection_radius
	area.add_child(collision_shape)
	area.connect("body_entered", Callable(self, "_on_body_entered"))
	add_child(area)
	

# Function to handle when a body enters the detection area
func _on_body_entered(body):
	if LightManager.is_red_light():
		return
	if body.name == "FpPlayer":  # Make sure to replace this with your player's identification logic
		start_moving_towards_player(body)


 #Process function
func start_moving_towards_player(player):
	player_target = get_node(player_path)
	start_position = global_transform.origin

	# Randomize the arc height and side angle
	actual_arc_height = randf_range(random_arc_height_min, random_arc_height_max)
	side_angle = randf_range(-random_angle_variance, random_angle_variance)

	is_moving = true

func _process(delta):
	if is_moving:
		move_towards_player(delta)



func move_towards_player(delta):
	var target_position = player_target.global_transform.origin
	var direction = (target_position - start_position).normalized()
	var horizontal_position = global_transform.origin.lerp(target_position, move_speed * delta)

	var distance_ratio = start_position.distance_to(horizontal_position) / start_position.distance_to(target_position)
	var arc = sin(distance_ratio * PI) * actual_arc_height

	# Calculate side offset
	var side_offset = Vector3(cos(side_angle), 0, sin(side_angle)) * distance_ratio * arc * 0.5

	# Update global position
	global_transform.origin = horizontal_position + Vector3(0, arc, 0) + side_offset

	if global_transform.origin.distance_to(target_position) < 1.0:
		is_moving = false
		collect()

func set_value(amount: int):
	value = amount

# Function to handle collectible pickup
func collect():
	print("collected")
	LootManager.add_funds(value)
	queue_free()  # Remove the collectible from the scene

