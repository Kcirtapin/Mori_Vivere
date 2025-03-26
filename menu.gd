extends Node2D
class_name Menu

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_yes_button_pressed():
	get_tree().quit()

func _on_no_button_pressed():
	$MenuHeader.show()
	$Return.show()
	$EndTurn.show()
	$Quit.show()
	$QuitConfirm.hide()
	$YesButton.hide()
	$NoButton.hide()


func _on_return_pressed():
	queue_free()


func _on_quit_pressed():
	$MenuHeader.hide()
	$Return.hide()
	$EndTurn.hide()
	$Quit.hide()
	$QuitConfirm.show()
	$YesButton.show()
	$NoButton.show()


func _on_end_turn_pressed():
	get_parent().playerTurn = false
	queue_free()
	
