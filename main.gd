extends Node2D

@export var level: PackedScene
var crntScene = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	

		


func _on_start_button_pressed():
	$TitleScreen.hide()
	crntScene = level.instantiate()
	add_child(crntScene)
