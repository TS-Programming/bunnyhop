class_name FpCamera
extends Marker3D

const MOUSE_SENSITIVITY_FACTOR := 0.001

@onready var camera := $H/V/Camera3D

#guns
@onready var gun_anim :=  $H/V/Camera3D/Rifle/AnimationPlayer
@onready var auto_anim :=  $H/V/Camera3D/Rifle/AnimationPlayer
@onready var gun_barrel :=  $H/V/Camera3D/Rifle/RayCast3D
@onready var aim_ray :=  $H/V/Camera3D/AimRay
@onready var aim_ray_end :=  $H/V/Camera3D/AimRayEnd
@onready var auto_barrel = $H/V/Camera3D/SteampunkAuto/Meshes/Barrel
#end guns

@onready var fp_player: FpPlayer = get_parent()
# transforms to interpolate the fp_camera
@onready var initial_camera_xform: Transform3D = transform
@onready var old_xform: Transform3D
@onready var current_xform: Transform3D

@onready var mouse_horizontal_sensitivity: float = 1.0
var mouse_horizontal_sensitivity_modifier: float = 1.0
@onready var mouse_vertical_sensitivity: float = 1.0
var mouse_vertical_sensitivity_modifier: float = 1.0

# use whenever teleporting the scene, to not interpolate
func forget_previous_transforms():
	old_xform = fp_player.global_transform
	current_xform = fp_player.global_transform

func modify_camera(modifier: float):
	mouse_horizontal_sensitivity_modifier = modifier
	mouse_vertical_sensitivity_modifier = modifier
	
# get the basis of H node
func get_hbasis() -> Basis:
	return $H.global_transform.basis

# get the basis of H node
func get_local_hbasis() -> Basis:
	return $H.transform.basis

# get the basis of V node or Camera
func get_camera_basis() -> Basis:
	return $H/V.global_transform.basis

# get the basis of V node or Camera
func get_local_basis() -> Basis:
	return $H/V.transform.basis

# get the horizontal rotation (yaw)
func get_hrot() -> float:
	return $H.rotation.y

# get the vertical rotation (pitch)
func get_vrot() -> float:
	return $H/V.rotation.x

func get_forward_vector() -> Vector3:
	return -get_basis().z

func get_interpolated_global_transform():
	var fraction := Engine.get_physics_interpolation_fraction()
	return old_xform.interpolate_with(current_xform, fraction) * initial_camera_xform

func _physics_process(_delta: float) -> void:
	old_xform = current_xform
	current_xform = fp_player.global_transform

func _process(_delta: float) -> void:
	# fp_camera interpolation
	# print_debug(mouse_horizontal_sensitivity)
	var fraction := Engine.get_physics_interpolation_fraction()
	global_transform = old_xform.interpolate_with(current_xform, fraction) * initial_camera_xform

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var hrot: float = -event.relative.x
		var vrot: float = -event.relative.y
		$H.rotate_y(hrot * mouse_horizontal_sensitivity_modifier * mouse_horizontal_sensitivity * MOUSE_SENSITIVITY_FACTOR)
		$H/V.rotate_x(vrot * mouse_vertical_sensitivity_modifier * mouse_vertical_sensitivity * MOUSE_SENSITIVITY_FACTOR)
		$H/V.rotation.x = clamp($H/V.rotation.x, -PI * 0.47, PI * 0.47)
