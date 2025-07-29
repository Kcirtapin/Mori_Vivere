extends Node2D

var allies
var enemies
var tileMap
enum align {ALLY,ENEMY,NEUTRAL}


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
		return false
	return tileMap.get_cell_tile_data(0,tileMap.local_to_map(pos),false).get_custom_data("isPassable") and abs(tileMap.get_cell_tile_data(0,tileMap.local_to_map(pos),false).get_custom_data("elevation")-prevElevation) <= 1

#Checks if a unit could occupy this space
#Use align enum for alignment parameter
func isOccupyable(pos:Vector2, prevElevation:int):
	return isPassable(pos,align.NEUTRAL,prevElevation)

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

func getTilesAtRange(pos,minRange,maxRange,getUnits,alignment):
	var outDict = {pos:0}
	for i in range(minRange):
		outDict.merge(expandRangeOne(outDict))
	var removeDict = outDict.duplicate()
	for i in range(minRange,maxRange):
		outDict.merge(expandRangeOne(outDict))
	for p in removeDict:
		outDict.remove(p)
	var outList = []
	for p in outDict:
		outList.append(p)
	if getUnits:
		var unitList = []
		if alignment != align.ALLY:
			for a in allies:
				if a.position in outList:
					unitList.append(a)
		if alignment != align.ENEMY:
			for e in enemies:
				if e.position in outList:
					unitList.append(e)
		return unitList
	else:
		return outList

func expandRangeOne(posDict:Dictionary):
	var outDict = Dictionary()
	for pos in posDict:
		var adjTiles = getAdjacentTiles(pos)
		for tile in adjTiles:
			outDict[tile] = 0
	return outDict

func getPathToGood(startPos, endPos):
	var routeList = DEPQ.new()
	var MAX_MOVES = 15
	var routeNotFound = true
	var crntRoute = [startPos]
	#The 0 in the usedTiles dictionary is a dummy value. usedTiles is essentially a set
	var usedTiles = {startPos:0}
	routeList.add(crntRoute,crntRoute.size())
	while routeNotFound and routeList.size() > 0:
		crntRoute = routeList.pop_min()
		var crntElevation = tileMap.get_cell_tile_data(0,tileMap.local_to_map(crntRoute[len(crntRoute)-1]),false).get_custom_data("elevation")
		#print(crntRoute)
		if crntRoute[len(crntRoute)-1] == endPos:
			if not isOccupyable(crntRoute[len(crntRoute)-1], crntElevation):
				crntRoute.pop_back()
			if isOccupyable(crntRoute[len(crntRoute)-1], crntElevation):
				return crntRoute
		elif len(crntRoute) <= MAX_MOVES:
			var adjTiles = getAdjacentTiles(crntRoute[len(crntRoute)-1])
			for tile in adjTiles:
				if (tile not in usedTiles.keys() and isPassable(tile,align.ENEMY, crntElevation)) or tile == endPos:
					usedTiles[tile] = 0
					var newList = crntRoute.duplicate()
					for i in range(tileMap.get_cell_tile_data(0,tileMap.local_to_map(tile),false).get_custom_data("moveCost")):
						newList.push_back(tile)
					routeList.add(newList,newList.size())
	return [null]

func compareDefenses(a,b):
	var aDef = a.getDefense()
	var bDef = b.getDefense()
	var aHP = a.getHP()
	var bHP = b.getHP()
	if aDef > bDef:
		return true
	elif aDef < bDef:
		return false
	else:
		if aHP > bHP:
			return true
		elif aHP < bHP:
			return false
	return true

func move(path, entity):
	var speed = entity.getSpeed()
	if len(path) > 1:
		path.pop_front()
		while speed >= 1 and len(path) > 0:
			entity.position = path.pop_front()
			speed -= 1
## AI models ##
# Note - no ML used. It's all algorithms
func basic_AI(enemy):
	if len(getAdjacentEnemies(enemy,align.ENEMY,true)) == 0:
		var targetList = getPathToGood(enemy.position,allies[0].position)
		for a in allies:
			var potentialRouteList = getPathToGood(enemy.position,a.position)
			if (len(potentialRouteList) < len(targetList) and potentialRouteList != [null]) or targetList == []:
				targetList = potentialRouteList
		move(targetList,enemy)
		#var speed = enemy.getSpeed()
		#if len(targetList) > 1:
			#targetList.pop_front()
			#while speed >= 1 and len(targetList) > 0:
				#enemy.position = targetList.pop_front()
				#speed -= 1
	var adjAllies = getAdjacentEnemies(enemy,align.ENEMY,true)
	if len(adjAllies) > 0:
		adjAllies[0].takeHit(enemy.getAttack(),true)

#Moves towards closest unit. If there are multiple units in attacking range, attack the one with the lowest defense
func targetSquishyAI(enemy):
	var targetQueue:Array = allies.duplicate()
	var speed = enemy.getSpeed()
	for a in allies:
		var potentialRouteList = getPathToGood(enemy.position,a.position)
		if len(potentialRouteList) > speed or potentialRouteList == [null]:
			targetQueue.remove_at(targetQueue.find(a))
	if len(targetQueue) == 0:
		print("No nearby targets")
		targetQueue = allies.duplicate()
	targetQueue.sort_custom(compareDefenses)
	print(targetQueue)
	var adjTargets = getAdjacentEnemies(enemy,align.ENEMY,true)
	if targetQueue[len(targetQueue)-1] in adjTargets:
		adjTargets.pop_back().takeHit(enemy.getAttack(),true)
	else:
		move(getPathToGood(enemy.position, targetQueue.pop_back().position),enemy)
		adjTargets = getAdjacentEnemies(enemy,align.ENEMY,true)
		if len(adjTargets) > 0:
			adjTargets.sort_custom(compareDefenses)
			adjTargets.pop_back().takeHit(enemy.getAttack(),true)
