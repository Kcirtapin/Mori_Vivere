extends Area2D
class_name allied_unit

var selected = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$Unit.initialize(10,3,2,1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not(self.has_node("Unit")):
		queue_free()



func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			selected = not(selected)
			if selected:
				$AnimatedSprite2D.animation = "selected"
				$AnimatedSprite2D.play()
			else:
				$AnimatedSprite2D.animation = "base"
				$AnimatedSprite2D.stop()
				
