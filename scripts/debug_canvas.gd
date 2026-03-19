extends CanvasLayer

@onready var velocidad_label = $PanelContainer/VBoxContainer/VelocidadLabel
@onready var estado_label = $PanelContainer/VBoxContainer/EstadoLabel
@onready var input_label = $PanelContainer/VBoxContainer/InputLabel
@onready var debug_label = $PanelContainer/VBoxContainer/InputLabel

@export var player: CharacterBody3D

func _process(_delta: float) -> void:
	# Cláusula de guarda: si no hay jugador, no hacemos nada
	if not player: 
		return
	
	var player_rotation = player.pivot.rotation
	
	debug_label.text =  str(player_rotation)
	
	update_debug_ui()

func update_debug_ui() -> void:
	var speed = player.velocity.length()
	velocidad_label.text = "Velocidad: %.2f m/s" % speed
	update_status_label(speed)
	
	# 3. Datos de Input
	var is_accelerating = Input.is_action_pressed("move_foward")
	var turn_input = Input.get_axis("turn_right", "turn_left")
	input_label.text = "Acelerando: %s | Giro: %.1f" % [is_accelerating, turn_input]

func update_status_label(speed: float) -> void:
	var is_accelerating = Input.is_action_pressed("move_foward")
	var is_braking = Input.is_action_pressed("brake")
	
	if is_accelerating:
		_set_status("ACELERANDO", Color.GREEN)
	elif is_braking:
		_set_status("FRENANDO", Color.RED)
	elif speed > 0.1:
		_set_status("INERCIA", Color.YELLOW)
	else:
		_set_status("EN REPOSO", Color.WHITE)

func _set_status(text: String, color: Color) -> void:
	estado_label.text = "Estado: %s" % text
	estado_label.modulate = color
