extends Node

const COLOR_TEAM_ONE = Color("6699ff")
const COLOR_TEAM_TWO = Color("ff3399")
const COLOR_ERROR = Color("ff0000")
const COLOR_CLEAR = Color("ffffff")
const FIELD_BORDERS = Vector2(1360,1058)
const FIELD_START_POINT = Vector2(320,18)

const PRINT_COLLIDERS_INFO = false

enum GameStages {MENU, GENERATING, TESTING, TESTED, PLACING, END}

var gameStage = GameStages.MENU

var hideCursorSquare = true #defines do you need to show Square for Cursor or not 
var cursorSquare #square for cursor
var currentSquareToPlace #that square that player control rn and want to place
var whoPlays = 0 #defines the team who plays
var lastMousePosition = Vector2(320,18)
var howManySquaresColliding = 0
var collidingPlayersStartPoint = 0
var bordersCollidingWithPlayer = {"player1": 0, "player2": 0}
var rotationFixVector = Vector2(0,0)
var testingObject = {
	"Square": null,
	"Rotated": 0,
	"SquareSize": Vector2(0,0),
	"MinSize": 0, #when one size is bigger than another
	"BiggerSize": 0
}

var gridSystem = {
	"grid": [],
	"playerOneMask": [],
	"playerTwoMask": []
}

#var isItTheEnd = false

var gameTime=0

func _ready():
	print("GameStage = ", gameStage)
	
	gridSystem.grid = init_array(gridSystem.grid)
	gridSystem.playerOneMask = init_array(gridSystem.playerOneMask)
	gridSystem.playerTwoMask = init_array(gridSystem.playerTwoMask)
	randomize()
	
func init_array(array):
	
	for x in range(20):
		var col = []
		col.resize(20)
		array.append(col)
	
	for x in range(20):
		for y in range(20):
			array[x][y] = 0
	return array
	
func _on_StartGameButton_button_up():
	get_node("StartGameButton").hide()
	get_node("grayBackroundRect").hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)	
	
	cursorSquare = load("res://Scenes/SquareCursor.tscn").instance()
	cursorSquare.modulate = COLOR_TEAM_ONE
	add_child(cursorSquare)
	
	cursorSquare.hide()
	#TODO: сделать это действие по анимации рандома
	generate_new_square()
	
func _input(event):
	if gameStage != GameStages.MENU:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT and not event.pressed:
				_on_left_button_click(event.position)
			if event.button_index == BUTTON_WHEEL_UP and event.pressed:
				rotate_square(currentSquareToPlace, -90)
			if event.button_index == BUTTON_WHEEL_DOWN and event.pressed:
				rotate_square(currentSquareToPlace, 90)
		elif event is InputEventMouseMotion:
			lastMousePosition = event.position
			move_cursor(event.position)	

func _on_left_button_click(mouse_position):
	if not placingRules():
		showErrorOnPlacing()
		return
	else:
		 place_squareToPlace()
		
func _process(delta):
	gameTime+=delta
	
	#if gameStage == GameStages.TESTING:
		#testingForEnd()
	
	return false
		
func placingRules():
	var answer: bool
	answer = true
	var area1 = get_PlayerSquares_node(0)#TODO: сделать единичную инициализацию
	var area2 = get_PlayerSquares_node(1)
	
	var area1ChildCount = area1.get_child_count()
	var area2ChildCount = area2.get_child_count()
	
	if howManySquaresColliding != 0:
		answer = false
	
	if whoPlays == 0:	
		if area1ChildCount == 0:
			if collidingPlayersStartPoint != 1:
				answer = false
		else:
			if bordersCollidingWithPlayer.player1 == 0:
				answer = false
	
	if whoPlays == 1:
		if area2ChildCount == 0:
			if collidingPlayersStartPoint != 2:
				answer = false
		else:
			if bordersCollidingWithPlayer.player2 == 0:
				answer = false
	
	return answer
	
func showErrorOnPlacing():
	$errorTimer.start()
	cursorSquare.modulate = COLOR_ERROR
	currentSquareToPlace.modulate = COLOR_ERROR

func move_cursor(position):
	if hideCursorSquare == false:
		cursorSquare.visible = true
		cursorSquare.rect_position = position
		
		var x_pos = stepify(position.x-FIELD_START_POINT.x, 52)+FIELD_START_POINT.x
		var y_pos = stepify(position.y+18, 52)+18
	
		var currentSquarePos = Vector2(x_pos, y_pos)
		
		currentSquareToPlace.rect_position = currentSquarePos + rotationFixVector
	else:
		cursorSquare.hide()
		
func start_dice_animation_orSmth():
	print("GameStage = ", "dice animation")
	hideCursorSquare = true
	
	pass #animation things
	
	hideCursorSquare = false
	
func generate_new_square():
	var w = randi()%6 + 1
	var h = randi()%6 + 1
	gameStage = GameStages.GENERATING
	print("GameStage = ", gameStage)
	print("Generated new square: ", w, ":", h)
	
	currentSquareToPlace = get_square(w, h)
	
	hideCursorSquare = true
	
	testingForEndInit(w,h)
	#$beforeEndTimer.start()
	
func place_squareToPlace():
	#starts with clicking LMB
	gameStage = GameStages.PLACING
	print("GameStage = ", gameStage)
	
	currentSquareToPlace.modulate = COLOR_CLEAR
	
	var square = currentSquareToPlace.get_node("Area2DSquare/square")
	
	var size_x = square.rect_size.x
	var size_y = square.rect_size.y
	
	var pos_x: int
	var pos_y: int
	pos_x = (currentSquareToPlace.rect_position.x-FIELD_START_POINT.x)/52
	pos_y = (currentSquareToPlace.rect_position.y-FIELD_START_POINT.y)/52
	
	var width: int
	var height: int
	
	width = (size_x - 4)/(56 - 4)
	height = (size_y - 4)/(56 - 4)

	if currentSquareToPlace.rect_rotation as int != 0:	
		if rotationFixVector.x !=0 and rotationFixVector.y !=0:
			pos_x -= width
			pos_y -= height
		elif rotationFixVector.x !=0:
			pos_x -= height
		elif rotationFixVector.y !=0:
			pos_y -= width
		
		match currentSquareToPlace.rect_rotation as int:
			90,-90, 270, -270:
				var temp = width
				width = height
				height = temp
			_:
				pass

	for x in range(pos_y, pos_y+height):
		for y in range(pos_x, pos_x+width):
			gridSystem.grid[x][y] = whoPlays+1
	
	get_node("PlayerSquares").remove_child(currentSquareToPlace)
	get_PlayerSquares_node(whoPlays).add_child(currentSquareToPlace)
	
	change_team()
	bordersCollidingWithPlayer.player1 = 0
	bordersCollidingWithPlayer.player2 = 0
	rotationFixVector = Vector2(0,0)
	generate_new_square()
	

func rotate_square(square, angle):
	square.rect_position -= rotationFixVector
	rotationFixVector = Vector2(0,0)
	square.rect_rotation +=angle
	if square.rect_rotation >=360 or square.rect_rotation <=-360:
		square.rect_rotation = 0

	var rotation: int 
	rotation = square.rect_rotation
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

	square.rect_position += rotationFixVector
		
func change_team():
	if whoPlays == 0:
		cursorSquare.modulate = COLOR_TEAM_TWO
		whoPlays = 1
	else:
		cursorSquare.modulate = COLOR_TEAM_ONE
		whoPlays = 0
	print("Team changed. Now playing: Player "+(whoPlays+1)as String)

func get_square(width, height):
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
	
	collisionForBorders.shape.extents = (sizeVector/2) #+ Vector2(4,4)
	collisionForBorders.position = (sizeVector/2) 
	squareScene.get_node("Area2DSquare").connect("area_exited", self, "_on_square_area_exited")
	squareScene.get_node("Area2DSquare").connect("area_entered", self, "_on_square_area_entered")

	return squareScene

func _on_square_area_entered(another_area):
	var name_of_area = another_area.get_name()

	if name_of_area == "Area2DSquare":
		howManySquaresColliding+=1
		if PRINT_COLLIDERS_INFO:
			print(gameTime as String+" P", whoPlays+1, "; ", another_area.get_name()+ " enters square area sized "
		 + another_area.get_node("square").rect_size.x as String + ";" + another_area.get_node("square").rect_size.y as String)
	
func _on_square_area_exited(another_area):
	var name_of_area = another_area.get_name()
	
	if name_of_area == "Area2DSquare":
		howManySquaresColliding-=1
		if PRINT_COLLIDERS_INFO:
			print(gameTime as String+" P", whoPlays+1, "; ", another_area.get_name()+ " leaves square area")

func _on_background_area_entered(another_area):
	if another_area.get_name() == "Area2DSquare":
		howManySquaresColliding+=1
		if PRINT_COLLIDERS_INFO:
			print(gameTime as String+" P", whoPlays+1, "; ", another_area.get_name()+ " enters background")	
	
func _on_background_area_exited(another_area):
	if another_area.get_name() == "Area2DSquare":
		howManySquaresColliding-=1
		if PRINT_COLLIDERS_INFO:
			print(gameTime as String+" P", whoPlays+1, "; ", another_area.get_name()+ " leaves background")	
	
func _on_borderPlayer1_area_entered(another_area):
	var a = another_area.get_name()
	if another_area.get_name() == "Area2DforBordersPlayerOne":
		bordersCollidingWithPlayer.player1 += 1
		if PRINT_COLLIDERS_INFO:
			print(gameTime as String+" P", whoPlays+1, "; ", another_area.get_name()+ " enters borderPlayer1_area")	
		#print(bordersCollidingWithPlayer)
	
func _on_borderPlayer1_area_exited(another_area):
	if another_area.get_name() == "Area2DforBordersPlayerOne":
		bordersCollidingWithPlayer.player1 -= 1
		if PRINT_COLLIDERS_INFO:
			print(gameTime as String+" P", whoPlays+1, "; ", another_area.get_name()+ " leaves borderPlayer1_area")	
		#print(bordersCollidingWithPlayer)

func _on_borderPlayer2_area_entered(another_area):
	if another_area.get_name() == "Area2DforBordersPlayerTwo":
		bordersCollidingWithPlayer.player2 += 1
		if PRINT_COLLIDERS_INFO:
			print(gameTime as String+" P", whoPlays+1, "; ", another_area.get_name()+ " enters borderPlayer2_area")	
		#print(bordersCollidingWithPlayer)

func _on_borderPlayer2_area_exited(another_area):
	if another_area.get_name() == "Area2DforBordersPlayerTwo":
		bordersCollidingWithPlayer.player2 -= 1
		if PRINT_COLLIDERS_INFO:
			print(gameTime as String+" P", whoPlays+1, "; ", another_area.get_name()+ " leaves borderPlayer2_area")	
		#print(bordersCollidingWithPlayer)
		
func _on_playerOneStartPoints_area_entered(another_area):
	if another_area.get_name() == "Area2DSquare":
		collidingPlayersStartPoint = 1
		if PRINT_COLLIDERS_INFO:
			print(gameTime as String+" P", whoPlays+1, "; ", another_area.get_name()+ " enters playerOneStartPoints_area")	

func _on_playerOneStartPoints_area_exited(another_area):
	if another_area.get_name() == "Area2DSquare":
		collidingPlayersStartPoint = 0
		if PRINT_COLLIDERS_INFO:
			print(gameTime as String+" P", whoPlays+1, "; ", another_area.get_name()+ " leaves playerOneStartPoints_area")	

func _on_playerTwoStartPoints_area_entered(another_area):
	if another_area.get_name() == "Area2DSquare":
		collidingPlayersStartPoint = 2
		if PRINT_COLLIDERS_INFO:
			print(gameTime as String+" P", whoPlays+1, "; ", another_area.get_name()+ " enters playerTwoStartPoints_area")	

func _on_playerTwoStartPoints_area_exited(another_area):
	if another_area.get_name() == "Area2DSquare":
		collidingPlayersStartPoint = 0
		if PRINT_COLLIDERS_INFO:
			print(gameTime as String+" P", whoPlays+1, "; ", another_area.get_name()+ " leaves playerTwoStartPoints_area")	

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

func testingForEndInit(width, height):
	
	gameStage = GameStages.TESTING
	print("GameStage = ", gameStage)

	var area1ChildCount = get_PlayerSquares_node(0).get_child_count()
	var area2ChildCount = get_PlayerSquares_node(1).get_child_count()
#
	for x in range(20):
		print(gridSystem.grid[x])
		
	if area1ChildCount == 0 or area2ChildCount == 0 or testingForEnd(width, height) == false:
		gameStage = GameStages.TESTED
#		if testingObject.Square != null:
#			testingObject.Square.free()
		get_node("PlayerSquares").add_child(currentSquareToPlace)
		currentSquareToPlace.rect_position = lastMousePosition
		rotationFixVector = Vector2(0,0)
		start_dice_animation_orSmth()
	pass
func testingForEnd(width, height):
	var answer = true
	var grid = gridSystem.grid
	
	var minSize = width
	var maxSize = width
	
	if width > height:
		maxSize = width
		minSize = height
	elif width < height:
		maxSize = height
		minSize = width
		
	for y in range(0, 20-minSize):
		for x in range(0,20-maxSize):
			if (x==0 and y==0) or (x == 19 and y==19):
				continue
			if grid[y][x] != 0:
				continue
			
			for rotated in range(1):		
				var isBreak = false
				
				var temp_width = width
				var temp_height = height
				
				if rotated == 1:
					temp_width = height
					temp_height = width
				
				if (x+temp_width > 19 and y+temp_height > 19):
					continue
				for j in range(temp_height):
					for i in range(temp_width):
						if (grid[y+j][x+i] !=0):
							isBreak = true
							break
						pass
					if isBreak == true:
						break
					pass
				
				if isBreak == true:
					answer = true
					continue
				else:
					var incI = 0
					var incJ = 0
					if (x == 0):
						incI+=1
					if (y == 0):
						incJ+=1
					if (x + temp_width > 19):
						temp_width-=1
					if (y + temp_height > 19):
						temp_height-=1
					
					for j in range(y-1+incJ, y+temp_height+1):
						for i in range(x-1+incI, x+temp_width+1):
							if (grid[j][i] == whoPlays+1):
								answer = false
								return answer
				pass
			pass
		pass
	print("IT IS THE END!!!")
