extends Node2D

@export var Menu: PackedScene

var menuEnabled = false
var exitMenu

@export var allied_unit: PackedScene
@export var enemy_unit: PackedScene
@export var victory_msg: PackedScene

var unit
var playerTurn = true
var enemies = []
var allies = []

enum align {ALLY,ENEMY,NEUTRAL}
enum tileSourceIDs {NONE=-1,NORMAL=0,BLOCKER=1,ATTACK=2,MOVEMENT=3,ROUGH=4}
enum tileLayerIDs {TERRAIN=0,OVERLAY=1}

var flippedTiles = []

# Called when the node enters the scene tree for the first time.
func _ready():
	$AI_Library.initialize(allies,enemies,$TileMap)
	$TileMap.add_layer(tileLayerIDs.OVERLAY)
	
	var alliedSpawnCoords = [Vector2(4,3),Vector2(4,5),Vector2(4,7),Vector2(6,8)]
	for a in range(len(alliedSpawnCoords)):
		allies.append(allied_unit.instantiate())
		allies[a].position = $TileMap.map_to_local(alliedSpawnCoords[a])
		add_child(allies[a])
		
	var enemySpawnCoords = [Vector2(12,6), Vector2(12,8), Vector2(14,2), Vector2(20,7), Vector2(21,1)]
	for e in range(len(enemySpawnCoords)):
		enemies.append(enemy_unit.instantiate())
		enemies[e].position = $TileMap.map_to_local(enemySpawnCoords[e])
		add_child(enemies[e])

func _input(event):
	if event is InputEventMouseButton and playerTurn and not(menuEnabled):
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and unit != null:
			deselectUnit()
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			#Checks if the click was on a unit
			if unit == null or not(unit.selected):
				unit = getClickedUnit(event.position)
			#If a unit was clicked or is already selected
			if unit != null:
				
				#Moves the unit to the clicked location
				if unit.selected and $TileMap.get_cell_source_id(tileLayerIDs.OVERLAY,$TileMap.local_to_map(event.position)) == tileSourceIDs.MOVEMENT:
					#THIS WILL CAUSE A BUG IF ANYTHING HAPPENS TO PLAYER POSITION OR SPEED
					#IN BETWEEN PLAYER SELECTION AND THE MOVEMENT.
					flipTile(tileSourceIDs.NONE,flippedTiles)
					unit.position = centerOnTile(event.position)
					var adjEnemiesList = $AI_Library.getAdjacentEnemies(unit,align.ALLY,false)
					if len(adjEnemiesList) > 0:
						flipTile(tileSourceIDs.ATTACK,adjEnemiesList)
					else:
						unit.toggleSelect(false)
						unit.toggleReady(false)
						checkEndOfTurn()
					unit.toggleReady(false)
					
				#If there are attack options availible
				elif unit.selected and $TileMap.get_cell_source_id(tileLayerIDs.OVERLAY,$TileMap.local_to_map(event.position)) == tileSourceIDs.ATTACK:
					var adjEnemiesList = $AI_Library.getAdjacentEnemies(unit,align.ALLY,false)
					flipTile(tileSourceIDs.NONE,adjEnemiesList)
					for e in enemies:
						if e.position == centerOnTile(event.position):
							e.takeHit(unit.getAttack(),true)
					unit.toggleSelect(false)
					unit.toggleReady(false)
					checkEndOfTurn()
				#Selects the unit and highlights options
				elif not(unit.selected) and $TileMap.local_to_map(event.position) == $TileMap.local_to_map(unit.position) and unit.isReady:
					unit.toggleSelect(true)
					flippedTiles = validGroundMovements(centerOnTile(unit.position),unit.getSpeed(),align.ALLY)
					flipTile(tileSourceIDs.MOVEMENT,flippedTiles)
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

func deselectUnit():
	if unit.selected:
		unit.toggleSelect(false)
		flipTile(tileSourceIDs.NONE,flippedTiles)
		var adjEnemiesList = $AI_Library.getAdjacentEnemies(unit,align.ALLY,false)
		flipTile(-1,adjEnemiesList)

func getClickedUnit(pos):
	var centeredPos = centerOnTile(pos)
	for a in allies:
		if a.position == centeredPos:
			return a
	return null

#Flips tiles to their highlit state
#Atlas layer guide: 0=base state, 2=attackable state, 3=movableState
func flipTile(atlasID:int,posList:Array):
	if atlasID != tileSourceIDs.NONE:
		for pos in posList:
			$TileMap.set_cell(tileLayerIDs.OVERLAY,$TileMap.local_to_map(pos),atlasID,Vector2i(0,0))
	else:
		for pos in posList:
			$TileMap.erase_cell(tileLayerIDs.OVERLAY,$TileMap.local_to_map(pos))

#Takes a local vector2 of position, and returns the local vector2 position centered on the nearest tile
func centerOnTile(pos:Vector2):
	return $TileMap.map_to_local($TileMap.local_to_map(pos))

#Use align enum for alignment
func validGroundMovements(startPos:Vector2, speed:int, alignment):
	var returnList = []
	validGroundMovementsRec(startPos,speed,true,alignment,returnList)
	return returnList


func validGroundMovementsRec(startPos:Vector2, speed:int, validTarget:bool, alignment, tileList:Array):
	if validTarget:
		tileList.append(startPos)
	if speed == 0:
		return tileList
	else:
		var adjTileList = getAdjacentTiles(startPos)
		var crntElevation = $TileMap.get_cell_tile_data(tileLayerIDs.TERRAIN,$TileMap.local_to_map(startPos),false).get_custom_data("elevation")
		for tile in adjTileList:
			var cost = $TileMap.get_cell_tile_data(tileLayerIDs.TERRAIN,$TileMap.local_to_map(tile),false).get_custom_data("moveCost")
			if $AI_Library.isPassable(tile,align.NEUTRAL, crntElevation) and speed - cost >= 0:
				validGroundMovementsRec(tile, speed-cost, true, alignment, tileList)
			elif $AI_Library.isPassable(tile,alignment, crntElevation) and speed - cost >= 0:
				validGroundMovementsRec(tile, speed-cost, false, alignment, tileList)
		return tileList

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

func checkEndOfTurn():
	var noRemainingMoves = true
	for a in allies:
		if a.isReady:
			noRemainingMoves = false
	if noRemainingMoves and unit.selected == false and len(enemies) > 0:
		_on_end_turn_button_pressed()

func checkEndOfGame():
	if len(enemies) == 0:
		get_tree().paused = true
		var msg = victory_msg.instantiate()
		add_child(msg)
		msg.position = Vector2(get_viewport_rect().size/2)-$EnemyTurnLabel.size/2
	elif len(allies) == 0:
		get_tree().paused = true
		var msg = victory_msg.instantiate()
		add_child(msg)
		msg.position = Vector2(get_viewport_rect().size/2)-$EnemyTurnLabel.size/2
		msg.changeToDefeat()

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
		$AI_Library.basic_AI(enemy)

func removeEnemy(enemy):
	var indOfRemoval = -1
	for i in range(len(enemies)):
		if enemies[i] == enemy:
			indOfRemoval = i
	if indOfRemoval != -1:
		enemies.remove_at(indOfRemoval)
		checkEndOfGame()

func removeAlly(ally):
	var indOfRemoval = -1
	for i in range(len(allies)):
		if allies[i] == ally:
			indOfRemoval = i
	if indOfRemoval != -1:
		allies.remove_at(indOfRemoval)
		checkEndOfGame()

func _on_end_turn_button_pressed():
	if unit != null:
		unit.toggleSelect(false)
	#Resets overlay
	$TileMap.remove_layer(tileLayerIDs.OVERLAY)
	$TileMap.add_layer(tileLayerIDs.OVERLAY)
	
	playerTurn = false
	$EndTurnButton.disabled = true
	$EnemyTurnLabel.show()
	$EnemyTurnLabel.position = Vector2(get_viewport_rect().size/2)-$EnemyTurnLabel.size/2
	$EnemyTurnLabelTimer.start()
