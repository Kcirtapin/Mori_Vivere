extends Area2D

var AI_TYPE = "ranged"
var FIRE_ID = 7

# Called when the node enters the scene tree for the first time.
func _ready():
	var MAXHP = 6
	var SPEED = 4
	var ATTACK = 8
	var DEFENSE = 0
	var NAME = "Mage"
	var MIN_RANGE = 2
	var MAX_RANGE = 3
	$Unit.initialize(NAME,MAXHP,SPEED,ATTACK,DEFENSE,MIN_RANGE,MAX_RANGE)

func takeHit(dmg:int, isBlockable:bool):
	$Unit.takeHit(dmg,isBlockable)
	checkDeath()

func attack(opponent):
	opponent.takeHit(getAttack(),true)
	return [[opponent.position,FIRE_ID]]

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
