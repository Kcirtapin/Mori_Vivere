extends Area2D
class_name allied_unit

var selected = false

# Called when the node enters the scene tree for the first time.
func _ready():
	var MAXHP = 10
	var SPEED = 3
	var ATTACK = 2
	var DEFENSE = 1
	$Unit.initialize(MAXHP,SPEED,ATTACK,DEFENSE)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not(self.has_node("Unit")):
		queue_free()

func getSpeed():
	return $Unit.speed

func toggleSelect(sel):
	selected = sel
	if selected:
		$AnimatedSprite2D.animation = "selected"
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.animation = "base"
		$AnimatedSprite2D.stop()
