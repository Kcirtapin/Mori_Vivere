extends Control

var unitName:String = ""
var HP:int = 0
var maxHP:int = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func initialize(name, crntHealth, maxHealth):
	unitName = name
	HP = float(crntHealth)
	maxHP = float(maxHealth)
	$UnitName.text = unitName
	$HealthNumber.text = "     HP:   "+str(HP)+"/"+str(maxHP)
	$HPGaugeMeter.apply_scale(Vector2(float(HP)/float(maxHP),1.0))

func delete():
	queue_free()
