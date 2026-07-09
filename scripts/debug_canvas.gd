extends CanvasLayer

# Ahora solo necesitas un único RichTextLabel que acepte BBCode
@onready var debug_label = $PanelContainer/VBoxContainer/DebugLabel

@export var player: CharacterBody3D

# Diccionario interno donde guardaremos los datos dinámicamente
var debug_data: Dictionary = {}

func _process(_delta: float) -> void:
	if not player: 
		return
	
	# 1. Recolectamos la información
	collect_debug_data()
	# 2. La mostramos en pantalla
	render_debug_ui()

func collect_debug_data() -> void:
	# Aquí puedes meter CUALQUIER variable nueva sin crear nodos en la UI.
	
	# 1. Velocidad
	debug_data["Velocidad"] = "%.2f m/s" % player.velocity.length()
	debug_data["Rotacion visual Z"] = "%.2f grados" % player.pivot.rotation.z
	debug_data["Rotacion visual Y"] = "%.2f grados" % player.pivot.rotation.y
	# 2. Estado (Manejamos el color internamente con BBCode si quieres)
	var state_name = player.States.keys()[player.current_state]
	var state_color = "white"
	match player.current_state:
		player.States.NORMAL: state_color = "cyan"
		player.States.DRIFTING: state_color = "orange"
		player.States.JUMPING, player.States.HEAT: state_color = "yellow"
	
	debug_data["Estado Físico"] = "[color=%s]%s[/color]" % [state_color, state_name]
	
	# 3. Inputs
	var is_accelerating = Input.is_action_pressed("move_foward")
	var turn_input = Input.get_axis("turn_right", "turn_left")
	debug_data["Inputs"] = "Acelerando: %s | Giro: %.1f" % [is_accelerating, turn_input]
	
	# 4. Orientación
	var current_angle = wrapf(player.rotation_degrees.y, 0, 360)
	debug_data["Orientación"] = "%.1f °" % current_angle
	
	# 5. Calentamiento y combustible
	debug_data["Temperatura"] = "%.1f °" % player.actual_heat
	debug_data["Combustible"] = "%.1f / %.1f" % [player.actual_fuel, player.max_fuel]
	debug_data["Cooldown"] = "%.1f s" % player.cooldown_timer

	# ¿Quieres añadir algo nuevo mañana? Solo haz esto:
	# debug_data["Nueva Variable"] = player.mi_nueva_variable

func render_debug_ui() -> void:
	var final_text = ""
	
	# Recorremos el diccionario y armamos el bloque de texto completo
	for key in debug_data.keys():
		final_text += "[b]%s:[/b] %s\n" % [key, debug_data[key]]
	
	# Actualizamos el único label
	debug_label.text = final_text
