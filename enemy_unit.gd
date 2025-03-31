extends Area2D

var AI_TYPE = "basic"

# Called when the node enters the scene tree for the first time.
func _ready():
	var MAXHP = 10
	var SPEED = 3
	var ATTACK = 6
	var DEFENSE = 1
	$Unit.initialize(MAXHP,SPEED,ATTACK,DEFENSE)

func takeHit(dmg:int, isBlockable:bool):
	$Unit.takeHit(dmg,isBlockable)

func getSpeed():
	return $Unit.speed

func getAttack():
	return $Unit.attack

func getAiType():
	return AI_TYPE

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not(self.has_node("Unit")):
		get_parent().removeEnemy(self)
		queue_free()
