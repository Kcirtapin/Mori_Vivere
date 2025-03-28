extends Node2D

@export var Menu: PackedScene

var menuEnabled = false
var exitMenu

@export var allied_unit: PackedScene
var player
var playerTurn = true
var enemies = []
var allies = []

# Called when the node enters the scene tree for the first time.
func _ready():
	player = allied_unit.instantiate()
	player.position = $TileMap.map_to_local(Vector2(5,1))
	add_child(player)
	allies.append(player)
	$EnemyTurnLabel.hide()
	

func _input(event):
	if event is InputEventMouseButton and playerTurn and not(menuEnabled):
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			#Moves the unit to the clicked location
			if player.selected and $TileMap.get_cell_source_id(0,$TileMap.local_to_map(event.position)) == 3:
				#THIS WILL CAUSE A BUG IF ANYTHING HAPPENS TO PLAYER POSITION OR SPEED
				#IN BETWEEN PLAYER SELECTION AND THE MOVEMENT.
				var validMovementTiles = []
				validGroundMovements(centerOnTile(player.position),player.getSpeed(), validMovementTiles)
				flipTile(false,validMovementTiles)
				player.position = centerOnTile(event.position)
				player.toggleSelect(false)
				
			#Selects the unit and highlights options
			elif not(player.selected) and $TileMap.local_to_map(event.position) == $TileMap.local_to_map(player.position):
				player.toggleSelect(true)
				var validMovementTiles = []
				validGroundMovements(centerOnTile(player.position),player.getSpeed(), validMovementTiles)
				flipTile(true,validMovementTiles)
	#Opens pause menu
	if event.is_action_pressed("pauseMenu") and not(menuEnabled):
		exitMenu = Menu.instantiate()
		add_child(exitMenu)
		exitMenu.position = Vector2(get_viewport_rect().size/2)
		menuEnabled = true
		get_tree().paused = true
	#Closes pause menu
	elif event.is_action_pressed("pauseMenu") and menuEnabled:
		menuEnabled = false
		get_tree().paused = false
		exitMenu.queue_free()

#Flips tiles to their highlit state
func flipTile(highlit:bool,posList:Array):
	for pos in posList:
		if highlit:
			$TileMap.set_cell(0,$TileMap.local_to_map(pos),3,Vector2i(0,0))
		else:
			$TileMap.set_cell(0,$TileMap.local_to_map(pos),0,Vector2i(0,0))

#Takes a local vector2 of position, and returns the local vector2 position centered on the nearest tile
func centerOnTile(pos:Vector2):
	return $TileMap.map_to_local($TileMap.local_to_map(pos))
	
func isPassable(pos:Vector2):
	for a in allies:
		if pos == a.position:
			return false
	for e in enemies:
		if pos == e.position:
			return false
	return $TileMap.get_cell_tile_data(0,$TileMap.local_to_map(pos),false).get_custom_data("isPassable")

func validGroundMovements(startPos:Vector2, speed:int, tileList:Array):
	tileList.append(startPos)
	if speed == 0:
		return
	else:
		var tileSize = $TileMap.tile_set.tile_size.x
		var tileDiagonalSize = int(tileSize * sqrt(2)/2)
		var upHex = centerOnTile(startPos + Vector2(0, -1 * tileSize))
		var upRightHex = centerOnTile(startPos + Vector2(tileDiagonalSize, -1 * tileDiagonalSize))
		var upLeftHex = centerOnTile(startPos + Vector2(-1 * tileDiagonalSize, -1 * tileDiagonalSize))
		var downHex = centerOnTile(startPos + Vector2(0, tileSize))
		var downRightHex = centerOnTile(startPos + Vector2(tileDiagonalSize, tileDiagonalSize))
		var downLeftHex = centerOnTile(startPos + Vector2(-1 * tileDiagonalSize, tileDiagonalSize))
		if isPassable(upHex):
			validGroundMovements(upHex, speed-1, tileList)
		if isPassable(upRightHex):
			validGroundMovements(upRightHex, speed-1, tileList)
		if isPassable(upLeftHex):
			validGroundMovements(upLeftHex, speed-1, tileList)
		if isPassable(downHex):
			validGroundMovements(downHex, speed-1, tileList)
		if isPassable(downRightHex):
			validGroundMovements(downRightHex, speed-1, tileList)
		if isPassable(downLeftHex):
			validGroundMovements(downLeftHex, speed-1, tileList)
		return
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if menuEnabled and not(has_node("Menu")):
		menuEnabled = false
		get_tree().paused = false
	if not(playerTurn) and $EnemyTurnLabelTimer.is_stopped():
		$EnemyTurnLabel.show()
		$EnemyTurnLabel.position = Vector2(get_viewport_rect().size/2)-$EnemyTurnLabel.size/2
		$EnemyTurnLabelTimer.start()


func _on_enemy_turn_label_timer_timeout():
	playerTurn = true
	for enemy in enemies:
		doEnemyTurn(enemy)
	$EnemyTurnLabel.hide()
	$EnemyTurnLabelTimer.stop()

func doEnemyTurn(enemy):
	if enemy.getAiType() == "basic":
		return true
