extends CharacterBody3D

enum States { NORMAL,BRAKING,BOOSTING, DRIFTING, JUMPING, HEAT, OVERHEAT }

# --- Variables de Control de Estado ---
var current_state: States = States.NORMAL:
	set(value):
		if current_state != value:
			current_state = value

# --- Exports (Mantengo tus valores originales) ---
@export_group("Movement")
@export var max_speed: float = 50.0
@export var acceleration: float = 5.0
@export var friction: float = 2.0
@export var brake: float = 10.0
@export var stop_speed: float = 0.5

@export_group("Turn")
@export var turn_speed: float = 3.0
@export var lean_amount: float = 0.3
@export var min_turn_multiplier: float = 0.2
@export var turn_weight: float = 5.0
@export var brake_turn_penalty: float = 0.2

@export_group("Hover Effect")
@export var hover_amplitude: float = 0.1
@export var hover_speed: float = 3.0
@export var base_pivot_height: float = 0.2

@export_group("Visual Effects")
@export var brake_rotation_amount: float = 0.8
@export var brake_rotation_speed: float = 7.0


@export_group("Boost Settings")
@export var boost_force: float = 30.0      # Impulso de velocidad instantáneo
@export var boost_max_speed: float = 80.0  # El nuevo límite de velocidad durante el boost
@export var boost_duration: float = 2.0    # Cuánto dura el efecto (segundos)
@export var boost_cooldown: float = 5.0    # Tiempo antes de poder usarlo de nuevo

var boost_timer: float = 0.0
var cooldown_timer: float = 0.0
var is_boosting: bool = false
var original_max_speed: float # Para restaurar la velocidad después


@onready var pivot: Node3D = $Pivot

# --- Variables Internas ---
var current_turn_velocity: float = 0.0
var current_speed: float = 0.0
var time_passed: float = 0.0

func _physics_process(delta: float) -> void:
	# 1. Gravedad y suelo (Común a casi todos los estados)
	_apply_gravity(delta)
	_boost_board(delta)
	# 2. Máquina de Estados (Selección de lógica)
	match current_state:
		States.NORMAL:
			_handle_normal_state(delta)
		States.DRIFTING:
			_handle_drift_state(delta)
		# States.JUMPING, HEAT, etc., se añadirán conforme los desarrolles

	# 3. Aplicar Movimiento Final
	_apply_velocity_to_body()
	move_and_slide()
	
	# 4. Jugo Visual
	time_passed += delta
	_update_visuals(current_turn_velocity, delta)

# --- LÓGICA DE ESTADOS ---

func _handle_normal_state(delta: float) -> void:
	# Captura de inputs
	var input_forward = Input.is_action_pressed("move_foward")
	var brake_input = Input.is_action_pressed("brake")
	var turn_dir = Input.get_axis("turn_right", "turn_left")

	# Lógica de Velocidad
	if input_forward:
		if brake_input:
			current_speed = lerp(current_speed, max_speed, (acceleration/2) * delta)
		else:
			current_speed = lerp(current_speed, max_speed, acceleration * delta)
			
	else:
		current_speed = lerp(current_speed, 0.0, friction * delta)
	
	if brake_input and current_speed > stop_speed:
		current_speed = lerp(current_speed, 0.0, brake * delta)


	
	if current_speed < stop_speed:
		current_speed = 0.0

	# Lógica de Giro
	_process_turning(turn_dir, brake_input, delta)
	
	# Ejemplo de transición (Futura lógica de Drift)
	# if Input.is_action_just_pressed("drift"): current_state = States.DRIFTING

func _handle_drift_state(_delta: float) -> void:
	# Aquí irá la lógica de derrape cerrado (Semana 4)
	pass

# --- FUNCIONES DE SOPORTE (REUTILIZABLES) ---

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0

func _boost_board(delta: float) -> void:
	if cooldown_timer > 0:
		cooldown_timer -= delta

	# 2. Activar Boost
	if Input.is_action_just_pressed("boost") and cooldown_timer <= 0 and not is_boosting:
		_start_boost()

	# 3. Lógica mientras el Boost está activo
	if is_boosting:
		boost_timer -= delta
		# Efecto visual: Podrías aumentar el FOV de la cámara aquí
		if boost_timer <= 0:
			_stop_boost()

func _start_boost() -> void:
	is_boosting = true
	boost_timer = boost_duration
	cooldown_timer = boost_cooldown
	
	# Guardamos la velocidad original para no "romper" el script permanentemente
	original_max_speed = max_speed 
	
	# Aplicamos el boost
	max_speed = boost_max_speed
	current_speed += boost_force # Empujón inicial instantáneo
	
	# Aquí es donde dispararías partículas o sonidos
	print("BOOST ACTIVO!")

func _stop_boost() -> void:
	is_boosting = false
	max_speed = original_max_speed
	print("BOOST FINALIZADO")

func _process_turning(turn_dir: float, is_braking: bool, delta: float) -> void:
	if current_speed > 1.0:
		var speed_factor = current_speed / max_speed
		var dynamic_turn = remap(speed_factor, 0.0, 1.0, 1.0, min_turn_multiplier)
		
		# Aplicamos penalización si está frenando
		var effective_turn = turn_dir
		if is_braking:
			effective_turn *= brake_turn_penalty
		
		current_turn_velocity = lerp(current_turn_velocity, effective_turn, turn_weight * delta)
		rotate_y(current_turn_velocity * (turn_speed * dynamic_turn) * delta)
	else:
		current_turn_velocity = 0.0

func _apply_velocity_to_body() -> void:
	var forward_dir = -global_transform.basis.z
	velocity.x = forward_dir.x * current_speed
	velocity.z = forward_dir.z * current_speed

func _update_visuals(dir: float, delta: float) -> void:
	if not pivot: return
	
	# A. Inclinación lateral
	var target_tilt = dir * lean_amount
	pivot.rotation.z = lerp(pivot.rotation.z, target_tilt, 5.0 * delta)
	
	# B. Efecto Flotante
	var hover_offset = sin(time_passed * hover_speed) * hover_amplitude
	
	# C. Animación de Freno (Snowboard style)
	var is_braking_visually = Input.is_action_pressed("brake") and current_speed > 2.0
	var target_brake_rotation = 0.0
	
	if is_braking_visually:
		target_brake_rotation = brake_rotation_amount
		pivot.rotation.z = lerp(pivot.rotation.z, lean_amount, 5.0 * delta)
		
	pivot.rotation.y = lerp(pivot.rotation.y, target_brake_rotation, brake_rotation_speed * delta)
	pivot.position.y = base_pivot_height + hover_offset
