extends Node2D

@export var Menu: PackedScene

var menuEnabled = false
var exitMenu

@export var allied_unit: PackedScene
@export var enemy_unit: PackedScene
var unit
var playerTurn = true
var enemies = []
var allies = []

# Called when the node enters the scene tree for the first time.
func _ready():
	allies.append(allied_unit.instantiate())
	allies.append(allied_unit.instantiate())
	var alliedSpawnCoords = [Vector2(5,1),Vector2(6,1)]
	for a in range(len(allies)):
		allies[a].position = $TileMap.map_to_local(alliedSpawnCoords[a])
		add_child(allies[a])
	enemies.append(enemy_unit.instantiate())
	for e in enemies:
		e.position = $TileMap.map_to_local(Vector2(14,5))
		add_child(e)

func _input(event):
	if event is InputEventMouseButton and playerTurn and not(menuEnabled):
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			#Checks if the click was on a unit
			if unit == null or not(unit.selected):
				unit = getClickedUnit(event.position)
			#If a unit was clicked or is already selected
			if unit != null:
				#Moves the unit to the clicked location
				if unit.selected and $TileMap.get_cell_source_id(0,$TileMap.local_to_map(event.position)) == 3:
					#THIS WILL CAUSE A BUG IF ANYTHING HAPPENS TO PLAYER POSITION OR SPEED
					#IN BETWEEN PLAYER SELECTION AND THE MOVEMENT.
					var validMovementTiles = []
					validGroundMovements(centerOnTile(unit.position),unit.getSpeed(),true,"allied", validMovementTiles)
					flipTile(0,validMovementTiles)
					unit.position = centerOnTile(event.position)
					var adjEnemiesList = getAdjacentEnemies(unit,"good")
					if len(adjEnemiesList) > 0:
						flipTile(2,adjEnemiesList)
					else:
						unit.toggleReady(false)
						unit.toggleSelect(false)
				
				elif unit.selected and $TileMap.get_cell_source_id(0,$TileMap.local_to_map(event.position)) == 2:
					var adjEnemiesList = getAdjacentEnemies(unit,"good")
					flipTile(0,adjEnemiesList)
					for e in enemies:
						if e.position == centerOnTile(event.position):
							e.takeHit(unit.getAttack(),true)
					unit.toggleSelect(false)
					unit.toggleReady(false)
				#Selects the unit and highlights options
				elif not(unit.selected) and $TileMap.local_to_map(event.position) == $TileMap.local_to_map(unit.position) and unit.isReady:
					unit.toggleSelect(true)
					var validMovementTiles = []
					validGroundMovements(centerOnTile(unit.position),unit.getSpeed(),true,"allied", validMovementTiles)
					flipTile(3,validMovementTiles)

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

func getClickedUnit(pos):
	var centeredPos = centerOnTile(pos)
	for a in allies:
		if a.position == centeredPos:
			return a
	return null

func getAdjacentEnemies(unit, alignment:String):
	var adjList = getAdjacentTiles(centerOnTile(unit.position))
	var adjEnemyList = []
	if alignment == "good":
		for e in enemies:
			if e.position in adjList:
				adjEnemyList.append(e.position)
	return adjEnemyList

#Flips tiles to their highlit state
#Atlas layer guide: 0=base state, 2=attackable state, 3=movableState
func flipTile(atlasLayer:int,posList:Array):
	for pos in posList:
		$TileMap.set_cell(0,$TileMap.local_to_map(pos),atlasLayer,Vector2i(0,0))

#Takes a local vector2 of position, and returns the local vector2 position centered on the nearest tile
func centerOnTile(pos:Vector2):
	return $TileMap.map_to_local($TileMap.local_to_map(pos))

#Checks if anything would impede movement on the specified tile. Uses local coordinates, but must already be centered
#Alignment values: "allied", "enemy". All other values will treat units as impassable
func isPassable(pos:Vector2, alignment:String):
	if alignment != "allied":
		for a in allies:
			if pos == a.position:
				return false
	if alignment != "enemy":
		for e in enemies:
			if pos == e.position:
				return false
	return $TileMap.get_cell_tile_data(0,$TileMap.local_to_map(pos),false).get_custom_data("isPassable")

func validGroundMovements(startPos:Vector2, speed:int, validTarget:bool, alignment:String, tileList:Array):
	if validTarget:
		tileList.append(startPos)
	if speed == 0:
		return
	else:
		var adjTileList = getAdjacentTiles(startPos)
		for tile in adjTileList:
			if isPassable(tile,"none"):
				validGroundMovements(tile, speed-1, true, alignment, tileList)
			elif isPassable(tile,alignment):
				validGroundMovements(tile, speed-1, false, alignment, tileList)

func getAdjacentTiles(pos:Vector2):
	var tileSize = $TileMap.tile_set.tile_size.x
	var tileDiagonalSize = int(tileSize * sqrt(2)/2)
	var upHex = centerOnTile(pos + Vector2(0, -1 * tileSize))
	var upRightHex = centerOnTile(pos + Vector2(tileDiagonalSize, -1 * tileDiagonalSize))
	var upLeftHex = centerOnTile(pos + Vector2(-1 * tileDiagonalSize, -1 * tileDiagonalSize))
	var downHex = centerOnTile(pos + Vector2(0, tileSize))
	var downRightHex = centerOnTile(pos + Vector2(tileDiagonalSize, tileDiagonalSize))
	var downLeftHex = centerOnTile(pos + Vector2(-1 * tileDiagonalSize, tileDiagonalSize))
	return [upHex,upRightHex,downRightHex,downHex,downLeftHex,upLeftHex]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if menuEnabled and not(has_node("Menu")):
		menuEnabled = false
		get_tree().paused = false
	$EndTurnButton.position = get_viewport_rect().size - $EndTurnButton.size
	if playerTurn == true:
		var noRemainingMoves = true
		for a in allies:
			if a.isReady:
				noRemainingMoves = false
		if noRemainingMoves:
			_on_end_turn_button_pressed()

func _on_enemy_turn_label_timer_timeout():
	playerTurn = true
	for enemy in enemies:
		doEnemyTurn(enemy)
	$EnemyTurnLabel.hide()
	$EnemyTurnLabelTimer.stop()
	for a in allies:
		a.toggleReady(true)
	$EndTurnButton.disabled = false

func doEnemyTurn(enemy):
	if enemy.getAiType() == "basic":
		var target = null
		for a in allies:
			if target == null or (a.position - enemy.position).length_squared() < (target.position - enemy.position).length_squared():
				target = a

func removeEnemy(enemy):
	for i in range(len(enemies)):
		if enemies[i] == enemy:
			enemies.remove_at(i)

func _on_end_turn_button_pressed():
	playerTurn = false
	$EndTurnButton.disabled = true
	$EnemyTurnLabel.show()
	$EnemyTurnLabel.position = Vector2(get_viewport_rect().size/2)-$EnemyTurnLabel.size/2
	$EnemyTurnLabelTimer.start()
