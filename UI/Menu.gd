extends Control

@export var game : PackedScene
@export var world : World
var seeded = false
@onready var random = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_new_button_pressed() -> void:
	var instance = game.instantiate()
	instance.get_node("World").world = World.new()
	if not seeded is bool:
		instance.get_node("World").world.seeded = seeded
	else:
		instance.get_node("World").world.seeded = random.randi()
	get_tree().root.add_child(instance)
	queue_free()

func _on_line_edit_text_changed(new_text: String) -> void:
	seeded = int(new_text)
