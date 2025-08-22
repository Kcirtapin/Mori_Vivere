extends Control

var tileName:String = ""
var elevation:int = 0
var moveCost:int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func initialize(tile:TileData):
	moveCost = tile.get_custom_data("moveCost")
	tileName = tile.get_custom_data("name")
	elevation = tile.get_custom_data("elevation")
	$TileName.text = tileName
	$Elevation.text = "     Elevation: "+str(elevation)
	$MoveCost.text = "   Move Cost: "+str(moveCost)

func delete():
	queue_free()

