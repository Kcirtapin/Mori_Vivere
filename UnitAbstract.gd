extends Node2D

class_name UnitAbstract

var hitPoints = 0
var maxHitPoints = 0
var speed = 0
var attack = 0
var defense = 0
var dead = false


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func initialize(maxHP, spd, atk, def):
	hitPoints = maxHP
	maxHitPoints = maxHP
	speed = spd
	attack = atk
	defense = def
	

func takeHit(dmg, isBlockable):
	#Uses defense to reduce damage if applicable
	if isBlockable:
		dmg-=defense
		#Exits method if damage is reduced to nothing
		if dmg<=0:
			return
	#Kills off unit if HP reaches 0
	if hitPoints-dmg <= 0:
		hitPoints = 0
		die()
	#In case of negative damage to heal, and the damage would heal beyond max HP
	elif (hitPoints-dmg >= maxHitPoints):
		hitPoints = maxHitPoints
	#Damage is taken, and hp is reduced to a non-zero amount or increased to a number below max HP
	else:
		hitPoints-=dmg
		
	

func die():
	#This is meant to be overriden by a parent node or otherwise edited.
	dead = true
	queue_free()
	

