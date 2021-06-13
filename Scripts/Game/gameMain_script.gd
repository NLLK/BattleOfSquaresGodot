extends Node

const COLOR_TEAM_ONE = Color("6699ff")
const COLOR_TEAM_TWO = Color("ff3399")
const COLOR_ERROR = Color("ff0000")
const COLOR_CLEAR = Color("ffffff")
const FIELD_BORDERS = Vector2(1360,1058)
const FIELD_START_POINT = Vector2(320,18)

const BEFORE_END_SECONDS = 3

const PRINT_COLLIDERS_INFO = false

enum GameStages {MENU, START, GENERATING, TESTING, TESTED, DICE_ANIMATION, PLACING, END, PAUSE, END_MENU}

var gameStage = GameStages.MENU

var hideCursorSquare = true #TODO: rudiment. Need to remove
var cursorSquare #square for cursor
var currentSquareToPlace #that square that player control rn and want to place
var whoPlays = 0 #defines the team who plays
var lastMousePosition = Vector2(320,18)

var howManySquaresColliding = 0
var collidingPlayersStartPoint = 0
var bordersCollidingWithPlayer = {"player1": 0, "player2": 0}
var isOutsideOfField
var rotationFixVector = Vector2(0,0)
var gridSystem = {
	"grid": []
}
var debuggingGrid = []

var squareObjectList = []
enum squareSides {UPPER,RIGHT,LOWER,LEFT}
#var isItTheEnd = false
var beforeEndSecondsSpent = 0
var pausePreviousGameStage
var gameTime=0

func _ready():
	print("GameStage = ", gameStage)
	
	gridSystem.grid = init_array(gridSystem.grid, 0)
	init_array(debuggingGrid, 0)
	randomize()
	
func init_array(array, just_zero):
	if (just_zero == 0):
		for _x in range(20):
			var col = []
			col.resize(20)
			array.append(col)
	
	for x in range(20):
		for y in range(20):
			array[x][y] = 0
	return array
	
func _on_StartGameButton_button_up():
	gameStage = GameStages.START
	print("GameStage = ", gameStage)
	
	$startMenu.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)	
	
	cursorSquare = $SquareCursor
	cursorSquare.modulate = get_players_color(whoPlays)
	#add_child(cursorSquare)
	hideCursorSquare = false
	cursorSquare.hide()
	#TODO: сделать это действие по анимации рандома
	generate_new_square()

func _on_endPlayAgain_button_up():
	$endMenu.hide()
	$endMenu.modulate = Color("00ffffff")
	gameStage = GameStages.START
	print("GameStage = ", gameStage)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)	
	
	cursorSquare.modulate = get_players_color(whoPlays)
	
	cursorSquare.hide()
	for child in get_PlayerSquares_node(0).get_children():
		child.free()
		pass
	for child in get_PlayerSquares_node(1).get_children():
		child.free()
		pass

	currentSquareToPlace.free()
	
	init_array(gridSystem.grid, 1)
	howManySquaresColliding = 0
	collidingPlayersStartPoint = 0
	bordersCollidingWithPlayer.player1 = 0
	bordersCollidingWithPlayer.player2 = 0
	
	squareObjectList.clear()
	
	beforeEndSecondsSpent = 0
	#$beforeEndLabel.hide()
	
	#TODO: сделать это действие по анимации рандома
	generate_new_square()
	
	pass
	
func _input(event):
	if gameStage != GameStages.MENU and gameStage != GameStages.END_MENU and gameStage != GameStages.PAUSE:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT and not event.pressed:
				_on_left_button_click()
			if event.button_index == BUTTON_WHEEL_UP and event.pressed:
				rotate_square(currentSquareToPlace, -90)
			if event.button_index == BUTTON_WHEEL_DOWN and event.pressed:
				rotate_square(currentSquareToPlace, 90)
		elif event is InputEventMouseMotion:
			lastMousePosition = event.position
			move_cursor(event.position)	
		elif event is InputEventKey:
			if event.scancode == KEY_D:
				debugfunc()
			pass
	if event is InputEventKey:
		if event.scancode == KEY_ESCAPE and event.pressed:
			_on_pauseButton_button_up()
func debugfunc():
	$beforeEndTimer.start()
	#showEndMenu()
	pass
func _on_left_button_click():
	if !isOutsideOfField:
		if not placingRules():
			showErrorOnPlacing()
			return
		else:
			 place_squareToPlace()

func beforeEndInit():
	#$beforeEndLabel.show()
	#$beforeEndLabel.text = BEFORE_END_SECONDS as String

	$beforeEndTimer.start()
		
func showEndMenu():

	hideCursorSquare = true
	cursorSquare.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)	
	change_team()
	$endMenu/whoWonLabel.set("custom_colors/font_color", get_players_color(whoPlays))
	$endMenu/whoWonLabel.set("custom_colors/font_outline_modulate", get_players_color(whoPlays))
	$endMenu/whoWonLabel.text = "Player " + (whoPlays+1)as String + " won!" 
	change_team()
	$endMenu/Tween.interpolate_property($endMenu, "modulate", 
	Color("00ffffff"), Color("ffffffff"), 3, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$endMenu/Tween.start()
	$endMenu.show()

	pass
		
func placingRules():
	var answer: bool
	answer = true
	var area1 = get_PlayerSquares_node(0)
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
	position-=Vector2(52, 52)
	isOutsideOfField = false

	var square = currentSquareToPlace.get_node("Area2DSquare/square")
	
	var width = (square.rect_size.x - 4)/(56 - 4)
	var height = (square.rect_size.y - 4)/(56 - 4)
	
	if currentSquareToPlace.rect_rotation as int == 90:
		var temp = width
		width = height
		height = temp
		pass
	
	var pos_x = stepify(position.x-FIELD_START_POINT.x, 52)/52
	var pos_y = stepify(position.y-FIELD_START_POINT.y, 52)/52
	
	if (pos_x < 0 or pos_y < 0 or pos_x > 20-width or pos_y > 19-height):
		isOutsideOfField = true
	
	if isOutsideOfField:
		hideCursorSquare = true
		cursorSquare.hide()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)	
		pass
	else:
		hideCursorSquare = false
	
	if gameStage != GameStages.PAUSE and not isOutsideOfField:	
		if hideCursorSquare == false:
			cursorSquare.show()
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			cursorSquare.rect_position = position + Vector2(52/2, 52/2)
			
			var x_pos = stepify(position.x-FIELD_START_POINT.x, 52)+FIELD_START_POINT.x
			var y_pos = stepify(position.y+FIELD_START_POINT.y, 52)+FIELD_START_POINT.y
			var currentSquarePos = Vector2(x_pos, y_pos)
			
			currentSquareToPlace.rect_position = currentSquarePos + rotationFixVector
		else:
			cursorSquare.hide()
		if gameStage == GameStages.END:
			#$beforeEndLabel.rect_position = position + Vector2(52/2+8, 52/2)
			pass
		
func start_dice_animation_orSmth():
	if gameStage != GameStages.END:
		gameStage = GameStages.DICE_ANIMATION
		print("GameStage = ", gameStage)
		hideCursorSquare = true
		
		pass #animation things
		
		hideCursorSquare = false
	else:
		beforeEndInit()
		pass #animation things
		pass
	
func generate_new_square():
	var w = randi()%6 + 1
	var h = randi()%6 + 1
	gameStage = GameStages.GENERATING
	print("GameStage = ", gameStage)
	print("Generated new square: ", w, ":", h)
	
	currentSquareToPlace = get_square(w, h)
		
	testingForEndInit(w,h)
	
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
				
	for y in range(pos_y, pos_y+height):
		for x in range(pos_x, pos_x+width):
			gridSystem.grid[y][x] = whoPlays+1
	
	var squareObj = squareObject.new(Vector2(pos_x,pos_y), Vector2(pos_x+width-1,pos_y+height-1),whoPlays)
	squareObjectList.append(squareObj)
	
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
	if square.rect_rotation == 180:
		square.rect_rotation = 0
	if square.rect_rotation == -90:
		square.rect_rotation = 90 
		
	var size_y = square.get_node("Area2DSquare/square").rect_size.y
	var height = (size_y - 4)/(56 - 4)
	
	var positionModification = Vector2(0,0)
	if currentSquareToPlace.rect_rotation as int == 90:
		positionModification = Vector2(height, 0)
		pass

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
			
	rotationFixVector += positionModification*52
	square.rect_position += rotationFixVector

func change_team():
	if whoPlays == 0:
		cursorSquare.modulate = COLOR_TEAM_TWO
		whoPlays = 1
	elif whoPlays == 1:
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

func get_PlayerSquares_node(team):
	if team == 0:
		return get_node("PlayerSquares").get_node("PlayerSquares1")
	elif team == 1:
		return get_node("PlayerSquares").get_node("PlayerSquares2")

func get_players_color(team):
	if team == 0:
		return COLOR_TEAM_ONE
	elif team == 1:
		return COLOR_TEAM_TWO

func testingForEndInit(width, height):
	
	gameStage = GameStages.TESTING
	print("GameStage = ", gameStage)

	var area1ChildCount = get_PlayerSquares_node(0).get_child_count()
	var area2ChildCount = get_PlayerSquares_node(1).get_child_count()

	if area1ChildCount == 0 or area2ChildCount == 0:
		gameStage = GameStages.TESTED
		print("GameStage = ", gameStage)
		get_node("PlayerSquares").add_child(currentSquareToPlace)
		currentSquareToPlace.rect_position = lastMousePosition
		rotationFixVector = Vector2(0,0)
		start_dice_animation_orSmth()
	elif testingForEnd(width, height) == false:
		gameStage = GameStages.TESTED
		get_node("PlayerSquares").add_child(currentSquareToPlace)
		currentSquareToPlace.rect_position = lastMousePosition
		rotationFixVector = Vector2(0,0)
		start_dice_animation_orSmth()
	else:
		gameStage = GameStages.END
		print("GameStage = ", gameStage)
		
		get_node("PlayerSquares").add_child(currentSquareToPlace)
		currentSquareToPlace.rect_position = lastMousePosition
		rotationFixVector = Vector2(0,0)
				
		start_dice_animation_orSmth()

func testingForEnd(width, height):
	
	init_array(debuggingGrid, 1)
	var grid = gridSystem.grid
	var fittable #is square fits somewhere
	
	for square in squareObjectList:
		
		if square.player != whoPlays:
			continue
		var bordersP1 = Vector2(-1,-1)
		var bordersP2 = Vector2(1,1)
		
		#for upper left corner and borders at all
		if square.p1.x == 0:
			bordersP1.x = 0
		if square.p1.y == 0:
			bordersP1.y = 0
		#for lower right corner and borders at all
		if square.p2.x == 19:
			bordersP2.x = 0
		if square.p2.y == 19:
			bordersP2.y = 0
		
		#for upper side of square
		if square.p1.y != 0:
			for x in range(square.p1.x, square.p2.x+bordersP2.x ):#+ 1
				#last +1 is to simply use range()
				var y = square.p1.y - 1
				if grid[y][x] == 0:
					fittable = testingForEndCheckPlace(x, y, width,height,squareSides.UPPER)
					if fittable:
						print("Can place ",width,":",height, " square at ",y, ";", x, ". Side= ",squareSides.UPPER )
						return false
						pass
					else:
						continue
						pass
					pass
					
				pass
		#for right side of square
		if square.p2.x !=19:
			for y in range(square.p1.y, square.p2.y + bordersP2.y):#+ 1
				var x = square.p2.x + 1
				if grid[y][x] == 0:
					fittable = testingForEndCheckPlace(x, y, width,height,squareSides.RIGHT)
					if fittable:
						print("Can place ",width,":",height, " square at ",y, ";", x, ". Side= ",squareSides.RIGHT )
						return false
						pass
					else:
						continue
						pass
					pass
				pass
		#for lower side of square
		if square.p2.y !=19:
			for x in range(square.p1.x, square.p2.x + bordersP2.x ):#+ 1
				var y = square.p2.y + 1
				if grid[y][x] == 0:
					fittable = testingForEndCheckPlace(x,y,height,width,squareSides.LOWER)
					if fittable:
						print("Can place ",width,":",height, " square at ",y, ";", x, ". Side= ",squareSides.LOWER )
						return false
						pass
					else:
						continue
						pass
					pass
				pass
		#for left side of square
		if square.p1.x !=0:
			for y in range(square.p1.y + bordersP1.y, square.p2.y + bordersP2.y):
				var x = square.p1.x - 1
				if grid[y][x] == 0:
					fittable = testingForEndCheckPlace(x, y,height,width,squareSides.LEFT)
					if fittable:
						print("Can place ",width,":",height, " square at ",y, ";", x, ". Side= ",squareSides.LEFT )
						return false
						pass
					else:
						continue
						pass
					pass
				pass
		pass
		
	return true
	
func testingForEndCheckPlace(x,y,width,height,side):
	var grid = gridSystem.grid
	
	var isBreak
	var temp_width
	var temp_height
	
	for rotate in [0,1]:
		if width == height and rotate==0:
			continue
		temp_width = width
		temp_height = height
		isBreak = false
				
		if rotate==1:
			temp_width = height
			temp_height = width
		match side:
			squareSides.UPPER:
				if x+temp_width >20 or y-temp_height +1 <0:
					isBreak = true
					continue
				for j in range(y-temp_height+1, y+1):
					for i in range(x, x+temp_width):
						debuggingGrid[j][i] = whoPlays+1
						if grid[j][i] != 0:
							isBreak = true
							break
						pass
					if isBreak:
						break
					pass
				pass
			squareSides.RIGHT:
				if x+temp_width >20 or y+temp_height >20:
					isBreak = true
					continue
				for j in range(y, y+temp_height):
					for i in range(x, x+temp_width):
						debuggingGrid[j][i] = whoPlays+1
						if grid[j][i] != 0:
							isBreak = true
							break
						pass
					if isBreak:
						break
					pass
				pass
			squareSides.LOWER:
				if x-temp_width +1 < 0 or y+temp_height >20:
					isBreak = true
					continue
				for j in range(y, y+temp_height):
					for i in range(x-temp_width +1, x+1):
						debuggingGrid[j][i] = whoPlays+1
						if grid[j][i] != 0:
							isBreak = true
							break
						pass
					if isBreak:
						break
					pass
				pass
			squareSides.LEFT:
				if x-temp_width+1 <0 or y-temp_height+1 <0:
					isBreak = true
					continue
				for j in range(y-temp_height+1, y+1):
					for i in range(x-temp_width+1, x+1):
						debuggingGrid[j][i] = whoPlays+1
						if grid[j][i] != 0:
							isBreak = true
							break
						pass
					if isBreak:
						break
					pass
				pass
		if isBreak:
			continue
		else:
#			var string = ""
#			for xy in range(20):
#				string += debuggingGrid[xy] as String + "\n"
#			$debuggingText.text = string
			return true
		pass
	var string = ""
	for xy in range(20):
		string += debuggingGrid[xy] as String + "\n"
	$"debuggingThings/debuggingText".text = string
	return false

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
	if another_area.get_name() == "Area2DforBordersPlayerOne":
		bordersCollidingWithPlayer.player1 += 1
		if PRINT_COLLIDERS_INFO:
			print(gameTime as String+" P", whoPlays+1, "; ", another_area.get_name()+ " enters borderPlayer1_area")	
	
func _on_borderPlayer1_area_exited(another_area):
	if another_area.get_name() == "Area2DforBordersPlayerOne":
		bordersCollidingWithPlayer.player1 -= 1
		if PRINT_COLLIDERS_INFO:
			print(gameTime as String+" P", whoPlays+1, "; ", another_area.get_name()+ " leaves borderPlayer1_area")	

func _on_borderPlayer2_area_entered(another_area):
	if another_area.get_name() == "Area2DforBordersPlayerTwo":
		bordersCollidingWithPlayer.player2 += 1
		if PRINT_COLLIDERS_INFO:
			print(gameTime as String+" P", whoPlays+1, "; ", another_area.get_name()+ " enters borderPlayer2_area")	

func _on_borderPlayer2_area_exited(another_area):
	if another_area.get_name() == "Area2DforBordersPlayerTwo":
		bordersCollidingWithPlayer.player2 -= 1
		if PRINT_COLLIDERS_INFO:
			print(gameTime as String+" P", whoPlays+1, "; ", another_area.get_name()+ " leaves borderPlayer2_area")	
		
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

func _on_errorTimer_timeout():
	currentSquareToPlace.modulate = COLOR_CLEAR
	if whoPlays == 0:
		cursorSquare.modulate = COLOR_TEAM_ONE
	else:
		cursorSquare.modulate = COLOR_TEAM_TWO

func _on_beforeEndTimer_timeout():
	if gameStage == GameStages.PAUSE:
		$beforeEndTimer.start()
		pass
	elif beforeEndSecondsSpent != BEFORE_END_SECONDS-1:
		beforeEndSecondsSpent+=1
		#$beforeEndLabel.text = (BEFORE_END_SECONDS - beforeEndSecondsSpent) as String
		$beforeEndTimer.start()
	else:
		#$beforeEndLabel.hide()
		gameStage = GameStages.END_MENU
		print("GameStage = ", gameStage)
		showEndMenu()
		pass
	pass # Replace with function body.

func _on_pauseButton_button_up():
	if gameStage != GameStages.MENU and gameStage != GameStages.END_MENU:
		if $pauseMenu.visible == false:
			pausePreviousGameStage = gameStage
			gameStage = GameStages.PAUSE
			print("GameStage = ", gameStage)
			hideCursorSquare = true
			cursorSquare.hide()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			$pauseMenu.visible = true
		else:
			_on_pauseMenuContinue_button_up()

func _on_pauseMenuContinue_button_up():
	gameStage = pausePreviousGameStage
	print("GameStage = ", gameStage)
	$pauseMenu.hide()
	hideCursorSquare = false
	cursorSquare.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	pass # Replace with function body.

func _on_pauseMenuSurrender_button_up():
	$pauseMenu.hide()
	#$beforeEndLabel.hide()
	gameStage = GameStages.END_MENU
	print("GameStage = ", gameStage)
	showEndMenu()
	pass # Replace with function body.
