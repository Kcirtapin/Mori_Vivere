extends Node2D

@export var Menu: PackedScene

var menuEnabled = false
var exitMenu

@export var allied_unit: PackedScene
@export var enemy_unit: PackedScene
@export var tanky_enemy: PackedScene
@export var victory_msg: PackedScene
@export var terrain_label: PackedScene
@export var unit_label: PackedScene
@export var ranged_allied_unit: PackedScene

var unit
var playerTurn = true
var enemies = []
var allies = []

enum align {ALLY,ENEMY,NEUTRAL}
enum tileSourceIDs {NONE=-1,NORMAL=0,BLOCKER=1,ATTACK=2,MOVEMENT=3,ROUGH=4,MOUSE=6,FIRE=7,CORPSE=8}
enum tileLayerIDs {TERRAIN=0,EFFECTS=1,MOUSE=2,OVERLAY=3}

var flippedTiles = []
var prevMouseOverlay = null


var crntTerrainLabel = null
var crntUnitLabel = null

# Called when the node enters the scene tree for the first time.
func _ready():
	$AI_Library.initialize(allies,enemies,$TileMap)
	$TileMap.add_layer(tileLayerIDs.EFFECTS)
	$TileMap.add_layer(tileLayerIDs.MOUSE)
	$TileMap.add_layer(tileLayerIDs.OVERLAY)
	
	var alliedSpawnCoords = [[Vector2(4,3),"reg"],[Vector2(4,5),"ranged"],[Vector2(4,7),"reg"],[Vector2(6,8),"reg"],[Vector2(6,5),"reg"]]
	for a in range(len(alliedSpawnCoords)):
		if alliedSpawnCoords[a][1] == "reg":
			allies.append(allied_unit.instantiate())
		elif alliedSpawnCoords[a][1] == "ranged":
			allies.append(ranged_allied_unit.instantiate())
		allies[a].position = $TileMap.map_to_local(alliedSpawnCoords[a][0])
		add_child(allies[a])
		
	var enemySpawnCoords = [[Vector2(12,6),"reg"], [Vector2(12,8),"reg"], [Vector2(14,2),"reg"], [Vector2(20,7),"reg"], [Vector2(21,1),"tank"]]
	for e in range(len(enemySpawnCoords)):
		if enemySpawnCoords[e][1] == "reg":
			enemies.append(enemy_unit.instantiate())
		elif enemySpawnCoords[e][1] == "tank":
			enemies.append(tanky_enemy.instantiate())
		enemies[e].position = $TileMap.map_to_local(enemySpawnCoords[e][0])
		add_child(enemies[e])

func _input(event):
	if event is InputEventMouseMotion and playerTurn and not(menuEnabled):
		var newLabelNeeded = false
		if prevMouseOverlay != null and prevMouseOverlay != $TileMap.local_to_map(event.position):
			$TileMap.erase_cell(tileLayerIDs.MOUSE,prevMouseOverlay)
			newLabelNeeded = true
		prevMouseOverlay = $TileMap.local_to_map(event.position)
		$TileMap.set_cell(tileLayerIDs.MOUSE,prevMouseOverlay,tileSourceIDs.MOUSE,Vector2i.ZERO)
		var terrainTile = $TileMap.get_cell_tile_data(tileLayerIDs.TERRAIN,prevMouseOverlay)
		if terrainTile != null and newLabelNeeded:
			if crntTerrainLabel != null:
				crntTerrainLabel.delete()
				if crntUnitLabel != null:
					crntUnitLabel.delete()
			crntTerrainLabel = terrain_label.instantiate()
			add_child(crntTerrainLabel)
			crntTerrainLabel.initialize(terrainTile)
			crntTerrainLabel.position = Vector2.ZERO
			var hoveredUnit = getUnitAt(event.position)
			if hoveredUnit != null:
				crntUnitLabel = unit_label.instantiate()
				add_child(crntUnitLabel)
				crntUnitLabel.initialize(hoveredUnit.getName(),hoveredUnit.getHP(),hoveredUnit.getMaxHP())
				crntUnitLabel.position = Vector2(crntTerrainLabel.size.x*1.2,0)

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
					if not(highlightAttacks(unit)):
						#print("No attacking options")
						unit.toggleSelect(false)
						unit.toggleReady(false)
						checkEndOfTurn()
					unit.toggleReady(false)
					
				#If there are attack options availible
				elif unit.selected and $TileMap.get_cell_source_id(tileLayerIDs.OVERLAY,$TileMap.local_to_map(event.position)) == tileSourceIDs.ATTACK:
					flipTile(tileSourceIDs.NONE,flippedTiles)
					for e in enemies:
						if e.position == centerOnTile(event.position):
							e.takeHit(unit.getAttack(),true)
							crntUnitLabel.updateHealthBar(e.getHP(),e.getMaxHP())
					unit.toggleSelect(false)
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

func highlightAttacks(crntUnit):
	var options = $AI_Library.getTilesAtRange(crntUnit.position,crntUnit.getMinRange(),crntUnit.getMaxRange(),true,align.ALLY)
	#print(options)
	if len(options) > 0:
		flippedTiles = []
		flippedTiles.resize(len(options))
		for o in range(len(options)):
			flippedTiles[o] = options[o].position
		flipTile(tileSourceIDs.ATTACK,flippedTiles)
		return true
	return false
		
func deselectUnit():
	if unit.selected:
		unit.toggleSelect(false)
		flipTile(tileSourceIDs.NONE,flippedTiles)

func getClickedUnit(pos):
	var centeredPos = centerOnTile(pos)
	for a in allies:
		if a.position == centeredPos:
			return a
	return null

func getUnitAt(pos):
	var centeredPos = centerOnTile(pos)
	for a in allies:
		if a.position == centeredPos:
			return a
	for e in enemies:
		if e.position == centeredPos:
			return e
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
		var crntElevation = $TileMap.get_cell_tile_data(tileLayerIDs.TERRAIN,$TileMap.local_to_map(startPos)).get_custom_data("elevation")
		for tile in adjTileList:
			var cost = 0
			if $TileMap.get_cell_tile_data(tileLayerIDs.EFFECTS,$TileMap.local_to_map(tile)) == null:
				cost = $TileMap.get_cell_tile_data(tileLayerIDs.TERRAIN,$TileMap.local_to_map(tile)).get_custom_data("moveCost")
			else:
				cost = $TileMap.get_cell_tile_data(tileLayerIDs.TERRAIN,$TileMap.local_to_map(tile)).get_custom_data("moveCost") + $TileMap.get_cell_tile_data(tileLayerIDs.EFFECTS,$TileMap.local_to_map(tile)).get_custom_data("moveCost")
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
	#print("Checking end of turn")
	var noRemainingMoves = true
	for a in allies:
		if a.isReady:
			#print("Some move remains")
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
		a.resetDefense()
		a.toggleReady(true)
	$EndTurnButton.disabled = false

func doEnemyTurn(enemy):
	if enemy.getAiType() == "basic":
		$AI_Library.basic_AI(enemy)
	elif enemy.getAiType() == "weakest":
		$AI_Library.targetSquishyAI(enemy)

func removeEnemy(enemy):
	var indOfRemoval = -1
	for i in range(len(enemies)):
		if enemies[i] == enemy:
			indOfRemoval = i
	if indOfRemoval != -1:
		$TileMap.set_cell(tileLayerIDs.EFFECTS,$TileMap.local_to_map(enemies[indOfRemoval].position),tileSourceIDs.CORPSE,Vector2i.ZERO)
		enemies.remove_at(indOfRemoval)
		checkEndOfGame()

func removeAlly(ally):
	var indOfRemoval = -1
	for i in range(len(allies)):
		if allies[i] == ally:
			indOfRemoval = i
	if indOfRemoval != -1:
		$TileMap.set_cell(tileLayerIDs.EFFECTS,$TileMap.local_to_map(allies[indOfRemoval].position),tileSourceIDs.CORPSE,Vector2i.ZERO)
		allies.remove_at(indOfRemoval)
		checkEndOfGame()

func _on_end_turn_button_pressed():
	if unit != null:
		unit.toggleSelect(false)
	#Resets overlay
	$TileMap.remove_layer(tileLayerIDs.OVERLAY)
	$TileMap.add_layer(tileLayerIDs.OVERLAY)
	
	for e in enemies:
		e.resetDefense()
	playerTurn = false
	$EndTurnButton.disabled = true
	$EnemyTurnLabel.show()
	$EnemyTurnLabel.position = Vector2(get_viewport_rect().size/2)-$EnemyTurnLabel.size/2
	$EnemyTurnLabelTimer.start()
