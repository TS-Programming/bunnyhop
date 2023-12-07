extends Node

var hud = null
@export var hud_path := "/root/Main2/Map/FpPlayer/FpHud"
var weapon_manager = null
var weapon_manager_path := "/root/Main2/Map/FpPlayer/FpCamera/H/V/Camera3D/WeaponManager"
var funds: int = 0

var total_kills: int = 0  # Total number of kills
var multiplier: int = 1  # Current loot multiplier
var max_multiplier: int = 5  # Maximum multiplier value
var kills_needed_for_next_level: int = 1  # Kills needed to reach the next multiplier level


# Called when the node enters the scene tree for the first time.
func _ready():
	hud = get_node(hud_path)
	weapon_manager= get_node(weapon_manager_path)
	call_deferred("update_funds")  # Defer the call to the update_funds function
	
# Call this method when the player kills an enemy
func register_kill():
	total_kills += 1
	if total_kills >= kills_needed_for_next_level and multiplier < max_multiplier:
		multiplier += 1
		kills_needed_for_next_level += multiplier  # Increase the threshold for the next level
	hud.set_kill_streak(total_kills)
	hud.set_multiplier(multiplier)

# Call this method when the player takes damage
func reset_multiplier():
	total_kills = 0
	multiplier = 1
	kills_needed_for_next_level = 1

# Method to calculate loot amount
func calculate_loot(base_loot: int) -> int:
	return base_loot * multiplier

func update_funds():
	if hud:
		hud.set_funds(funds)


func add_funds(value: int):
	funds += value
	weapon_manager.check_weapon_switch(funds)
	hud.set_funds(funds)

func spend_funds(value: int) -> bool:
	if funds - value > 0:
		funds -= value
		weapon_manager.check_weapon_switch(funds)
		hud.set_funds(funds)
		return true
	return false
