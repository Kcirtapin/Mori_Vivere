extends Node2D

@export var allied_unit: PackedScene
var player

# Called when the node enters the scene tree for the first time.
func _ready():
	player = allied_unit.instantiate()
	player.position.x = 200
	player.position.y = 200
	add_child(player)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if player.selected:
				player.position = event.position
				#player.selected = false
		
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
