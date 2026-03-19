extends CharacterBody3D

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
@export var turn_weight: float = 5.0    # Qué tan rápido alcanza/suelta el giro (inercia)
@export_group("Hover Effect")
@export var hover_amplitude: float = 0.1 
@export var hover_speed: float = 3.0 
@export var base_pivot_height: float = 0.2






@onready var pivot: Node3D = $Pivot    


var current_turn_velocity: float = 0.0 # Almacena la inercia del giro actual
var current_speed: float = 0.0
var time_passed: float = 0.0 # Variable para rastrear el tiempo y alimentar el seno

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 20.0 * delta 
	else:
		velocity.y = 0
		

	var input_dir = Input.is_action_pressed("move_foward") 
	var brake_input = Input.is_action_pressed("brake")
	var turn_dir = Input.get_axis("turn_right", "turn_left") 

	# 3. Lógica de Aceleración y Fricción y frenado
	if input_dir:
		current_speed = lerp(current_speed, max_speed, acceleration * delta)
	else:
		current_speed = lerp(current_speed, 0.0, friction * delta)
	
	if current_speed < stop_speed:
		current_speed = 0.0
	if brake_input and current_speed > stop_speed:
		current_speed = lerp(current_speed, 0.0, brake*delta)
		
		
	# 4. Lógica de Giro con Límite de Radio
	if current_speed > 1.0:
		var speed_factor = current_speed / max_speed
		var dynamic_turn = remap(speed_factor, 0.0, 1.0, 1.0, min_turn_multiplier)
		
		current_turn_velocity = lerp(current_turn_velocity, turn_dir, turn_weight * delta)
		
		# Aplicamos la rotación usando la velocidad de giro suavizada
		rotate_y(current_turn_velocity * (turn_speed * dynamic_turn) * delta)
	else:
		# Si nos detenemos, reseteamos la inercia de giro
		current_turn_velocity = 0.0
	# 5. Aplicar Movimiento
	var forward_dir = -global_transform.basis.z 
	velocity.x = forward_dir.x * current_speed
	velocity.z = forward_dir.z * current_speed
	
	
	
	
	move_and_slide()
	
	time_passed += delta # Incrementamos el tiempo
	_update_visuals(turn_dir, delta)

func _update_visuals(dir: float, delta: float) -> void:
	if pivot:
		# A. Inclinación lateral (Lean) - Código anterior
		var target_tilt = dir * lean_amount
		pivot.rotation.z = lerp(pivot.rotation.z, target_tilt, 5.0 * delta)
		
		# B. Efecto Flotante (Oscilación Vertical)

		var hover_offset = sin(time_passed * hover_speed) * hover_amplitude
		
		
		
		
		# Aplicamos la posición al eje Y del pivot (Altura base + oscilación)
		pivot.position.y = base_pivot_height + hover_offset
		
