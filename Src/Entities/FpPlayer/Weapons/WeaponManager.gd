extends Node3D

signal Weapon_Changed
signal Update_Ammo
signal Update_WeaponStack
signal Hit_Successfull
signal Add_Signal_To_HUD

signal Spray_Rotation
signal Shake_Screen
signal Reset_Spray
signal Connect_Weapon_To_HUD
signal Connect_Weapon_To_Camera

@export var Animation_Player: AnimationPlayer
@onready var player = $/root/Main2/Map/FpPlayer
#@onready var Bullet_Point = get_node("%BulletPoint")
#@onready var Debug_Bullet = preload("res://Player_Controller/Spawnable_Objects/hit_debug.tscn")


var Melee_Shake:= Vector3(0,0,2.5)
var Melee_Shake_Magnetude:= Vector4(1,1,1,1)

#var Secondary_Mode = false

var Current_Weapon = null

var WeaponStack = [] #An Array of weapons currently in possesion by the player

#var WeaponIndicator = 0
var Next_Weapon: String

#WEAPON TYPE ENUMERATOR TO HELP WITH CODE READABILITY
enum {NULL,HITSCAN, PROJECTILE}

var Collision_Exclusion: Array

#The List of All Available weapons in the game
var Weapons_List = {
}

#An Array of weapon resources to make dictionary creation easier
@export var _weapon_resources: Array[WeaponResource]

@export var Start_Weapons: Array[String]

func _ready():
	print("weapon manager ready")
#	Animation_Player.animation_finished.connect(_on_animation_finished)
#	Initialize(Start_Weapons) #current starts on the first weapon in the stack

#func _input(event):
#	if event.is_action_pressed("WeaponUp"):
#		var GetRef = WeaponStack.find(Current_Weapon.Weapon_Name)
#		GetRef = min(GetRef+1,WeaponStack.size()-1)
#
#		exit(WeaponStack[GetRef])
#
#	if event.is_action_pressed("WeaponDown"):
#		var GetRef = WeaponStack.find(Current_Weapon.Weapon_Name)
#		GetRef = max(GetRef-1,0)
#
#		exit(WeaponStack[GetRef])
#
#	if event.is_action_pressed("Secondary_Fire"):
#		secondary()
#
#	if event.is_action_released("Secondary_Fire"):
#		reset_secondary()
#
#	if event.is_action_pressed("Shoot"):
#		shoot()
#
#	if event.is_action_released("Shoot"):
#		Current_Weapon.Spray_Count_Update()
#
#	if event.is_action_pressed("Reload"):
#		reload()
#
#	if event.is_action_pressed("Drop_Weapon"):
#		drop(Current_Weapon.Weapon_Name)
#
#	if event.is_action_pressed("Melee"):
#		melee()



		
#func Initialize(_Start_Weapons: Array):
#	for Weapons in _weapon_resources:
#		Weapons.ready()
#		Weapons_List[Weapons.Weapon_Name] = Weapons
#		Connect_Weapon_To_HUD.emit(Weapons)
#		Connect_Weapon_To_Camera.emit(Weapons)
#
#	for child in _Start_Weapons:
#		WeaponStack.push_back(child)
#
#	Current_Weapon = Weapons_List[WeaponStack[0]]
#
#	Update_WeaponStack.emit(WeaponStack)
#	enter()
#
#func enter():
#	Animation_Player.queue(Current_Weapon.Pick_Up_Anim)
#	Current_Weapon.Spray_Count_Update()
#	Weapon_Changed.emit(Current_Weapon.Weapon_Name)
#	Update_Ammo.emit([Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
#
#func exit(_next_weapon: String):
#	if _next_weapon != Current_Weapon.Weapon_Name:
#		if Animation_Player.get_current_animation() != Current_Weapon.Change_Anim:
#			if Current_Weapon.Secondary_Mode == true:
#				reset_secondary()
#			Animation_Player.queue(Current_Weapon.Change_Anim)
#			Next_Weapon = _next_weapon
#
#func Change_Weapon(weapon_name: String):
#	Current_Weapon = Weapons_List[weapon_name]
#	Next_Weapon = ""
#	enter()

# Variables for managing fire rate
var time_since_last_shot = 0.0
var fire_rate = 0.07  # Example fire rate (in seconds)

func _process(delta):
	time_since_last_shot += delta

var bullet = load("res://Scenes/Bullet.tscn")
var bullet_trail = load("res://Scenes/BulletTrail.tscn")
var instance
var ammo_left_in_mag: int = 6
var mag_size: int = 6
var is_reloading: bool = false
var reload_time: float = 0.8

# New function to handle the shooting mechanism.
# `is_auto` could be a boolean indicating if the shooting mode is automatic.
func perform_shoot():
	if !player.fp_camera.auto_anim.is_playing():
		player.fp_camera.auto_anim.play("Shoot")
		instance = bullet_trail.instantiate()
		if player.fp_camera.aim_ray.is_colliding():
			instance.init(player.fp_camera.auto_barrel.global_position, player.fp_camera.aim_ray.get_collision_point())
			player.get_parent().add_child(instance)
			if player.fp_camera.aim_ray.get_collider().is_in_group("enemy"):
				player.fp_camera.aim_ray.get_collider().hit()
				instance.trigger_particles(player.fp_camera.aim_ray.get_collision_point(), player.fp_camera.auto_barrel.global_position, true)
			else:
				instance.trigger_particles(player.fp_camera.aim_ray.get_collision_point(), player.fp_camera.auto_barrel.global_position, false)
	else:
		print(player.fp_camera.auto_barrel.global_position)
		print(player.fp_camera.aim_ray_end.global_position)
		instance.init(player.fp_camera.auto_barrel.global_position, player.fp_camera.aim_ray_end.global_position)
		player.get_parent().add_child(instance)

# Modified shoot function
func shoot(is_auto: bool):
	if is_reloading:
		return
	if ammo_left_in_mag <= 0:
		reload()
		return
	if is_auto and time_since_last_shot < fire_rate:
		return

	time_since_last_shot = 0.0
	ammo_left_in_mag -= 1
	perform_shoot()  # Call the new function with appropriate mode

# Modified secondary shoot function
func secondary_shoot(is_auto: bool, cost: int):
	if is_auto and time_since_last_shot >= fire_rate:
		pass
	else:
		return
	if LootManager.spend_funds(cost):
		time_since_last_shot = 0.0
		perform_shoot()  # Call the new function with appropriate mode

func reload():
	is_reloading = true
	await get_tree().create_timer(reload_time).timeout
	ammo_left_in_mag = mag_size
	is_reloading = false
	

#func shoot():
#	if !player.fp_camera.auto_anim.is_playing():
#		player.fp_camera.auto_anim.play("Shoot")
#		instance = bullet_trail.instantiate()
#		if player.fp_camera.aim_ray.is_colliding():
#			instance.init(player.fp_camera.auto_barrel.global_position, player.fp_camera.aim_ray.get_collision_point())
#			player.get_parent().add_child(instance)
#			if player.fp_camera.aim_ray.get_collider().is_in_group("enemy"):
#				player.fp_camera.aim_ray.get_collider().hit()
#				instance.trigger_particles(player.fp_camera.aim_ray.get_collision_point(),
#											player.fp_camera.auto_barrel.global_position, true)
#			else:
#				instance.trigger_particles(player.fp_camera.aim_ray.get_collision_point(),
#											player.fp_camera.auto_barrel.global_position, false)
#	else:
#		instance.init(player.fp_camera.auto_barrel.global_position, player.fp_camera.aim_ray_end.global_position)
#		player.get_parent().add_child(instance)
#
#func secondary_shoot():
#	if !player.fp_camera.auto_anim.is_playing():
#		player.fp_camera.auto_anim.play("Shoot")
#		instance = bullet_trail.instantiate()
#		if player.fp_camera.aim_ray.is_colliding():
#			instance.init(player.fp_camera.auto_barrel.global_position, player.fp_camera.aim_ray.get_collision_point())
#			player.get_parent().add_child(instance)
#			if player.fp_camera.aim_ray.get_collider().is_in_group("enemy"):
#				player.fp_camera.aim_ray.get_collider().hit()
#				instance.trigger_particles(player.fp_camera.aim_ray.get_collision_point(),
#											player.fp_camera.auto_barrel.global_position, true)
#			else:
#				instance.trigger_particles(player.fp_camera.aim_ray.get_collision_point(),
#											player.fp_camera.auto_barrel.global_position, false)
#	else:
#		instance.init(player.fp_camera.auto_barrel.global_position, player.fp_camera.aim_ray_end.global_position)
#		player.get_parent().add_child(instance)


		
		
#func Secondary_Shoot(secondary_resource):
#	if secondary_resource.Ammo != 0:
#		secondary_resource.Ammo  -= 1
#		var CollissionPoint =  GetCameraCollision(Current_Weapon.Fire_Range)
#		match secondary_resource.Fire_Type:
#			"Hitscan":
#				HitScanCollision(CollissionPoint)
#			"Projectile":
#				LaunchProjectile(CollissionPoint[1])
#		Reset_Spray.emit()
#	reset_secondary()
	
	
#	if Current_Weapon.Current_Ammo != 0:
#		if not Animation_Player.is_playing():
#			Animation_Player.play(Current_Weapon.Shoot_Anim)
#			Current_Weapon.Current_Ammo -= 1
#			Update_Ammo.emit([Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
#			var Camera_Collission =  GetCameraCollision(Current_Weapon.Fire_Range)
#			match Current_Weapon.Type:
#				NULL:
#					pass
#				HITSCAN:
#					HitScanCollision(Camera_Collission)
#				PROJECTILE:
#					LaunchProjectile(Camera_Collission[1])
#	else:
#		reload()



#	if Current_Weapon.Current_Ammo == Current_Weapon.Magazine:
#		return
#	elif not Animation_Player.is_playing():
#
#		if Current_Weapon.Reserve_Ammo != 0:		
#			if Current_Weapon.Secondary_Mode == true:
#				reset_secondary()
#
#			Animation_Player.queue(Current_Weapon.Reload_Anim)
#
#		else:
#			Animation_Player.queue(Current_Weapon.Out_Of_Ammo_Anim)

func Calculate_Reload():
	var Reload_Amount = min(Current_Weapon.Magazine-Current_Weapon.Current_Ammo,Current_Weapon.Magazine,Current_Weapon.Reserve_Ammo)

	Current_Weapon.Current_Ammo = Current_Weapon.Current_Ammo+Reload_Amount
	Current_Weapon.Reserve_Ammo = Current_Weapon.Reserve_Ammo-Reload_Amount
	Current_Weapon.Spray_Count_Update()
	
	Update_Ammo.emit([Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])


#func melee():
#	if Current_Weapon.Secondary_Mode:
#		reset_secondary()
#
#	var Current_Anim = Animation_Player.get_current_animation()
#
#	if Current_Anim == Current_Weapon.Shoot_Anim:
#		return
#
#	if Current_Anim != Current_Weapon.Melee_Anim:
#		Animation_Player.play(Current_Weapon.Melee_Anim)
#		var Camera_Collission =  GetCameraCollision(2)
#		Shake_Screen.emit(Melee_Shake,Melee_Shake_Magnetude)
#		if Camera_Collission[0]:
#			var Direction = (Camera_Collission[1] - owner.global_transform.origin).normalized()
#			HitScanDamage(Camera_Collission[0],Direction,Camera_Collission[1], Current_Weapon.Melee_Damage)
			
#func drop(_name: String):
#	if Weapons_List[_name].Can_Be_Dropped and WeaponStack.size() != 1:
#		var Weapon_Ref = WeaponStack.find(_name,0)
#		if Weapon_Ref != -1:
#			WeaponStack.pop_at(Weapon_Ref)
#			Update_WeaponStack.emit(WeaponStack)
#
#			if Weapons_List[_name].Weapon_Drop:
#				var Weapon_Dropped = Weapons_List[_name].Weapon_Drop.instantiate()
#				Weapon_Dropped._current_ammo = Weapons_List[_name].Current_Ammo
#				Weapon_Dropped._reserve_ammo = Weapons_List[_name].Reserve_Ammo
#
#				Weapon_Dropped.set_global_transform(Bullet_Point.get_global_transform())
#				get_tree().get_root().add_child(Weapon_Dropped)
#
#				Animation_Player.play(Current_Weapon.Drop_Anim)
#				Weapon_Ref  = max(Weapon_Ref-1,0)
#				exit(WeaponStack[Weapon_Ref])
#	else:
#		return
		
#func _on_animation_finished(anim_name):
#	if anim_name == Current_Weapon.Shoot_Anim:
#		if Current_Weapon.AutoFire == true:
#				if Input.is_action_pressed("Shoot"):
#					if Current_Weapon.Current_Ammo == 0:
#						Reset_Spray.emit()
#					shoot()
#
#				else:
#					Reset_Spray.emit()
#		else:
#			Reset_Spray.emit()
#
#	if anim_name == Current_Weapon.Change_Anim:
#		Change_Weapon(Next_Weapon)
#
#	if anim_name == Current_Weapon.Reload_Anim:
#		Calculate_Reload()
#
#	CheckSecondaryMode()
	
#func CheckSecondaryMode():	
#	if Current_Weapon.Secondary_Mode == true:
#		if !Input.is_action_pressed("Secondary_Fire"):
#			reset_secondary()	
#
#func secondary():
#	if Current_Weapon.Secondary_Fire_Resource:
#		if not Animation_Player.is_playing():
#			Current_Weapon.Secondary_Fire()
#
#			if Current_Weapon.Secondary_Fire_Resource.Secondary_Fire_Shoot:
#				Secondary_Shoot(Current_Weapon.Secondary_Fire_Resource)
#
#			Animation_Player.play(Current_Weapon.Secondary_Fire_Resource.Seconday_Fire_Animation)
#
#func reset_secondary():
#	if Current_Weapon.Secondary_Fire_Resource:
#		if Current_Weapon.Secondary_Mode:
#			if not Animation_Player.is_playing():
#				Current_Weapon.Secondary_Fire_Released()
#				if Current_Weapon.Secondary_Fire_Resource.Seconday_Fire_Animation_Reset:
#					Animation_Player.play(Current_Weapon.Secondary_Fire_Resource.Seconday_Fire_Animation_Reset)



#func GetCameraCollision(_fire_range: int)->Array:
#	var _Camera = get_viewport().get_camera_3d()
#	var _Viewport = get_viewport().get_size()
#
#	var Spray = Current_Weapon.Get_Spray()
#	Spray_Rotation.emit(Spray, Current_Weapon.x_Magnetude,Current_Weapon.y_Magnetude,Current_Weapon.z_Magnetude,Current_Weapon.Base_Magnetude,Current_Weapon.count)
#
#	if Current_Weapon.Secondary_Mode == true:
#		Spray = Vector2.ZERO
#
#	var Ray_Origin = _Camera.project_ray_origin(_Viewport/2)
#	var Ray_End = (Ray_Origin + _Camera.project_ray_normal((_Viewport/2)+Vector2i(Spray))*_fire_range)
#
#	var New_Intersection = PhysicsRayQueryParameters3D.create(Ray_Origin,Ray_End)
#	New_Intersection.set_exclude(Collision_Exclusion)
#	New_Intersection.set_collision_mask(0b1011111)
#	New_Intersection.set_collide_with_areas(true)
#	var Intersection = get_world_3d().direct_space_state.intersect_ray(New_Intersection)
#
#	if not Intersection.is_empty():
#		var Collision = [Intersection.collider,Intersection.position]
#		var rd = Debug_Bullet.instantiate()
#		var world = get_tree().get_root()
#		world.add_child(rd)
#		rd.global_translate(Intersection.position)
#		return Collision
#	else:
#		return [null,Ray_End]

#func HitScanCollision(Collision: Array):
#	var Point = Collision[1]
#	if Collision[0]:
#		if Collision[0].is_in_group("Target"):
#			var Bullet = get_world_3d().direct_space_state
#
#			var Bullet_Direction = (Point - Bullet_Point.global_transform.origin).normalized()
#			var New_Intersection = PhysicsRayQueryParameters3D.create(Bullet_Point.global_transform.origin,Point+Bullet_Direction*2)
#			New_Intersection.set_collide_with_areas(true)
#			var Bullet_Collision = Bullet.intersect_ray(New_Intersection)
#
#			if Bullet_Collision:
#				HitScanDamage(Bullet_Collision.collider, Bullet_Direction,Bullet_Collision.position,Current_Weapon.Damage)
#
#func HitScanDamage(Collider, Direction, Position, Damage):
#	if Collider.is_in_group("Target") and Collider.has_method("Hit_Successful"):
#		Hit_Successfull.emit()
#		Collider.Hit_Successful(Damage, Direction, Position)
#
#func LaunchProjectile(Point: Vector3):
#	var Direction = (Point - Bullet_Point.global_transform.origin).normalized()
#	var Projectile = Current_Weapon.Projectile_To_Load.instantiate()
#
#	Bullet_Point.add_child(Projectile)
#	Add_Signal_To_HUD.emit(Projectile)
#
#	var Projectile_RID = Projectile.get_rid()
#
#	Collision_Exclusion.push_back(Projectile_RID)
#	Projectile.tree_exited.connect(Remove_Exclusion.bind(Projectile_RID))
#
#	Projectile.set_linear_velocity(Direction*Current_Weapon.Projectile_Velocity)
#	Projectile.Damage = Current_Weapon.Damage
#
#func Remove_Exclusion(_RID):
#	Collision_Exclusion.erase(_RID)
#
#func _on_pick_up_detection_body_entered(body):
#	var Weapon_In_Stack = WeaponStack.find(body._weapon_name,0)
#
#	if Weapon_In_Stack != -1:
#		var remaining
#
#		remaining = Add_Ammo(body._weapon_name, body._current_ammo+body._reserve_ammo)
#		body._current_ammo = min(remaining, Weapons_List[body._weapon_name].Magazine)
#		body._reserve_ammo = max(remaining - body._current_ammo,0)
#
#		if remaining == 0:
#			body.queue_free()
#
#	elif body.TYPE == "Weapon":
#		if body.Pick_Up_Ready == true:
#			var GetRef = WeaponStack.find(Current_Weapon.Weapon_Name)
#			WeaponStack.insert(GetRef,body._weapon_name)
#
#			#Zero Out Ammo From the Resource
#			Weapons_List[body._weapon_name].Current_Ammo = body._current_ammo
#			Weapons_List[body._weapon_name].Reserve_Ammo = body._reserve_ammo
#
#			Update_WeaponStack.emit(WeaponStack)
#			exit(body._weapon_name)
#
#			body.queue_free()
#
#func Add_Ammo(_Weapon: String, Ammo: int)->int:
#	var _weapon = Weapons_List[_Weapon]
#
#	var Required = _weapon.Max_Ammo - _weapon.Reserve_Ammo
#	var Remaining = max(Ammo - Required,0)
#
#	_weapon.Reserve_Ammo += min(Ammo, Required)
#
#	Update_Ammo.emit([Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
#	return Remaining
	

