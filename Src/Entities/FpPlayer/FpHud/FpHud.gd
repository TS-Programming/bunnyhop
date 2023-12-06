extends CanvasLayer

@onready var speed_label := $MousePassHud/Mid/Speed
@onready var top_speed_label := $MousePassHud/TopSpeed
@onready var projection_label := $MousePassHud/Top/Projection
@onready var angle_label := $MousePassHud/Top/Angle
@onready var funds_label := $MousePassHud/Top/Funds
@onready var multiplier := $MousePassHud/Top/Multiplier
@onready var total_kills := $MousePassHud/Top/TotalKills

func _ready():
	set_multiplier(1)
	set_kill_streak(0)

func set_projection(val: float) -> void:
	projection_label.text = "projection: " + str(val).pad_decimals(2)

func set_angle(val: float) -> void:
	angle_label.text = "angle: " + str(val).pad_decimals(2) + " deg"

func set_velocity(val: float) -> void:
	speed_label.text = str(val).pad_decimals(1)
	var weight = val / 25.0
	speed_label.self_modulate = lerp(Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 0.4, 0.2, 1.0), weight)
	
func set_top_speed(val: float) -> void:
	top_speed_label.text = str(val).pad_decimals(1)
	
func set_funds(val: int):
	funds_label.text = "Loot: " + str(val)

func set_multiplier(val: int):
	multiplier.text = "Multiplier: " + str(val)
	
func set_kill_streak(val: int):
	total_kills.text = "Kill Streak: " + str(val)
