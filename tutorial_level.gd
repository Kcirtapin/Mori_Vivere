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
			if player.selected and isValidGroundMovement(centerOnTile(player.position),centerOnTile(event.position),player.getSpeed()):
				player.position = centerOnTile(event.position)
				player.toggleSelect()
			elif not(player.selected) and $TileMap.local_to_map(event.position) == $TileMap.local_to_map(player.position):
				player.toggleSelect()
				

func centerOnTile(pos):
	return $TileMap.map_to_local($TileMap.local_to_map(pos))
	
func isPassable(pos):
	return $TileMap.get_cell_tile_data(0,$TileMap.local_to_map(pos),false).get_custom_data("isPassable")

func isValidGroundMovement(startPos, endPos, speed):
	if centerOnTile(endPos) == centerOnTile(startPos):
		return true
	elif speed == 0:
		return false
	else:
		var tileSize = $TileMap.tile_set.tile_size.x
		var tileDiagonalSize = int(tileSize * sqrt(2)/2)
		var upHex = centerOnTile(startPos + Vector2(0, -1 * tileSize))
		var upRightHex = centerOnTile(startPos + Vector2(tileDiagonalSize, -1 * tileDiagonalSize))
		var upLeftHex = centerOnTile(startPos + Vector2(-1 * tileDiagonalSize, -1 * tileDiagonalSize))
		var downHex = centerOnTile(startPos + Vector2(0, tileSize))
		var downRightHex = centerOnTile(startPos + Vector2(tileDiagonalSize, tileDiagonalSize))
		var downLeftHex = centerOnTile(startPos + Vector2(-1 * tileDiagonalSize, tileDiagonalSize))
		var validPathFound = false
		if not(validPathFound) and isPassable(upHex):
			validPathFound = validPathFound or isValidGroundMovement(upHex, endPos, speed-1)
		if not(validPathFound) and isPassable(upRightHex):
			validPathFound = validPathFound or isValidGroundMovement(upRightHex, endPos, speed-1)
		if not(validPathFound) and isPassable(upLeftHex):
			validPathFound = validPathFound or isValidGroundMovement(upLeftHex, endPos, speed-1)
		if not(validPathFound) and isPassable(downHex):
			validPathFound = validPathFound or isValidGroundMovement(downHex, endPos, speed-1)
		if not(validPathFound) and isPassable(downRightHex):
			validPathFound = validPathFound or isValidGroundMovement(downRightHex, endPos, speed-1)
		if not(validPathFound) and isPassable(downLeftHex):
			validPathFound = validPathFound or isValidGroundMovement(downLeftHex, endPos, speed-1)
		return validPathFound
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
