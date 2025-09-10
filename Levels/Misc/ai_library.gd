extends Node2D

var allies
var enemies
var tileMap:TileMap


enum align {ALLY,ENEMY,NEUTRAL}
enum tileSourceIDs {NONE=-1,NORMAL=0,BLOCKER=1,ATTACK=2,MOVEMENT=3,ROUGH=4,MOUSE=6,FIRE=7,CORPSE=8}
enum tileLayerIDs {TERRAIN=0,EFFECTS=1,MOUSE=2,OVERLAY=3}


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

func getTilesAtRange(pos,minRange,maxRange,getUnits:bool,alignment=align.NEUTRAL):
	var outDict = {pos:0}
	for i in range(minRange-1):
		outDict.merge(expandRangeOne(outDict))
	#print("OutDict 1:  ",outDict)
	var removeDict = outDict.duplicate()
	for i in range(minRange,maxRange+1):
		outDict.merge(expandRangeOne(outDict))
	#print("OutDict 2:  ",outDict)
	for p in removeDict:
		outDict.erase(p)
	#print("OutDict 3:  ",outDict)
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
	return getPathToPosList(startPos, [endPos])

func getPathToPosList(startPos, endPosList):
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
		if crntRoute[len(crntRoute)-1] in endPosList:
			while not(isOccupyable(crntRoute[len(crntRoute)-1], crntElevation)) and len(crntRoute) > 1:
				crntRoute.pop_back()
			if isOccupyable(crntRoute[len(crntRoute)-1], crntElevation):
				return crntRoute
		elif len(crntRoute) <= MAX_MOVES:
			var adjTiles = getAdjacentTiles(crntRoute[len(crntRoute)-1])
			for tile in adjTiles:
				if (tile not in usedTiles.keys() and isPassable(tile,align.ENEMY, crntElevation)) or tile in endPosList:
					usedTiles[tile] = 0
					var newList = crntRoute.duplicate()
					if tileMap.get_cell_tile_data(tileLayerIDs.EFFECTS,tileMap.local_to_map(tile)) == null:
						for i in range(tileMap.get_cell_tile_data(tileLayerIDs.TERRAIN,tileMap.local_to_map(tile)).get_custom_data("moveCost")):
							newList.push_back(tile)
					else:
						for i in range(tileMap.get_cell_tile_data(tileLayerIDs.TERRAIN,tileMap.local_to_map(tile)).get_custom_data("moveCost")+tileMap.get_cell_tile_data(tileLayerIDs.EFFECTS,tileMap.local_to_map(tile)).get_custom_data("moveCost")):
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

func addEffect(pos:Vector2i, effect:int):
	tileMap.set_cell(tileLayerIDs.EFFECTS, tileMap.local_to_map(pos), effect, Vector2i.ZERO)
## AI modes ##
# Note - no ML used. It's all algorithms
func basic_AI(enemy):
	if len(getAdjacentEnemies(enemy,align.ENEMY,true)) == 0:
		#print("No adjacent enemies")
		var targetList = [null]
		for a in allies:
			var potentialRouteList = getPathToGood(enemy.position,a.position)
			if (len(potentialRouteList) < len(targetList) and potentialRouteList != [null]) or targetList == [null]:
				targetList = potentialRouteList
		#print("moving: ",targetList)
		move(targetList,enemy)
	var adjAllies = getAdjacentEnemies(enemy,align.ENEMY,true)
	if len(adjAllies) > 0:
		var effects = enemy.attack(adjAllies[0])
		for e in effects:
			addEffect(e[0],e[1])

#Moves towards closest unit. If there are multiple units in attacking range, attack the one with the lowest defense
func targetSquishyAI(enemy):
	var targetQueue:Array = allies.duplicate()
	var speed = enemy.getSpeed()
	for a in allies:
		var potentialRouteList = getPathToGood(enemy.position,a.position)
		if len(potentialRouteList) > speed or potentialRouteList == [null]:
			targetQueue.remove_at(targetQueue.find(a))
	if len(targetQueue) == 0:
		#print("No nearby targets")
		targetQueue = allies.duplicate()
	targetQueue.sort_custom(compareDefenses)
	#print(targetQueue)
	var adjTargets = getAdjacentEnemies(enemy,align.ENEMY,true)
	if targetQueue[len(targetQueue)-1] in adjTargets:
		var effects = enemy.attack(targetQueue.pop_back())
		for e in effects:
			addEffect(e[0],e[1])
	else:
		move(getPathToGood(enemy.position, targetQueue.pop_back().position),enemy)
		adjTargets = getAdjacentEnemies(enemy,align.ENEMY,true)
		if len(adjTargets) > 0:
			adjTargets.sort_custom(compareDefenses)
			var effects = enemy.attack(adjTargets.pop_back())
			for e in effects:
				addEffect(e[0],e[1])

func basicRangedAI(enemy):
	var targetQueue:Array = allies.duplicate()
	targetQueue.sort_custom(compareDefenses)
	var validTarget = false
	var shortestPath = [null]
	while not(validTarget) and len(targetQueue) != 0:
		var crntTarget = targetQueue.pop_back()
		var targetTiles = getTilesAtRange(crntTarget.position,enemy.getMinRange(),enemy.getMaxRange(),false)
		var targetPath = getPathToPosList(enemy.position,targetTiles)
		if len(targetPath) <= enemy.getSpeed():
			validTarget = true
			#Need to fix getPath function to add last tile so that the unit actually moves to within range
			move(targetPath,enemy)
			var effects = enemy.attack(crntTarget)
			for e in effects:
				addEffect(e[0],e[1])
			return
		if len(targetPath) < len(shortestPath) or shortestPath == [null]:
			shortestPath = targetPath
	if shortestPath != [null]:
		move(shortestPath,enemy)
