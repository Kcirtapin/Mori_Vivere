extends Node2D

var allies
var enemies
var tileMap
enum align {ALLY,ENEMY,NEUTRAL}
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

#Must be initialized with a list of enemies, allies, and a tilemap. "Ally" and "enemy" are from the player's perspective
func initialize(a, e, t):
	allies = a
	enemies = e
	tileMap = t

## Helper functions ##
#Checks if anything would impede movement on the specified tile. Uses local coordinates, but must already be centered
#Use align enum for alignment parameter
func isPassable(pos:Vector2, alignment, prevElevation:int):
	pos = centerOnTile(pos)
	if alignment != align.ALLY:
		for a in allies:
			if pos == a.position:
				return false
	if alignment != align.ENEMY:
		for e in enemies:
			if pos == e.position:
				return false
	if tileMap.get_cell_tile_data(0,tileMap.local_to_map(pos),false) == null:
		tileMap.get_cell_tile_data(0,tileMap.local_to_map(pos),false)
		return false
	return tileMap.get_cell_tile_data(0,tileMap.local_to_map(pos),false).get_custom_data("isPassable") and abs(tileMap.get_cell_tile_data(0,tileMap.local_to_map(pos),false).get_custom_data("elevation")-prevElevation) <= 1

func centerOnTile(pos:Vector2):
	return tileMap.map_to_local(tileMap.local_to_map(pos))

func getAdjacentTiles(pos:Vector2):
	var tileSize = tileMap.tile_set.tile_size.x
	var tileDiagonalSize = int(tileSize * sqrt(2)/2)
	var upHex = centerOnTile(pos + Vector2(0, -1 * tileSize))
	var upRightHex = centerOnTile(pos + Vector2(tileDiagonalSize, -1 * tileDiagonalSize))
	var upLeftHex = centerOnTile(pos + Vector2(-1 * tileDiagonalSize, -1 * tileDiagonalSize))
	var downHex = centerOnTile(pos + Vector2(0, tileSize))
	var downRightHex = centerOnTile(pos + Vector2(tileDiagonalSize, tileDiagonalSize))
	var downLeftHex = centerOnTile(pos + Vector2(-1 * tileDiagonalSize, tileDiagonalSize))
	return [upHex,upRightHex,downRightHex,downHex,downLeftHex,upLeftHex]

func getAdjacentEnemies(unit, alignment, getUnits:bool):
	var adjList = getAdjacentTiles(centerOnTile(unit.position))
	var adjEnemyList = []
	

	if alignment == align.ALLY:
		for e in enemies:
			if e.position in adjList:
				if getUnits:
					adjEnemyList.append(e)
				else:
					adjEnemyList.append(e.position)
				
	if alignment == align.ENEMY:
		for a in allies:
			if a.position in adjList:
				if getUnits:
					adjEnemyList.append(a)
				else:
					adjEnemyList.append(a.position)
				
	return adjEnemyList

func getPathToGood(startPos, endPos):
	var routeList = []
	var MAX_MOVES = 15
	var routeNotFound = true
	var crntRoute = [startPos]
	#The 0 in the usedTiles dictionary is a dummy value. usedTiles is essentially a set
	var usedTiles = {startPos:0}
	routeList.append(crntRoute)
	while routeNotFound and len(routeList) > 0:
		crntRoute = routeList.pop_front()
		var crntElevation = tileMap.get_cell_tile_data(0,tileMap.local_to_map(crntRoute[len(crntRoute)-1]),false).get_custom_data("elevation")
		#print(crntRoute)
		if crntRoute[len(crntRoute)-1] == endPos:
			if not isPassable(crntRoute[len(crntRoute)-1], align.ENEMY, crntElevation):
				crntRoute.pop_back()
			return crntRoute
		elif len(crntRoute) <= MAX_MOVES:
			var adjTiles = getAdjacentTiles(crntRoute[len(crntRoute)-1])
			for tile in adjTiles:
				if (tile not in usedTiles.keys() and isPassable(tile,align.ENEMY, crntElevation)) or tile == endPos:
					usedTiles[tile] = 0
					var newList = crntRoute.duplicate()
					newList.push_back(tile)
					routeList.push_back(newList)
	return []
## AI models ##
# Note - no ML used. It's all algorithms
func basic_AI(enemy):
	var target = allies[0]
	var targetList = getPathToGood(enemy.position,allies[0].position)
	for a in allies:
		var potentialRouteList = getPathToGood(enemy.position,a.position)
		if (len(potentialRouteList) < len(targetList) and potentialRouteList != []) or targetList == []:
			target = a
			targetList = potentialRouteList
	var speed = enemy.getSpeed()
	if len(targetList) > 1:
		targetList.pop_front()
		var cost = tileMap.get_cell_tile_data(0,tileMap.local_to_map(targetList[0]),false).get_custom_data("moveCost")
		while speed >= cost and len(targetList) > 0:
			enemy.position = targetList.pop_front()
			speed -= cost
			if len(targetList) > 0:
				cost = tileMap.get_cell_tile_data(0,tileMap.local_to_map(targetList[0]),false).get_custom_data("moveCost")
	var adjAllies = getAdjacentEnemies(enemy,align.ENEMY,true)
	if len(adjAllies) > 0:
		adjAllies[0].takeHit(enemy.getAttack(),true)


