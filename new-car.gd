extends VehicleBody3D

const ENGINE_POWER = 2000.0
const START_POWER = 2500.0
const MAX_TURN_ANGLE = 0.8
const NORMAL_SLIP = 2.0
const BRAKE_SLIP = 1.3
const COAST_BRAKE = 0.3
const BRAKE = 30
const MAX_SPEED_KMH = 180
const DRIFT_SLIP = 0.01
var engine_force_value = 0.0


@onready var front_left_wheel = $FrontLeft
@onready var front_right_wheel = $FrontRight
@onready var rear_left_wheel = $BackLeft
@onready var rear_right_wheel = $BackRight


var original_transform: Transform3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	original_transform = transform


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	#1- SET ACTIONS AND INPUTS
	var steer_input = Input.get_axis("turn_right", "turn_left")
	var accel_input = Input.get_axis("run_backwards", "run_foward")
	var brake_input = Input.is_action_pressed("brake") 
	var drift_input = Input.is_action_pressed("drift")
	
	var current_speed_ms = linear_velocity.length()
	var current_speed_kmh = current_speed_ms * 3.6
	
	
	var compensation = ENGINE_POWER * 0.2
	#2- SET ENGINE AND BRAKE MOVEMENT

	var speed_minimun = 90.0
	if current_speed_kmh < MAX_SPEED_KMH:
		if current_speed_kmh < speed_minimun:
			engine_force_value = accel_input * START_POWER
		else:
			engine_force_value = accel_input * ENGINE_POWER
	else:
		engine_force_value = min(0.0, accel_input) * ENGINE_POWER
		
		
	
	#3- SET STEERING
	steering = move_toward(steering, steer_input * MAX_TURN_ANGLE, delta * 3.0)
	front_left_wheel.steering = steering
	front_right_wheel.steering = steering
	
	#3.1 STEERING FIX WHEN CURVES
	if steering != 0:
		#var compensation = ENGINE_POWER * 0.5 * abs(steering)

		engine_force_value += compensation
		
		
	#4 SET SIMPLE BRAKE SYSTEM
	var brake_power_value = 0.0
	
	if brake_input:
		engine_force_value = 0.0
		rear_left_wheel.wheel_friction_slip = BRAKE_SLIP
		rear_right_wheel.wheel_friction_slip = BRAKE_SLIP
		brake_power_value = BRAKE
	if accel_input == 0 and current_speed_kmh > 0:
		brake_power_value = COAST_BRAKE
	else:
		rear_left_wheel.wheel_friction_slip = NORMAL_SLIP
		rear_right_wheel.wheel_friction_slip = NORMAL_SLIP
		
		
	#5 BASIC DRIFT MECHANIC
		
	if drift_input and current_speed_kmh > 30:

		engine_force_value += compensation

		rear_left_wheel.wheel_friction_slip = DRIFT_SLIP
		rear_right_wheel.wheel_friction_slip = DRIFT_SLIP
		
	else:
		rear_left_wheel.wheel_friction_slip = NORMAL_SLIP
		rear_right_wheel.wheel_friction_slip = NORMAL_SLIP
		
	
	rear_left_wheel.brake = brake_power_value
	rear_right_wheel.brake = brake_power_value
	front_left_wheel.brake = brake_power_value
	front_right_wheel.brake = brake_power_value
	
	
	rear_left_wheel.engine_force = engine_force_value
	rear_right_wheel.engine_force = engine_force_value
