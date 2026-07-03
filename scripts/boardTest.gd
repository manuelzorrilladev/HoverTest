extends CharacterBody3D

enum States { NORMAL, BRAKING, BOOSTING, DRIFTING, JUMPING, HEAT, OVERHEAT, NO_FUEL }

# El Setter controla las reglas de transición (cuándo se permite cambiar de estado)
var current_state: States = States.NORMAL:
	set(value):
		if current_state != value:
			_on_state_exit(current_state)
			current_state = value
			_on_state_enter(current_state)

# Diccionario que mapea los estados directamente a sus funciones Handler
@onready var state_handlers: Dictionary = {
	States.NORMAL:    _handle_normal_state,
	States.BRAKING:   _handle_braking_state,
	States.BOOSTING:  _handle_boosting_state,
	States.DRIFTING:  _handle_drifting_state,
	States.JUMPING:   _handle_jumping_state,
	States.HEAT:      _handle_heat_state,
	States.OVERHEAT:  _handle_overheat_state,
	States.NO_FUEL:   _handle_no_fuel_state
}

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	
	# REGLA DE ORO: Ejecuta dinámicamente el handler del estado actual
	if state_handlers.has(current_state):
		state_handlers[current_state].call(delta)
	
	# Físicas y visuales comunes a cualquier estado
	move_and_slide()
	time_passed += delta
	_update_visuals(current_turn_velocity, delta)

# --- GESTORES DE TRANSICIÓN (DISPARADORES ÚNICOS) ---

func _on_state_enter(new_state: States) -> void:
	print("Entrando a: ", States.keys()[new_state])
	match new_state:
		States.BOOSTING:
			# Aquí disparas partículas de turbo, cambias FOV, etc.
			pass
		States.NO_FUEL:
			# Aquí apagas el sonido del motor y activas alarmas
			pass

func _on_state_exit(old_state: States) -> void:
	match old_state:
		States.BOOSTING:
			# Aquí restauras la velocidad máxima normal o la FOV de la cámara
			pass

# --- LOS HANDLERS ESPECÍFICOS (Controladores) ---

func _handle_normal_state(delta: float) -> void:
	var input_forward = Input.is_action_pressed("move_foward")
	var turn_dir = Input.get_axis("turn_right", "turn_left")
	
	# Consumo y físicas normales
	_process_fuel_consumption(delta)
	current_speed = lerp(current_speed, max_speed, acceleration * delta)
	_process_turning(turn_dir, false, delta)
	
	# Verificación de Transiciones (Entradas a otros estados)
	if actual_fuel <= 0.0:
		current_state = States.NO_FUEL
	elif Input.is_action_pressed("brake") and current_speed > stop_speed:
		current_state = States.BRAKING
	elif Input.is_action_just_pressed("boost") and can_boost:
		current_state = States.BOOSTING

func _handle_braking_state(delta: float) -> void:
	var turn_dir = Input.get_axis("turn_right", "turn_left")
	
	# Frenado pesado
	current_speed = lerp(current_speed, 0.0, brake * delta)
	_process_turning(turn_dir, true, delta) # Se le pasa true para aplicar penalización
	
	# Transiciones de salida
	if not Input.is_action_pressed("brake") or current_speed <= stop_speed:
		current_state = States.NORMAL

func _handle_boosting_state(delta: float) -> void:
	# Lógica donde ignoras el freno y la fricción, vas a velocidad extrema
	current_speed = lerp(current_speed, boost_max_speed, (acceleration * 2) * delta)
	
	# El boost maneja su propio timer, si se acaba vuelves a NORMAL o a HEAT si abusaste
	if boost_timer <= 0:
		current_state = States.NORMAL

func _handle_no_fuel_state(delta: float) -> void:
	var turn_dir = Input.get_axis("turn_right", "turn_left")
	
	# El jugador no puede acelerar ni activar boost porque este handler no escucha esos inputs.
	# Solo sufre la desaceleración por motor ahogado.
	current_speed = lerp(current_speed, 0.0, (friction * 1.8) * delta)
	_process_turning(turn_dir, false, delta)
	
	if current_speed < stop_speed:
		current_speed = 0.0

# (Define el resto de tus handlers vacíos de la misma forma para evitar errores)
func _handle_drifting_state(delta: float) -> void: pass
func _handle_jumping_state(delta: float) -> void: pass
func _handle_heat_state(delta: float) -> void: pass
func _handle_overheat_state(delta: float) -> void: pass
