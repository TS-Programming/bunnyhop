extends CharacterBody3D


var player = null
var state_machine
var health = 3
var og_scale

signal zombie_hit

const SPEED = 8
const ATTACK_RANGE = 2.0
const KNOCKBACK = 15
const DAMAGE = 10

@export var player_path := "/root/Main2/Map/FpPlayer"
var loot = load("res://Models/Loot/Coin.tscn")

@onready var nav_agent = $NavigationAgent3D
@onready var anim_tree = $AnimationTree


# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_node(player_path)
	state_machine = anim_tree.get("parameters/playback")
	og_scale = scale


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if LightManager.is_green_light():
		return
		
	velocity = Vector3.ZERO
	
	
	match state_machine.get_current_node():
		"Run":
			# Navigation
			nav_agent.set_target_position(player.global_transform.origin)
			var next_nav_point = nav_agent.get_next_path_position()
			velocity = (next_nav_point - global_transform.origin).normalized() * SPEED
			rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), delta * 10.0)
		"Attack":
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)


	anim_tree.set("parameters/conditions/attack", _target_in_range())
	anim_tree.set("parameters/conditions/run", !_target_in_range())
	
	move_and_slide()


func _target_in_range():
	return global_position.distance_to(player.global_position) < ATTACK_RANGE


func _hit_finished():
	if global_position.distance_to(player.global_position) < ATTACK_RANGE + 1.0:
		var dir = global_position.direction_to(player.global_position)
		player.hit(DAMAGE, dir * KNOCKBACK)

func _on_area_3d_body_part_hit(dam):
	if LightManager.is_green_light():
		health += dam
		if og_scale * 2 > scale:
			scale *= 1.5
	else:
		health -= dam
		emit_signal("zombie_hit")

	if health <= 0:
		die()



func spawn_loot_spiral():
	var loot_multiplier = LootManager.multiplier
	var angle = 0.0
	var radius = 1.0
	var angle_increment = 45.0  # degrees
	var radius_increment = 0.5  # adjust for tighter or looser spiral

	for i in range(loot_multiplier):
		var expression = Expression.new()
		var radian = deg_to_rad(angle)
		var offset = Vector3(cos(radian), 0, sin(radian)) * radius

		var instance = loot.instantiate()
		instance.position = position + offset
		get_parent().add_child(instance)

		angle += angle_increment
		radius += radius_increment
		
func die():
	anim_tree.set("parameters/conditions/die", true)
	await get_tree().create_timer(4.0).timeout  # Wait for 4 seconds
	LootManager.register_kill()
	spawn_loot_spiral()
	queue_free()

#func _on_area_3d_body_part_hit(dam):
#	if LightManager.is_green_light():
#		health += dam
#		if og_scale * 2 > scale:
#			scale *= 1.5
#	else:
#		health -= dam
#	#	print(health)
#		emit_signal("zombie_hit")
#		if health <= 0:
#			anim_tree.set("parameters/conditions/die", true)
#			LootManager.numKillsSinceLastDamaged += 1;
#			await get_tree().create_timer(4.0).timeout
#			var instance = loot.instantiate()
#			instance.position = position
#			player.get_parent().add_child(instance)
#			queue_free()
