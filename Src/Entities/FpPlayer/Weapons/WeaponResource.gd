@icon("res://Player_Controller/scripts/Weapon_State_Machine/weapon_resource_icon.svg")
extends Resource

class_name WeaponResource

@export var bullet: PackedScene
@export var bullet_trail: PackedScene
@export var hitbox: Area3D
@export var ammo_left_in_mag: int = 6
@export var mag_size: int = 6
@export var reload_time: float = 0.8
@export var fire_rate: float = 0.07
@export var is_shot_gun: bool
@export var primary_is_auto: bool
@export var secondary_is_auto: bool
@export var secondary_is_continuous: bool
