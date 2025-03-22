extends Node2D

@export var allied_unit: PackedScene
var player

# Called when the node enters the scene tree for the first time.
func _ready():
	player = allied_unit.instantiate()
	player.position = $TileMap.map_to_local(Vector2(5,1))
	add_child(player)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if player.selected and Vector2i(event.position - player.position).length_squared() > 36**2 and  Vector2i(event.position - player.position).length_squared() < 92**2*player.getSpeed() and $TileMap.get_cell_tile_data(0,$TileMap.local_to_map(event.position),false).get_custom_data("isPassable"):
				player.position = $TileMap.map_to_local($TileMap.local_to_map(event.position))
				player.toggleSelect()
			elif not(player.selected) and $TileMap.local_to_map(event.position) == $TileMap.local_to_map(player.position):
				player.toggleSelect()
				

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
