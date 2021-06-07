extends Node

var hideCursorSquare = true #defines do you need to show Square for Cursor or not 
var gameStarted = false #defines are you playing rn or using menu
var cursorSquare #square for cursor
var currentSquareToPlace #that square that player control rn and want to place
var whoPlays = 0 #defines the team who plays
var lastMousePosition = Vector2(320,18)
var howManySquaresColliding = 0
var collidingPlayersStartPoint = 0
var bordersCollidingWithPlayer = {"player1": 0, "player2": 0}
const COLOR_TEAM_ONE = Color("6699ff")
const COLOR_TEAM_TWO = Color("ff3399")
const COLOR_ERROR = Color("ff0000")
const COLOR_CLEAR = Color("ffffff")
var rotationFixVector = Vector2(0,0)

func _ready():
	randomize()
	
func _on_StartGameButton_button_up():
	get_node("StartGameButton").hide()
	get_node("grayBackroundRect").hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)	
	
	cursorSquare = load("res://Scenes/SquareCursor.tscn").instance()
	cursorSquare.modulate = COLOR_TEAM_ONE
	add_child(cursorSquare)
	
	cursorSquare.hide()
	
	gameStarted = true
	#TODO: сделать это действие по анимации рандома
	start_dice_animation_orSmth()
	
func _input(event):
	if gameStarted == true:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT and not event.pressed:
				_on_left_button_click(event.position)
			if event.button_index == BUTTON_WHEEL_UP and event.pressed:
				rotate_squareToPlace(-90)
			if event.button_index == BUTTON_WHEEL_DOWN and event.pressed:
				rotate_squareToPlace(90)
		elif event is InputEventMouseMotion:
			lastMousePosition = event.position
			move_cursor(event.position)	

func _on_left_button_click(mouse_position):
	if not placingRules():
		showErrorOnPlacing()
		return
	else:
		 place_squareToPlace(mouse_position)
	
func placingRules():
	var answer: bool
	answer = true
	var area1 = get_PlayerSquares_node(0)
	var area2 = get_PlayerSquares_node(1)
	
	#var area1Array = area1.get_children()
	#var area2Array = area2.get_children()
	
	var area1ChildCount = area1.get_child_count()
	var area2ChildCount = area2.get_child_count()
	
	#var squarePosition = currentSquareToPlace.rect_position
	#var squareSize = currentSquareToPlace.get_node("Area2DSquare").get_node("square").rect_size
	
	if howManySquaresColliding != 0:
		showErrorOnPlacing()
		answer = false
	
	if whoPlays == 0:	
		if area1ChildCount == 0:
			if collidingPlayersStartPoint != 1:
				answer = false
		else:
			if bordersCollidingWithPlayer.player1 == 0:
				answer = false
			else: bordersCollidingWithPlayer.player1 = 0
	
	if whoPlays == 1:
		if area2ChildCount == 0:
			if collidingPlayersStartPoint != 2:
				answer = false
		else:
			if bordersCollidingWithPlayer.player2 == 0:
				answer = false
			else: bordersCollidingWithPlayer.player2 = 0
	
	return answer
	
func showErrorOnPlacing():
	$errorTimer.start()
	cursorSquare.modulate = COLOR_ERROR
	currentSquareToPlace.modulate = COLOR_ERROR

func move_cursor(position):
	if hideCursorSquare == false:
		cursorSquare.visible = true
		cursorSquare.rect_position = position
		
		var x_pos = stepify(position.x-320, 52)+320
		var y_pos = stepify(position.y, 52)+18
	
		var currentSquarePos = Vector2(x_pos, y_pos)
		
		currentSquareToPlace.rect_position = currentSquarePos + rotationFixVector
	else:
		cursorSquare.hide()
		
func start_dice_animation_orSmth():
	hideCursorSquare = true
	generate_new_square()
	
func generate_new_square():
	var w = randi()%6 + 1
	var h = randi()%6 + 1
	currentSquareToPlace = get_square(w, h)
	currentSquareToPlace.rect_position = lastMousePosition 
	get_node("PlayerSquares").add_child(currentSquareToPlace)
	hideCursorSquare = false
	$beforeEndTimer.start()
	
func place_squareToPlace(mouse_position):
	#starts with clicking LMB
	currentSquareToPlace.modulate = COLOR_CLEAR
	
	get_node("PlayerSquares").remove_child(currentSquareToPlace)
	
	var x_pos = stepify(mouse_position.x-320, 52)+320
	var y_pos = stepify(mouse_position.y, 52)+18
	
	var currentSquareToPlacePos = Vector2(x_pos, y_pos)
	currentSquareToPlace.rect_position = currentSquareToPlacePos + rotationFixVector
	
	get_PlayerSquares_node(whoPlays).add_child(currentSquareToPlace)
	
	rotationFixVector = Vector2(0,0)
	
	change_team()
	start_dice_animation_orSmth() #just creates new square using get_square()

func rotate_squareToPlace(angle):
	currentSquareToPlace.rect_position -= rotationFixVector
	rotationFixVector = Vector2(0,0)
	currentSquareToPlace.rect_rotation +=angle
	if currentSquareToPlace.rect_rotation >=360 or currentSquareToPlace.rect_rotation <=-360:
		currentSquareToPlace.rect_rotation = 0

	var rotation: int 
	rotation = currentSquareToPlace.rect_rotation
	match rotation:
		-270, 90:
			#x-=4
			rotationFixVector.x = 4
		-180, 180:
			#y-=4, x-=4
			rotationFixVector = Vector2(4,4)
		-90, 270:
			#y-=4
			rotationFixVector.y = 4
		_:
			rotationFixVector = Vector2(0,0)
	
	currentSquareToPlace.rect_position += rotationFixVector
		
func change_team():
	if whoPlays == 0:
		cursorSquare.modulate = COLOR_TEAM_TWO
		whoPlays = 1
	else:
		cursorSquare.modulate = COLOR_TEAM_ONE
		whoPlays = 0

func get_square(width, height):
		#get square of a sizes you need with team now plays
	var squareScene
	if whoPlays == 0:
		squareScene = load("res://Scenes/SquarePlayerOne.tscn").instance()
	else:
		squareScene = load("res://Scenes/SquarePlayerTwo.tscn").instance()
	
	var Area2DforBorders = Area2D.new()
	
	if whoPlays == 0:
		Area2DforBorders.set_name("Area2DforBordersPlayerOne")
		Area2DforBorders.connect("area_entered", self, "_on_borderPlayer1_area_entered")
		Area2DforBorders.connect("area_exited", self, "_on_borderPlayer1_area_exited")
	else:
		Area2DforBorders.set_name("Area2DforBordersPlayerTwo")
		Area2DforBorders.connect("area_entered", self, "_on_borderPlayer2_area_entered")
		Area2DforBorders.connect("area_exited", self, "_on_borderPlayer2_area_exited")
		
	var collisionForBorders = CollisionShape2D.new()
	var shapeForBorders = RectangleShape2D.new()
	collisionForBorders.shape = shapeForBorders
	Area2DforBorders.add_child(collisionForBorders)
	squareScene.add_child(Area2DforBorders)
		
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	collision.shape = shape
	squareScene.get_node("Area2DSquare").add_child(collision)
	
	var square = squareScene.get_node("Area2DSquare").get_node("square")
	
	var size_x = square.rect_size.x*width-((width-1)*4)
	var size_y = square.rect_size.y*height-((height-1)*4)
	var sizeVector = Vector2(size_x,size_y)

	square.rect_size = sizeVector
	collision.shape.extents = (sizeVector/2)-Vector2(4,4)
	collision.position = (sizeVector/2)
	
	collisionForBorders.shape.extents = (sizeVector/2) + Vector2(10,10)
	collisionForBorders.position = (sizeVector/2) 
	squareScene.get_node("Area2DSquare").connect("area_exited", self, "_on_square_area_exited")
	squareScene.get_node("Area2DSquare").connect("area_entered", self, "_on_square_area_entered")
		
	return squareScene

func _on_square_area_entered(another_area):
	var name_of_area = another_area.get_name()

	if name_of_area == "Area2DSquare":
		howManySquaresColliding+=1
		
	
func _on_square_area_exited(another_area):
	var name_of_area = another_area.get_name()
	
	if name_of_area == "Area2DSquare":
		howManySquaresColliding-=1

func _on_background_area_entered(another_area):
	if another_area.get_name() == "Area2DSquare":
		howManySquaresColliding+=1
		print("P", whoPlays+1, "; ", another_area.get_name()+ " enters background")		
	
func _on_background_area_exited(another_area):
	if another_area.get_name() == "Area2DSquare":
		howManySquaresColliding-=1
		print("P", whoPlays+1, "; ", another_area.get_name()+ " leaves background")	
	
func _on_borderPlayer1_area_entered(another_area):
	if another_area.get_name() == "Area2DforBordersPlayerOne":
		bordersCollidingWithPlayer.player1 += 1
		print("P", whoPlays+1, "; ", another_area.get_name()+ " enters borderPlayer1_area")	
	
func _on_borderPlayer1_area_exited(another_area):
	if another_area.get_name() == "Area2DforBordersPlayerOne":
		bordersCollidingWithPlayer.player1 -= 1
		print("P", whoPlays+1, "; ", another_area.get_name()+ " leaves borderPlayer1_area")	

func _on_borderPlayer2_area_entered(another_area):
	if another_area.get_name() == "Area2DforBordersPlayerTwo":
		bordersCollidingWithPlayer.player2 += 1
		print("P", whoPlays+1, "; ", another_area.get_name()+ " enters borderPlayer2_area")	

	
func _on_borderPlayer2_area_exited(another_area):
	if another_area.get_name() == "Area2DforBordersPlayerTwo":
		bordersCollidingWithPlayer.player2 -= 1
		print("P", whoPlays+1, "; ", another_area.get_name()+ " leaves borderPlayer2_area")	
		
func _on_playerOneStartPoints_area_entered(another_area):
	if another_area.get_name() == "Area2DSquare":
		collidingPlayersStartPoint = 1
		print("P", whoPlays+1, "; ", another_area.get_name()+ " enters playerOneStartPoints_area")	

func _on_playerOneStartPoints_area_exited(another_area):
	if another_area.get_name() == "Area2DSquare":
		collidingPlayersStartPoint = 0
		print("P", whoPlays+1, "; ", another_area.get_name()+ " leaves playerOneStartPoints_area")	


func _on_playerTwoStartPoints_area_entered(another_area):
	if another_area.get_name() == "Area2DSquare":
		collidingPlayersStartPoint = 2
		print("P", whoPlays+1, "; ", another_area.get_name()+ " enters playerTwoStartPoints_area")	


func _on_playerTwoStartPoints_area_exited(another_area):
	if another_area.get_name() == "Area2DSquare":
		collidingPlayersStartPoint = 0
		print("P", whoPlays+1, "; ", another_area.get_name()+ " leaves playerTwoStartPoints_area")	

func get_PlayerSquares_node(team):
	if team == 0:
		return get_node("PlayerSquares").get_node("PlayerSquares1")
	else:
		return get_node("PlayerSquares").get_node("PlayerSquares2")

func _on_errorTimer_timeout():
	currentSquareToPlace.modulate = COLOR_CLEAR
	if whoPlays == 0:
		cursorSquare.modulate = COLOR_TEAM_ONE
	else:
		cursorSquare.modulate = COLOR_TEAM_TWO

func _on_beforeEndTimer_timeout():
	var scanning = ScanningForEnd.new()
	var testingSquare = get_square(1, 1)
	testingSquare.set_name("testingSquare")
	add_child(testingSquare)
	
	scanning.start()
	pass # Replace with function body.
