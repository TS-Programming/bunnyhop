extends Node3D


@export var Animation_Player: AnimationPlayer
@onready var player = $/root/Main2/Map/FpPlayer


var time_since_last_shot = 0.0

var is_reloading: bool = false


@export var weapon_resources: Array[WeaponResource]
@export var weapon_tier_prices: Array[int] #including base tier for 0

var current_weapon: WeaponResource
var current_weapon_tier: int





func _ready():
	if weapon_resources.size() == 0:
		error_string(1)
	else:
		current_weapon = weapon_resources[0]
		current_weapon_tier = 0



func _process(delta):
	time_since_last_shot += delta
	if !player.fp_input.fire_secondary_pressed:
		flame_particles.emitting = false


func change_weapon_tier(tier: int):
	current_weapon_tier = tier
	current_weapon = weapon_resources[tier]
	

func check_weapon_switch(loot: int):
	if loot > weapon_tier_prices[current_weapon_tier] and current_weapon_tier + 1 < weapon_resources.size():
		if weapon_tier_prices[current_weapon_tier + 1] <= loot:
			change_weapon_tier(current_weapon_tier + 1)
			print("going up")
	elif current_weapon_tier - 1 >= 0:
		if weapon_tier_prices[current_weapon_tier] > loot:
			change_weapon_tier(current_weapon_tier - 1)
			print("going down")
			
func shoot(delta: float):
	if is_reloading:
		return
	if current_weapon.ammo_left_in_mag <= 0:
		reload()
		return
	if current_weapon.primary_is_auto and time_since_last_shot < current_weapon.fire_rate:
		return

	time_since_last_shot = 0.0
	current_weapon.ammo_left_in_mag -= 1
	if !current_weapon.is_shot_gun:
		perform_shoot() 
	else:
		perform_shotgun_shoot()

func secondary_shoot(delta: float):
	if current_weapon.secondary_is_auto and time_since_last_shot >= current_weapon.fire_rate:
		pass
	else:
		return
	if LootManager.spend_funds(3):
		time_since_last_shot = 0.0
		if !current_weapon.secondary_is_continuous:
			perform_shoot() 
		else:
			perform_continuous_shoot()
		

func reload():
	is_reloading = true
	await get_tree().create_timer(current_weapon.reload_time).timeout
	current_weapon.ammo_left_in_mag = current_weapon.mag_size
	is_reloading = false
	
@onready var hitbox = $Weapons/FlameThrower
@onready var flame_particles = $Weapons/FlameParticles

func perform_continuous_shoot():
	var enemies = hitbox.get_overlapping_areas()
	flame_particles.emitting = true
	for e in enemies:
		if e.is_in_group("enemy"):
			e.hit()

var instance

func perform_shoot():
	if !player.fp_camera.auto_anim.is_playing():
		player.fp_camera.auto_anim.play("Shoot")
	instance = current_weapon.bullet_trail.instantiate()
	if player.fp_camera.aim_ray.is_colliding():
		instance.init(player.fp_camera.auto_barrel.global_position,
		 player.fp_camera.aim_ray.get_collision_point())
		player.get_parent().add_child(instance)
		if player.fp_camera.aim_ray.get_collider().is_in_group("enemy"):
			player.fp_camera.aim_ray.get_collider().hit()
			instance.trigger_particles(player.fp_camera.aim_ray.get_collision_point(),
			 player.fp_camera.auto_barrel.global_position, true)
		else:
			instance.trigger_particles(player.fp_camera.aim_ray.get_collision_point(), 
			player.fp_camera.auto_barrel.global_position, false)
	else:
		instance.init(player.fp_camera.auto_barrel.global_position, 
		player.fp_camera.aim_ray_end.global_position)
		player.get_parent().add_child(instance)

var spread = 10

func perform_shotgun_shoot():
	for ray in player.fp_camera.shot_gun_rays.get_children():
		ray.target_position.x = randf_range(spread, -spread)
		ray.target_position.y = randf_range(spread, -spread)
		if !player.fp_camera.auto_anim.is_playing():
			player.fp_camera.auto_anim.play("Shoot")
		instance = current_weapon.bullet_trail.instantiate()
		if ray.is_colliding():
			instance.init(player.fp_camera.auto_barrel.global_position,
			 ray.get_collision_point())
			player.get_parent().add_child(instance)
			if ray.get_collider().is_in_group("enemy"):
				ray.get_collider().hit()
				instance.trigger_particles(ray.get_collision_point(),
				 player.fp_camera.auto_barrel.global_position, true)
			else:
				instance.trigger_particles(ray.get_collision_point(), 
				player.fp_camera.auto_barrel.global_position, false)
		else:
			instance.init(player.fp_camera.auto_barrel.global_position, 
			player.fp_camera.aim_ray_end.global_position)
			player.get_parent().add_child(instance)
			
			
#func perform_shotgun_shoot():
#	var should_pierce = false
#	var pierce_amount = 3
#	for ray in player.fp_camera.shot_gun_rays.get_children():
#		ray.target_position.x = randf_range(spread, -spread)
#		ray.target_position.y = randf_range(spread, -spread)
#
#		if !player.fp_camera.auto_anim.is_playing():
#			player.fp_camera.auto_anim.play("Shoot")
#
#		var ray_start = player.fp_camera.auto_barrel.global_position
#		var ray_end = player.fp_camera.aim_ray_end.global_position
#		var space_state = get_world_3d().direct_space_state
#		var max_distance = 200
#
#		while ray_start.distance_to(ray_end) < max_distance:
#			print("kjdsbfhjkdfs")
#			var params = PhysicsRayQueryParameters3D.new()
#			params.from = ray_start
#			params.to = ray_end
#			params.exclude = []  # Add any exclusions if needed
#			#params.collision_mask = 2  # Set appropriate mask
#
#			var result = space_state.intersect_ray(params)
#			if result.is_empty():
#				break  # No further collisions, exit loop
#
#			# Instantiate bullet trail per collision
#			var instance = current_weapon.bullet_trail.instantiate()
#			instance.init(ray_start, result.position)
#			player.get_parent().add_child(instance)
#
#			if result.collider.is_in_group("enemy"):
#				result.collider.hit()  # Apply effects like damage
#				instance.trigger_particles(result.position, ray_start, true)
#				if pierce_amount > 0:
#					should_pierce = true
#					pierce_amount -= 1
#				else: 
#					should_pierce = false
#			else:
#				instance.trigger_particles(result.position, ray_start, false)
#				should_pierce = false
#
#			# Check if the ray should pierce this object
#			if should_pierce:
#				# Move ray start just beyond the collision point
#				ray_start = result.position + result.normal * 0.01
#			else:
#				break  # Hit non-piercing object, exit loop








