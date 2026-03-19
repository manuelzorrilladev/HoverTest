extends SpringArm3D

# --- Parámetros ajustables ---
@export var mouse_sensitivity: float = 0.15
@export var tilt_upper_limit: float = 45.0  
@export var tilt_lower_limit: float = -60.0 
@export var initial_pitch: float = -20.0 # Inclinación vertical inicial 
@export var initial_yaw: float = 0.0   # Rotación horizontal inicial
@export var enable_vertical_rotation = false
@export var enable_horizontal_rotation = false




func _ready():
	# Desacoplamos la rotación del SpringArm de la del jugador
	# Así, al girar la tabla, la cámara no gira bruscamente con ella
	set_as_top_level(true)
	
	# Capturamos el ratón para que no se salga de la ventana
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	rotation_degrees.x = initial_pitch
	rotation_degrees.y = initial_yaw

func _input(event):
	# Detectamos el movimiento del ratón
	if event is InputEventMouseMotion:
		# 1. Rotación Horizontal (Eje Y)
		# Giramos el brazo horizontal si se quiere		
		if(enable_horizontal_rotation):
			rotation_degrees.y -= event.relative.x * mouse_sensitivity
		
		# 2. Rotación Vertical (Eje X)
		# Inclinamos el brazo arriba/abajo
		if(enable_vertical_rotation):
			rotation_degrees.x -= event.relative.y * mouse_sensitivity
		
		
		
		# 3. Limitamos la inclinación (Clamping)
		rotation_degrees.y = clamp(rotation_degrees.y, tilt_lower_limit, tilt_upper_limit)
		rotation_degrees.x = clamp(rotation_degrees.x, tilt_lower_limit, tilt_upper_limit)

func _process(_delta):
	# Ya que usamos 'top_level', debemos seguir manualmente la posición del jugador
	# Pero manteniendo nuestra propia rotación de cámara.
	if get_parent():
		global_position = get_parent().global_position
