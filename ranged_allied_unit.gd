extends Area2D


var selected = false
var isReady = true

# Called when the node enters the scene tree for the first time.
func _ready():
	var MAXHP = 6
	var SPEED = 4
	var ATTACK = 7
	var DEFENSE = 0
	var MIN_RANGE = 2
	var MAX_RANGE = 2
	var NAME = "Archer"
	$Unit.initialize(NAME,MAXHP,SPEED,ATTACK,DEFENSE,MIN_RANGE,MAX_RANGE)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not(self.has_node("Unit")):
		queue_free()
	if not(self.has_node("Unit")):
		get_parent().removeAlly(self)
		queue_free()

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

func getDefense():
	return $Unit.defense

func resetDefense():
	$Unit.resetDefense()

func takeHit(dmg:int, isBlockable:bool):
	$Unit.takeHit(dmg,isBlockable)

func toggleSelect(sel:bool):
	selected = sel
	if selected:
		$AnimatedSprite2D.animation = "selected"
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.animation = "base"
		$AnimatedSprite2D.stop()

func toggleReady(ready):
	isReady = ready

func _to_string():
	return "HP="+str(getHP())+", Def="+str(getDefense())
