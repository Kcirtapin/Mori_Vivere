extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready():
	var MAXHP = 10
	var SPEED = 3
	var ATTACK = 2
	var DEFENSE = 1
	$Unit.initialize(MAXHP,SPEED,ATTACK,DEFENSE)

func takeTurn():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
