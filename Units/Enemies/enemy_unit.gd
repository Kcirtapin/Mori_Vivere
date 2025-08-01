extends Area2D

var AI_TYPE = "basic"

# Called when the node enters the scene tree for the first time.
func _ready():
	var MAXHP = 10
	var SPEED = 3
	var ATTACK = 6
	var DEFENSE = 1
	var NAME = "Bad Guy"
	var MIN_RANGE = 1
	var MAX_RANGE = 1
	$Unit.initialize(NAME,MAXHP,SPEED,ATTACK,DEFENSE,MIN_RANGE,MAX_RANGE)

func takeHit(dmg:int, isBlockable:bool):
	$Unit.takeHit(dmg,isBlockable)
	checkDeath()
	

func checkDeath():
	if not(self.has_node("Unit")):
		get_parent().removeEnemy(self)
		queue_free()
		return true
	elif $Unit.dead == true:
		get_parent().removeEnemy(self)
		queue_free()
		return true
	return false

func getSpeed():
	return $Unit.speed

func getMinRange():
	return $Unit.minRange

func getMaxRange():
	return $Unit.maxRange

func getAttack():
	return $Unit.attack

func getHP():
	return $Unit.hitPoints

func getMaxHP():
	return $Unit.maxHitPoints

func getName():
	return $Unit.unitName

func getAiType():
	return AI_TYPE

func resetDefense():
	$Unit.resetDefense()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
