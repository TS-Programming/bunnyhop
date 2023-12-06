class_name FpMovement
extends Node

@export var gravity: float = 10.0
@export var gravity_modifier: float = 1.0
@export var speed_ground_max: float = 8.0
var speed_ground_max_modifier: float = 1.0
@export var speed_air_max: float = 8.0
var speed_air_max_modifier: float = 1.0
@export var speed_jump: float = 4.2
var speed_jump_modifier: float = 1.0

@export var accel_ground_max: float = 140.0
var accel_ground_max_modifier: float = 1.0
@export var accel_air_max: float = 70.0
var accel_air_max_modifier: float = 1.0

@export var friction_ground: float = 12.0
var friction_ground_modifier: float = 1.0
@export var friction_air: float = 0.1
var friction_air_modifier: float = 1.0

@export var floor_angle := 40.0 # (float, 0.0, 90.0)
@export var snap_to_floor: float = 0.1
var snap_to_floor_modifier: float = 1.0

@export var step_distance: float = 3.0

var time: float = 0.0

var move_direction: Vector3
var velocity: Vector3

# needed for ui
var projection: float
var velocity_move_direction_angle: float

var contact_normals: Array
var contact_points: Array

var top_speed: float = 0.0

var dash_speed: float = 20.0  # Adjust the dash speed as needed
var dash_duration: float = 0.25  # Duration of the dash in seconds
var dash_elapsed: float = 0.0  # Time elapsed since the dash started
var dashing: bool = false  # Flag to indicate if a dash is currently happening
var dash_vector: Vector3 = Vector3.ZERO
var floating: bool = false
var float_duration: float = 3.0  # Duration of the dash in seconds
var float_elapsed: float = 3.0  # Time elapsed since the dash started
var numDashes: int = 0
var isDashCharged: bool = true

func get_velocity() -> float:
	return velocity.length()

func get_hspeed() -> float:
	return (velocity - velocity.project(Vector3.UP)).length()

func get_vspeed() -> float:
	return velocity.project(Vector3.UP).length()

func accelerate(_velocity: Vector3, speed_max: float, accel_max: float, delta: float) -> Vector3:
	#print(move_direction.length())
	#print(_velocity.length())
	projection = _velocity.dot(move_direction)
	velocity_move_direction_angle = _velocity.angle_to(move_direction)
	var add_speed : float = clamp(speed_max - projection, 0.0, accel_max * delta)
	_velocity += add_speed * move_direction
	return _velocity

func friction(_velocity: Vector3, friction: float, _speed_stop: float, delta: float) -> Vector3:
	var speed := _velocity.length()
	if speed != 0.0:
		var control : float = max(_speed_stop, speed)
		var drop := control * friction * delta
		#print(drop)
		_velocity *= max(speed - drop, 0.0) / speed
	return _velocity

func movement_floor(player: FpPlayer, delta: float) -> void:
	var fp_input: FpInput = player.fp_input
	var floor_normal: Vector3 = player.get_floor_normal()
	# friction along floor
	var vel_perp_ground := velocity.project(floor_normal)
	var vel_along_ground := velocity - vel_perp_ground
	vel_along_ground = friction(vel_along_ground, friction_ground_modifier * friction_ground, 1.5, delta)
	# set velocity perpendicular to ground as 0
	vel_perp_ground = Vector3.ZERO
	velocity = vel_along_ground + vel_perp_ground

	# accelaerate along horizontal
	var vvel := velocity.project(Vector3.UP)
	var hvel := velocity - vvel
	hvel = accelerate(hvel, speed_ground_max_modifier * speed_ground_max, accel_ground_max_modifier * accel_ground_max, delta)

	if fp_input.queue_jump:
		vvel.y = speed_jump_modifier * speed_jump
		velocity = hvel + vvel
		player.set_velocity(velocity)
		player.set_up_direction(Vector3.UP)
		player.set_floor_stop_on_slope_enabled(true)
		player.set_max_slides(4)
		player.set_floor_max_angle(deg_to_rad(floor_angle))
		# TODOConverter3To4 infinite_inertia were removed in Godot 4 - previous value `false`
		player.move_and_slide()
		velocity = player.velocity
	else:
		velocity = hvel + vvel
		player.set_velocity(velocity)
		# TODOConverter3To4 looks that snap in Godot 4 is float, not vector like in Godot 3 - previous value `-floor_normal * snap_to_floor * snap_to_floor_modifier`
		player.set_up_direction(Vector3.UP)
		player.set_floor_stop_on_slope_enabled(true)
		player.set_max_slides(4)
		player.set_floor_max_angle(deg_to_rad(floor_angle))
		# TODOConverter3To4 infinite_inertia were removed in Godot 4 - previous value `false`
		player.move_and_slide()
		velocity = player.velocity
		
		
func movement_float(player: FpPlayer, delta: float) -> void:
	var fp_input: FpInput = player.fp_input

	# Horizontal movement: Apply friction and acceleration
	# Since there's no ground, use the entire velocity vector for friction
	var hvel := friction(velocity, friction_ground_modifier * friction_ground, 1.5, delta)

	# Apply acceleration based on input, similar to movement_floor
	hvel = accelerate(hvel, speed_ground_max_modifier * speed_ground_max, accel_ground_max_modifier * accel_ground_max, delta)

	var vvel := Vector3.ZERO  # Zero vertical velocity
	
	if fp_input.queue_jump:
		vvel.y = speed_jump_modifier * speed_jump
		velocity = hvel + vvel
		player.set_velocity(velocity)
		player.set_up_direction(Vector3.UP)
		player.set_floor_stop_on_slope_enabled(true)
		player.set_max_slides(4)
		player.set_floor_max_angle(deg_to_rad(floor_angle))
		float_elapsed = -1.0

	# Combine horizontal and zero vertical velocities
	velocity = hvel + vvel

	# Apply the velocity to the player
	player.set_velocity(velocity)
	player.move_and_slide()
	velocity = player.velocity
	
	
	float_elapsed -= delta
	print(float_elapsed)
	if float_elapsed < 0 || !player.fp_input.action_float_pressed:
		floating = false;


func movement_air(player: FpPlayer, delta: float) -> void:
	if player.fp_input.action_float_pressed && float_elapsed > 0:
		floating = true
		movement_float(player, delta)
		return
	
	#var fp_input: FpInput = player.fp_input
	var vvel := velocity.project(Vector3.UP)
	var hvel := velocity - vvel
	velocity = friction(velocity, friction_air_modifier * friction_air, 0.0, delta)
	hvel = accelerate(hvel, speed_air_max_modifier * speed_air_max, accel_air_max_modifier * accel_air_max, delta)

	#if fp_input.input_jump and time - time_since_on_floor <= time_coyote_jump:
	#	vvel.y = speed_jump_modifier * speed_jump
	
	velocity = hvel + vvel
	velocity += Vector3.DOWN * gravity * gravity_modifier * delta
	player.set_velocity(velocity)
	player.set_up_direction(Vector3.UP)
	player.set_floor_stop_on_slope_enabled(true)
	player.set_max_slides(4)
	player.set_floor_max_angle(deg_to_rad(floor_angle))
	# TODOConverter3To4 infinite_inertia were removed in Godot 4 - previous value `false`
	player.move_and_slide()
	velocity = player.velocity
	

func initiate_dash(player: FpPlayer) -> void:
	var fp_cam_basis: Basis = player.fp_camera.get_camera_basis()
	var move_direction = -fp_cam_basis.z.normalized()
	#print(move_direction)
	
	velocity = Vector3.ZERO
	player.set_velocity(velocity)
	
	dash_vector = move_direction * dash_speed
	dash_elapsed = 0.0
	dashing = true
	numDashes -= 1
	if numDashes <= 0:
		isDashCharged = false

func process_dash(player: FpPlayer, delta: float) -> void:
	if dashing:
		dash_elapsed += delta
		if dash_elapsed < dash_duration:
			# Apply a portion of the dash velocity
			velocity = dash_vector
			player.set_velocity(velocity)
			player.move_and_slide()
		else:
			# Dash has completed
			velocity = Vector3.ZERO
			player.set_velocity(velocity)
			dashing = false
			start_dash_timer(2)

func start_dash_timer(time: float):
	await get_tree().create_timer(time).timeout
	isDashCharged = true
	



func update_movement(player: FpPlayer, delta: float) -> void:
	#print(velocity.length())
	time += delta
	
	var fp_cam_hbasis: Basis = player.fp_camera.get_hbasis()
	var fp_input: FpInput = player.fp_input
	move_direction = fp_cam_hbasis.x * fp_input.input_move.x + fp_cam_hbasis.z * fp_input.input_move.z
	move_direction = move_direction.normalized()
	
	if fp_input.queue_dash and numDashes > 0 and isDashCharged:
		initiate_dash(player)
		process_dash(player, delta)
	else: if dashing:
		process_dash(player, delta)
	else: if player.is_on_floor():
		
		numDashes = 1
		float_elapsed = float_duration
		movement_floor(player, delta)
	else: if floating:
		movement_float(player, delta)
	else:
		movement_air(player, delta)
		
	if fp_input.fire_primary_pressed:
		_shoot_auto(player)
		
	
	var speed: float = velocity.length()
	if speed > top_speed:
		top_speed = speed
	
	#print(velocity.length())
	contact_normals = []
	contact_points = []
	for idx in player.get_slide_collision_count():
		var coll := player.get_slide_collision(idx)
		var n : Vector3 = coll.get_normal()
		var p : Vector3 = coll.get_position()
		contact_normals.append(n)
		contact_points.append(p)
		if coll.get_collider() is RigidBody3D:
			var obj: RigidBody3D = coll.get_collider()
			var imp: Vector3 = -n * 1.0
			obj.set_sleeping(false)
			obj.apply_impulse(imp, p - obj.global_transform.origin)
			
			


func on_hit(damage: int, direction: Vector3):
	print(direction)
	velocity += direction




#shooting stuff below
var bullet = load("res://Scenes/Bullet.tscn")
var bullet_trail = load("res://Scenes/BulletTrail.tscn")
var instance


# Guns
#@onready var gun_anim2 = $Head/Camera3D/Rifle2/AnimationPlayer
#@onready var gun_barrel2 = $Head/Camera3D/Rifle2/RayCast3D
#@onready var auto_anim = $Head/Camera3D/SteampunkAuto/AnimationPlayer
#@onready var auto_barrel = $Head/Camera3D/SteampunkAuto/Meshes/Barrel

func _shoot_pistols(player: FpPlayer):
	if !player.fp_camera.gun_anim.is_playing():
		player.fp_camera.gun_anim.play("Shoot")
		instance = bullet.instantiate()
		instance.position = player.fp_camera.gun_barrel.global_position
		player.get_parent().add_child(instance)
		if player.fp_camera.aim_ray.is_colliding():
			instance.set_velocity(player.fp_camera.aim_ray.get_collision_point())
		else:
			instance.set_velocity(player.fp_camera.aim_ray_end.global_position)
#	if !gun_anim2.is_playing():
#		gun_anim2.play("Shoot")
#		instance = bullet.instantiate()
#		instance.position = gun_barrel2.global_position
#		get_parent().add_child(instance)
#		if aim_ray.is_colliding():
#			instance.set_velocity(aim_ray.get_collision_point())
#		else:
#			instance.set_velocity(aim_ray_end.global_position)


func _shoot_auto(player: FpPlayer):
	if !player.fp_camera.auto_anim.is_playing():
		player.fp_camera.auto_anim.play("Shoot")
		instance = bullet_trail.instantiate()
		if player.fp_camera.aim_ray.is_colliding():
			instance.init(player.fp_camera.auto_barrel.global_position, player.fp_camera.aim_ray.get_collision_point())
			player.get_parent().add_child(instance)
			print(player.fp_camera.aim_ray.get_collider().name)
			if player.fp_camera.aim_ray.get_collider().is_in_group("enemy"):
				print("hoooot")
				player.fp_camera.aim_ray.get_collider().hit()
				instance.trigger_particles(player.fp_camera.aim_ray.get_collision_point(),
											player.fp_camera.auto_barrel.global_position, true)
			else:
				instance.trigger_particles(player.fp_camera.aim_ray.get_collision_point(),
											player.fp_camera.auto_barrel.global_position, false)
		else:
			instance.init(player.fp_camera.auto_barrel.global_position, player.fp_camera.aim_ray_end.global_position)
			player.get_parent().add_child(instance)
