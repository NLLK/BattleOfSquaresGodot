extends Object
class_name ScanningForEnd

var squareToPlace
var area1
var area2
var whoPlays

var isCollingWithSquares = false
var bordersCollidingWithPlayer = {"player1": 0, "player2": 0}
func _ready():
	pass

func start(squareToPlace, area1, area2, whoPlays):
	self.squareToPlace = squareToPlace
	self.area1 = area1
	self.area2 = area2
	self.whoPlays = whoPlays
	mainLoop()

func mainLoop():
	pass

func collidesWithSquare(whichSquare):
	pass
func collidesWithBackground():
	pass
func haveCommonBorder(borderInfo):
	
	pass

func placingRules():
	var answer: bool
	answer = true
	
	#var area1Array = area1.get_children()
	#var area2Array = area2.get_children()
	
	var area1ChildCount = area1.get_child_count()
	var area2ChildCount = area2.get_child_count()
	
	#var squarePosition = currentSquareToPlace.rect_position
	#var squareSize = currentSquareToPlace.get_node("Area2DSquare").get_node("square").rect_size
	
	if isCollingWithSquares != 0:
		answer = false
	
	if whoPlays == 0:	
		if bordersCollidingWithPlayer.player1 == 0:
			answer = false
		else: bordersCollidingWithPlayer.player1 = 0
	
	if whoPlays == 1:
		if bordersCollidingWithPlayer.player2 == 0:
			answer = false
		else: bordersCollidingWithPlayer.player2 = 0
	
	return answer
