extends CharacterBody3D

enum States {NORMAL, BRAKING, BOOSTING, DRIFTING, JUMPING, HEAT, OVERHEAT}

# --- Variables de Control de Estado ---
var current_state: States = States.NORMAL:
	set(value):
		if current_state != value:
			current_state = value

@onready var state_handlers: Dictionary = {
	States.NORMAL: _handle_normal_state,
	States.BRAKING: _handle_braking_state,
	States.BOOSTING: _handle_boosting_state,
	States.DRIFTING: _handle_drifting_state,
	States.JUMPING: _handle_jumping_state,
	States.HEAT: _handle_heat_state,
	States.OVERHEAT: _handle_overheat_state,
}


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
@export var hover_speed: float = 8.0
@export var base_pivot_height: float = 0.2

@export_group("Visual Effects")
@export var brake_rotation_amount: float = 0.8
@export var brake_rotation_speed: float = 7.0


@export_group("Boost Settings")
@export var boost_force: float = 30.0
@export var boost_max_speed: float = 80.0
@export var boost_duration: float = 2.0
@export var boost_cooldown: float = 5.0


@export_group("Fuel and Heat Management")
@export var max_fuel: float = 100.0
@export var actual_fuel: float = 100.0
@export var fuel_consumption_rate: float = 0.01
@export var actual_heat: float = 0.0
@export var heat_accumulation_rate: float = 1.0
@export var cooldown_rate: float = 0.5


var boost_timer: float = 0.0
var cooldown_timer: float = 0.0
var is_boosting: bool = false
var original_max_speed: float # Para restaurar la velocidad después


@onready var pivot: Node3D = $Pivot

# --- Variables Internas ---
var current_turn_velocity: float = 0.0
var current_speed: float = 0.0
var time_passed: float = 0.0


# VARIABLES 


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_boost_board(delta)
	
	
	if state_handlers.has(current_state):
		state_handlers[current_state].call(delta)

	# 3. Aplicar Movimiento Final
	_apply_velocity_to_body()
	move_and_slide()
	
	# 4. Jugo Visual
	time_passed += delta
	_update_visuals(current_turn_velocity, delta)

# 	GESTOR DE TRANSICIONES DE ESTADO


func _on_state_enter(new_state: States) -> void:
	print("Entrando a: ", States.keys()[new_state])
	match new_state:
		States.BOOSTING:
			# Aquí disparas partículas de turbo, cambias FOV, etc.
			pass
		# States.NO_FUEL:
		# 	# Aquí apagas el sonido del motor y activas alarmas
		# 	pass

func _on_state_exit(old_state: States) -> void:
	match old_state:
		States.BOOSTING:
			# Aquí restauras la velocidad máxima normal o la FOV de la cámara
			pass


# MECANICAS GLOBALES REUTILIZABLES
func _handle_fuel_consumption(delta: float) -> void:
	var input_forward = Input.is_action_pressed("move_foward")
	
	# 2. Lógica de Consumo de Combustible
	if input_forward and actual_fuel > 0.0:
		actual_fuel = lerp(actual_fuel, 0.0, fuel_consumption_rate * delta)
		if actual_fuel < 0.05:
			actual_fuel = 0.0

# MANEJO DE ESTADOS


func _handle_normal_state(delta: float) -> void:
	var input_forward = Input.is_action_pressed("move_foward")
	
	var turn_dir = Input.get_axis("turn_right", "turn_left")
	# 2. Lógica de Consumo de Combustible
	_handle_fuel_consumption(delta)
		
		
	# 3. Lógica de Velocidad y Aceleración
	if input_forward and actual_fuel > 0.0 and not Input.is_action_pressed("brake"):
		# Aceleración normal con combustible y sin frenar
		current_speed = lerp(current_speed, max_speed, acceleration * delta)
	
	elif actual_fuel <= 0.0:
		# --- SIN COMBUSTIBLE ---
		# El vehículo desacelera de forma más drástica. 
		# Puedes usar (friction * 1.5) o crear una variable externa llamada 'engine_brake_drag'
		current_speed = lerp(current_speed, 0.0, (friction * 1.5) * delta)
		
	else:
		# Desaceleración normal por inercia (soltó el acelerador pero tiene combustible)
		current_speed = lerp(current_speed, 0.0, friction * delta)
	
	
	if Input.is_action_pressed("brake") and current_speed > stop_speed:
		current_state = States.BRAKING
	elif Input.is_action_just_pressed("boost"):
		current_state = States.BOOSTING

	# 5. Parada Absoluta
	if current_speed < stop_speed:
		current_speed = 0.0

	# 6. Lógica de Giro
	_process_turning(turn_dir, Input.is_action_pressed("brake"), delta)
	

func _handle_braking_state(delta: float) -> void:
	var turn_dir = Input.get_axis("turn_right", "turn_left")
	
	# Frenado pesado
	current_speed = lerp(current_speed, 0.0, brake * delta)
	_process_turning(turn_dir, true, delta) # Se le pasa true para aplicar penalización
	
	# Transiciones de salida
	if not Input.is_action_pressed("brake") or current_speed <= stop_speed:
		current_state = States.NORMAL


func _handle_drifting_state(_delta: float) -> void:
	pass

func _handle_boosting_state(delta: float) -> void:
	_boost_board(delta)


func _handle_jumping_state(delta: float) -> void: pass
func _handle_heat_state(delta: float) -> void: pass
func _handle_overheat_state(delta: float) -> void: pass


# MECANICAS DE BOOST
func _boost_board(delta: float) -> void:
	if cooldown_timer > 0:
		cooldown_timer -= delta

	# 2. Activar Boost
	if Input.is_action_just_pressed("boost") and cooldown_timer <= 0 and not is_boosting and actual_fuel > 8.0:
		is_boosting = true
		_handle_fuel_consumption(delta)
		boost_timer = boost_duration
		cooldown_timer = boost_cooldown
		original_max_speed = max_speed
	
	# Aplicamos el boost
		max_speed = boost_max_speed
		current_speed += boost_force
		actual_fuel -= 10
	
	# Aquí es donde dispararías partículas o sonidos
	print("BOOST ACTIVO!")

	# 3. Lógica mientras el Boost está activo
	if is_boosting:
		boost_timer -= delta
		# Efecto visual: Podrías aumentar el FOV de la cámara aquí
		if boost_timer <= 0:
			_stop_boost()

func _stop_boost() -> void:
	is_boosting = false
	max_speed = original_max_speed
	current_state = States.NORMAL
	print("BOOST FINALIZADO")


#MOVIMIENTO

func _process_turning(turn_dir: float, is_braking: bool, delta: float) -> void:
	if current_speed > 1.0:
		var speed_factor = clamp(current_speed / max_speed, 0.0, 1.0)
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
	var forward_dir = - global_transform.basis.z
	velocity.x = forward_dir.x * current_speed
	velocity.z = forward_dir.z * current_speed

#MECANICA DE SALTOS

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0


# ESTETICOS
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
