extends TextureRect

@onready var score_label = $MarginContainer/HBoxContainer/score_label
@onready var counter_label = $MarginContainer/HBoxContainer/counter_label

var current_score = 0
var current_count = 0

func _ready():
	# Actualizar las etiquetas iniciales
	update_score_label()
	update_counter_label()

# Función para actualizar el puntaje
func update_score(new_score: int):
	current_score = new_score
	update_score_label()

# Función para actualizar los movimientos restantes
func update_moves(new_count: int):
	current_count = new_count
	update_counter_label()

# Función privada para actualizar la etiqueta del puntaje
func update_score_label():
	score_label.text = str(current_score)  # Convertir a String

# Función privada para actualizar la etiqueta de movimientos restantes
func update_counter_label():
	counter_label.text = str(current_count)  # Convertir a String
