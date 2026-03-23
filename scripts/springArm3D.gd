extends SpringArm3D

@export var mouse_sensitivity: float = 0.15
@export var joystick_sensitivity: float = 100.0
@export var tilt_upper_limit: float = 45.0  
@export var tilt_lower_limit: float = -60.0 
@export var initial_pitch: float = -20.0 
@export var initial_yaw: float = 0.0   
@export var enable_vertical_rotation = false
@export var enable_horizontal_rotation = false

@export_group("FOV Effect")
@export var normal_fov: float = 75.0     
@export var boost_fov: float = 90.0       
@export var fov_change_speed: float = 5.0 

@onready var camera: Camera3D = $Camera3D 

func _ready():
	set_as_top_level(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	rotation_degrees.x = initial_pitch
	rotation_degrees.y = initial_yaw
	
	if camera:
		camera.fov = normal_fov

func _input(event):
	if event is InputEventMouseMotion:
		if enable_horizontal_rotation:
			rotation_degrees.y -= event.relative.x * mouse_sensitivity
		
		if enable_vertical_rotation:
			rotation_degrees.x -= event.relative.y * mouse_sensitivity
		
		_clamp_rotation()

func _process(delta):
	if get_parent():
		global_position = get_parent().global_position
	
	_handle_joystick_input(delta)
	
	_update_camera_fov(delta)

func _handle_joystick_input(delta: float) -> void:
	var joy_look_h = Input.get_axis("look_left", "look_right")
	var joy_look_v = Input.get_axis("look_up", "look_down")
	
	if abs(joy_look_h) > 0.1 or abs(joy_look_v) > 0.1:
		if enable_horizontal_rotation:
			rotation_degrees.y -= joy_look_h * joystick_sensitivity * delta
			
		if enable_vertical_rotation:
			rotation_degrees.x -= joy_look_v * joystick_sensitivity * delta
			
		_clamp_rotation()

func _clamp_rotation() -> void:
	rotation_degrees.x = clamp(rotation_degrees.x, tilt_lower_limit, tilt_upper_limit)
	# rotation_degrees.y = clamp(rotation_degrees.y, tilt_lower_limit, tilt_upper_limit) # 360° horizontal

# --- FUNCIÓN PARA ACTUALIZAR EL FOV ---
func _update_camera_fov(delta: float) -> void:
	if not camera: return
	
	# 1. Determinamos el FOV objetivo
	var target_fov = normal_fov
	
	# Accedemos al estado del jugador para saber si está en boost.
	# Asumimos que el script del jugador tiene una variable 'is_boosting'.
	#get_parent().current_state == get_parent().States.BOOSTING
	
	#if get_parent() and get_parent().get("is_boosting"):
	if get_parent() and get_parent().is_boosting:
		target_fov = boost_fov
	
	# 2. Aplicamos la interpolación suave (Lerp)
	# camera.fov = lerp(camera.fov, target_fov, fov_change_speed * delta)
	
	# Interpolación de ángulo para suavizar FOV
	camera.fov = lerp_angle(deg_to_rad(camera.fov), deg_to_rad(target_fov), fov_change_speed * delta)
	camera.fov = rad_to_deg(camera.fov)
