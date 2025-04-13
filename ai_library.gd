extends Node2D

var allies
var enemies
var tileMap

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func initialize(a, e, t):
	allies = a
	enemies = e
	tileMap = t
## Helper functions ##
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

func getAdjacentEnemies(unit, alignment:String, getUnits:bool):
	var adjList = getAdjacentTiles(centerOnTile(unit.position))
	var adjEnemyList = []
	

	if alignment == "allied":
		for e in enemies:
			if e.position in adjList:
				if getUnits:
					adjEnemyList.append(e)
				else:
					adjEnemyList.append(e.position)
				
	if alignment == "enemy":
		for a in allies:
			if a.position in adjList:
				if getUnits:
					adjEnemyList.append(a)
				else:
					adjEnemyList.append(a.position)
				
	return adjEnemyList

func getPathToGood(startPos, endPos):
	var routeList = []
	var MAX_MOVES = 10
	var routeNotFound = true
	var crntRoute = [startPos]
	#The 0 in the usedTiles dictionary is a dummy value. usedTiles is essentially a set
	var usedTiles = {startPos:0}
	routeList.append(crntRoute)
	while routeNotFound and len(routeList) > 0:
		crntRoute = routeList.pop_front()
		#print(crntRoute)
		if crntRoute[len(crntRoute)-1] == endPos:
			crntRoute.pop_back()
			return crntRoute
		elif len(crntRoute) <= MAX_MOVES:
			var adjTiles = getAdjacentTiles(crntRoute[len(crntRoute)-1])
			for tile in adjTiles:
				if tile not in usedTiles.keys():
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
		if len(potentialRouteList) < len(targetList):
			target = a
			targetList = potentialRouteList
	var speed = enemy.getSpeed()
	var cost = tileMap.get_cell_tile_data(0,tileMap.local_to_map(targetList[0]),false).get_custom_data("moveCost")
	while speed >= cost and len(targetList) > 0:
		print(speed)
		enemy.position = targetList.pop_front()
		cost = tileMap.get_cell_tile_data(0,tileMap.local_to_map(enemy.position),false).get_custom_data("moveCost")
		speed -= cost
	var adjAllies = getAdjacentEnemies(enemy,"enemy",true)
	if len(adjAllies) > 0:
		adjAllies[0].takeHit(enemy.getAttack(),true)


