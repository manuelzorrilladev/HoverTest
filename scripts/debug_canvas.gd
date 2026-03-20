extends CanvasLayer

@onready var velocidad_label = $PanelContainer/VBoxContainer/VelocidadLabel
@onready var estado_label = $PanelContainer/VBoxContainer/EstadoLabel
@onready var input_label = $PanelContainer/VBoxContainer/InputLabel
# Asumo que rotation_label es para la rotación según tu código anterior
@onready var rotation_label = $PanelContainer/VBoxContainer/RotationLabel 

@export var player: CharacterBody3D

func _process(_delta: float) -> void:
	if not player: 
		return
	
	update_debug_ui()

func update_debug_ui() -> void:
	# 1. Velocidad
	var speed = player.velocity.length()
	velocidad_label.text = "Velocidad: %.2f m/s" % speed
	
	# 2. Estado Finito (Leído del Enum del jugador)
	update_status_label()
	
	# 3. Inputs
	var is_accelerating = Input.is_action_pressed("move_foward")
	var turn_input = Input.get_axis("turn_right", "turn_left")
	input_label.text = "Acelerando: %s | Input Giro: %.1f" % [is_accelerating, turn_input]
	
	# 4. Ángulo de Rotación (Y es el eje vertical en 3D)
	# Usamos wrapf para que el valor siempre esté entre 0 y 360
	var current_angle = wrapf(player.rotation_degrees.y, 0, 360)
	rotation_label.text = "Orientación: %.1f °" % current_angle

func update_status_label() -> void:
	# Obtenemos el nombre del estado usando la función keys() del Enum definido en el jugador
	var state_name = player.States.keys()[player.current_state]
	
	# Colores dinámicos según el estado para feedback visual rápido
	var state_color = Color.WHITE
	match player.current_state:
		player.States.NORMAL:
			state_color = Color.CYAN
		player.States.DRIFTING:
			state_color = Color.ORANGE
		player.States.JUMPING:
			state_color = Color.YELLOW
			
	_set_status(state_name, state_color)

func _set_status(text: String, color: Color) -> void:
	estado_label.text = "Estado Físico: %s" % text
	estado_label.modulate = color
