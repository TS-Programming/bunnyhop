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

## Variables for initial upward movement
#var initial_upward_speed: float = 5
#var initial_upward_speed_randomness: float = 2.0
#
## New internal variable
#var initial_velocity: Vector3 = Vector3.ZERO
#
#
## Variables for delaying ground check
#var ground_check_delay: float = 0.5  # Delay in seconds
#var ground_check_timer: float = 0.0  # Timer to track delay
#
#var raycast: RayCast3D
#
## Variables for initial arc movement
#var peak_height: float = 3.0
#var to_peak_duration: float = 0.5
#var elapsed_time: float = 0.0
#var peak_position: Vector3
#
#var flag: bool = false
#
## New variables for initial direction
#var initial_direction_variance: float = 1.0  # How much the initial direction can vary

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
	
	
#	# Add and configure RayCast3D for ground check
#	raycast = RayCast3D.new()
#	add_child(raycast)
#	raycast.enabled = true
#	raycast.target_position = Vector3(0, -0.3, 0)  # Adjust the length as needed
#	raycast.collision_mask = 4  # Assuming layer 3 is represented by bit 4
#
#	# Initialize delay timer
#	ground_check_timer = ground_check_delay
#
#	# Calculate peak position
#	peak_position = global_transform.origin + Vector3(0, peak_height, 0)
#
#	# Calculate a random initial direction
#	var random_x = randf_range(-initial_direction_variance, initial_direction_variance)
#	var random_z = randf_range(-initial_direction_variance, initial_direction_variance)
#	var initial_direction = Vector3(random_x, 1, random_z).normalized()

	# Calculate peak position based on this direction
	

# Function to handle when a body enters the detection area
func _on_body_entered(body):
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
#	if is_falling:
#		handle_falling(delta)
	if is_moving:
		move_towards_player(delta)

#func handle_falling(delta):
#	if ground_check_timer > 0:
#		ground_check_timer -= delta
#	if elapsed_time < to_peak_duration:
#		elapsed_time += delta
#		var lerp_factor = elapsed_time / to_peak_duration
#		global_transform.origin = global_transform.origin.lerp(peak_position, lerp_factor)
#	else:
#
#		initial_velocity.y -= 9.8 * delta
#		global_transform.origin += initial_velocity * delta
#		if raycast.is_colliding() and ground_check_timer <= 0:
#			initial_velocity = Vector3.ZERO
#			is_falling = false

#func handle_falling(delta):
#	if ground_check_timer > 0:
#		ground_check_timer -= delta
#	if elapsed_time < to_peak_duration:
#		elapsed_time += delta
#		var lerp_factor = elapsed_time / to_peak_duration
#		global_transform.origin = global_transform.origin.lerp(peak_position, lerp_factor)
#	else:
#		if raycast.is_colliding() and ground_check_timer <= 0:
#			initial_velocity = Vector3.ZERO
#			is_falling = false
#		else:
#			# Calculate target ground position
#			var ground_position = peak_position
#			ground_position.y = 0  # Assuming ground is at y = 0
#
#			# Lerp towards ground position
#			var ground_lerp_factor = min(1.0, elapsed_time / to_peak_duration)
#			var horizontal_position = global_transform.origin.lerp(ground_position, ground_lerp_factor)
#
#			# Apply arc effect
#			var arc = sin(ground_lerp_factor * PI) * actual_arc_height
#
#			# Update global position with arc effect
#			global_transform.origin = horizontal_position + Vector3(0, arc, 0)
#
#			elapsed_time += delta


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

#func _process(delta):
#
#	if is_falling:
#		if ground_check_timer > 0:
#			ground_check_timer -= delta  # Decrement timer
#		if elapsed_time < to_peak_duration:
#			elapsed_time += delta
#			var lerp_factor = elapsed_time / to_peak_duration
#			global_transform.origin = global_transform.origin.lerp(peak_position, lerp_factor)
#		else:
#			# Normal falling logic
#			initial_velocity.y -= 9.8 * delta
#			global_transform.origin += initial_velocity * delta
#			if raycast.is_colliding() and ground_check_timer < 0:
#				initial_velocity = Vector3.ZERO
#				is_falling = false
#
#	if is_moving:
#		var target_position = player_target.global_transform.origin
#		var direction = (target_position - start_position).normalized()
#		var horizontal_position = global_transform.origin.lerp(target_position, move_speed * delta)
#
#		var distance_ratio = start_position.distance_to(horizontal_position) / start_position.distance_to(target_position)
#		var arc = sin(distance_ratio * PI) * actual_arc_height
#
#		# Calculate side offset based on the side angle and distance ratio
#		var side_offset = Vector3(cos(side_angle), 0, sin(side_angle)) * distance_ratio * arc * 0.5  # Adjust the multiplier as needed
#
#		# Update global position with horizontal movement, arc, and side offset
#		global_transform.origin = horizontal_position + Vector3(0, arc, 0) + side_offset
#
#		if global_transform.origin.distance_to(target_position) < 1.0:  # Threshold to consider as 'reached'
#			is_moving = false
#			collect()  # Handle the collectible being collected

		


# Function to handle collectible pickup
func collect():
	# Implement collectible pickup logic here (e.g., increment score, play sound)
	print("collected")
	queue_free()  # Remove the collectible from the scene

