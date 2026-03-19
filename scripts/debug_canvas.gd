extends CanvasLayer

@onready var velocidad_label = $PanelContainer/VBoxContainer/VelocidadLabel
@onready var estado_label = $PanelContainer/VBoxContainer/EstadoLabel
@onready var input_label = $PanelContainer/VBoxContainer/InputLabel
@onready var rotation_label = $PanelContainer/VBoxContainer/InputLabel

@export var player: CharacterBody3D

func _process(_delta):
	if not player:
		return
		
	@warning_ignore("unused_variable")
	
	
	
	
	var speed = player.velocity.length()
	velocidad_label.text = "Velocidad: %.2f m/s" % speed
	
	# 2. Determinar estado (Acelerando / Desacelerando / Libre)
	var input_v = Input.is_action_pressed("move_foward")
	if input_v:
		estado_label.text = "Estado: ACELERANDO"
		estado_label.modulate = Color.GREEN
	else:
		if speed == 0:
			estado_label.text = "Estado: EN REPOSO"
			estado_label.modulate = Color.WHITE
		else :
			estado_label.text = "Estado: FRENADO POR INERCIA"
			estado_label.modulate = Color.YELLOW


		
	# 3. Mostrar Input actual
	input_label.text = 'Input V: %s | Input H: %.1f' % [input_v, Input.get_axis("turn_right", "turn_left")]
