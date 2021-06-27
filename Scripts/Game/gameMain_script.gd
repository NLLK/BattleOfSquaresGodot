extends Node

export(Color) var COLOR_TEAM_ONE = Color("6699ff")
export(Color) var COLOR_TEAM_TWO = Color("ff3399")
export(Color) var COLOR_ERROR = Color("ff0000")
const COLOR_CLEAR = Color("ffffff")
var FIELD_BORDERS = Vector2(1040,1040) # = Vector2(1360,1058)
var FIELD_START_POINT = Vector2(0,0)# = Vector2(320,18)
export(Vector2) var FIELD_POSITION = Vector2(320,18)

export(int) var BEFORE_END_SECONDS = 3
export(bool) var PRINT_COLLIDERS_INFO = false
export(bool) var isMobile
export(bool) var showCursorAnyWay

enum GameStages {MENU, START, GENERATING, TESTING, TESTED, DICE_ANIMATION, PLACING, END, PAUSE, END_MENU}

var gameStage = GameStages.MENU

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

var mobileCursorPosition#mb create separate object for it

##### NODE_paths #####

onready var NODE_SquareCursor = $CommonUI/SquareCursor
onready var NODE_Menu_start = $CommonUI/Menus/startMenu
onready var NODE_Menu_pause = $CommonUI/Menus/pauseMenu
onready var NODE_Menu_end = $CommonUI/Menus/endMenu
onready var NODE_Menu_end_whoWonLabel = NODE_Menu_end.get_node("whoWonLabel")
onready var NODE_Menu_end_Tween = NODE_Menu_end.get_node("endMenuTween")
onready var NODE_beforeEndTimer = $CommonUI/beforeEndTimer
onready var NODE_errorTimer = $CommonUI/errorTimer
onready var NODE_PlayerSquares = $CommonUI/backgroundMain/PlayerSquares
onready var NODE_PlayerSquares_1 = NODE_PlayerSquares.get_node("PlayerSquares1")
onready var NODE_PlayerSquares_2 = NODE_PlayerSquares.get_node("PlayerSquares2")
onready var NODE_debuggingText = $CommonUI/debuggingThings/debuggingText

onready var NODE_MobileMenu_Main = $MobileUI/Main
onready var NODE_MobileMenu_Joystick = $MobileUI/Main/Joystick
onready var NODE_MobileMenu_joystickDelayTimer = $MobileUI/joystickDelayTimer
onready var NODE_MobileMenu_placeButton = $MobileUI/Main/PlaceButtonBody/PlaceButton
onready var NODE_MobileMenu_rotateButton = $MobileUI/Main/RotateButton


##### /NODE_paths #####

func _ready():
	
	FIELD_BORDERS+=FIELD_POSITION
	FIELD_START_POINT+=FIELD_POSITION
	
	mobileCursorPosition = FIELD_START_POINT
	
	if (OS.get_name() == "Android"):
		isMobile = true
		
	if isMobile:
		NODE_SquareCursor.hide()
		print("Is mobiiiile is it now or never")

	NODE_MobileMenu_Main.hide()
	
	print("GameStage = ", gameStage)
	NODE_MobileMenu_Joystick.modulate = COLOR_TEAM_ONE
	NODE_Menu_end.modulate = Color("00ffffff")
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
	
	NODE_Menu_start.hide()
	if isMobile:
		NODE_MobileMenu_Main.show()
		NODE_MobileMenu_Joystick.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)	
	
	if showCursorAnyWay:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	cursorSquare = cursorSquareObject.new(NODE_SquareCursor,isMobile)
	cursorSquare.modulate(get_players_color(whoPlays))
	cursorSquare.hide()
	#TODO: сделать это действие по анимации рандома
	generate_new_square()

func _on_endPlayAgain_button_up():
	NODE_Menu_end.hide()
	NODE_Menu_end.modulate = Color("00ffffff")
	gameStage = GameStages.START
	print("GameStage = ", gameStage)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)	
	
	cursorSquare.modulate(get_players_color(whoPlays))
	
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
	
	#TODO: сделать это действие по анимации рандома
	generate_new_square()
	
	if isMobile:
		NODE_MobileMenu_Main.show()
		if whoPlays == 0:
			mobileCursorPosition = FIELD_START_POINT
		elif whoPlays == 1:
			
			var square = currentSquareToPlace.get_node("Area2DSquare/square")
	
			var width = (square.rect_size.x - 4)/(56 - 4)
			var height = (square.rect_size.y - 4)/(56 - 4)
			
			var pos_x = (20-width)*52#+FIELD_START_POINT.x
			var pos_y = (20-height)*52#+FIELD_START_POINT.y
						
			mobileCursorPosition = Vector2(pos_x, pos_y)
			
			mobile_move_cursor(Vector2(0,0))
	
	pass
	
func _input(event):
	if !isMobile:
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
					pass
					#debugfunc()
				#pass
		if event is InputEventKey:
			if event.scancode == KEY_ESCAPE and event.pressed:
				_on_pauseButton_button_up()
			if event.scancode == KEY_D:
				debugfunc()
	else:
		pass
		
func _physics_process(_delta):
	if gameStage == GameStages.PLACING or gameStage == GameStages.END:
		if isMobile:
			var joystick = NODE_MobileMenu_Joystick
			if joystick.output != Vector2(0,0):
				if NODE_MobileMenu_joystickDelayTimer.is_stopped():
					NODE_MobileMenu_joystickDelayTimer.start()
					mobile_move_cursor(joystick.output)
				
func debugfunc():
	
	var square = currentSquareToPlace.get_node("Area2DSquare/square")
		
	var width = (square.rect_size.x - 4)/(56 - 4)
	var height = (square.rect_size.y - 4)/(56 - 4)
	
	testingForEnd(width, height)
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

	NODE_beforeEndTimer.start()
		
func showEndMenu():

	cursorSquare.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)	
	change_team()
	NODE_Menu_end_whoWonLabel.set("custom_colors/font_color", get_players_color(whoPlays))
	NODE_Menu_end_whoWonLabel.set("custom_colors/font_outline_modulate", get_players_color(whoPlays))
	NODE_Menu_end_whoWonLabel.text = "Player " + (whoPlays+1)as String + " won!" 
	change_team()
	NODE_Menu_end_Tween.interpolate_property(NODE_Menu_end, "modulate", 
	Color("00ffffff"), Color("ffffffff"), 3, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	NODE_Menu_end_Tween.start()
	NODE_Menu_end.show()
	
	if isMobile:
		NODE_MobileMenu_Main.hide()
		pass
	
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
	NODE_errorTimer.start()
	cursorSquare.modulate(COLOR_ERROR)
	currentSquareToPlace.modulate = COLOR_ERROR
	NODE_MobileMenu_placeButton.modulate = COLOR_ERROR

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
		
	if (pos_x < 0 or pos_y < 0 or pos_x > 19 or pos_y > 19):
		isOutsideOfField = true
		cursorSquare.hide()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)	
		pass
	else:
		isOutsideOfField = false
		cursorSquare.rect_position(position + Vector2(52/2, 52/2))
		cursorSquare.show()
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	
	if not (pos_x < 0 or pos_y < 0 or pos_x > 20-width or pos_y > 20-height):		
		if gameStage != GameStages.PAUSE and not isOutsideOfField:	
			var x_pos = stepify(position.x-FIELD_START_POINT.x, 52)#+FIELD_START_POINT.x
			var y_pos = stepify(position.y-FIELD_START_POINT.y, 52)#+FIELD_START_POINT.y
			var currentSquarePos = Vector2(x_pos, y_pos)
				
			currentSquareToPlace.rect_position = currentSquarePos + rotationFixVector
	
func start_dice_animation_orSmth():
	if gameStage != GameStages.END:
		gameStage = GameStages.DICE_ANIMATION
		print("GameStage = ", gameStage)
		cursorSquare.hide()
		
		pass #animation things
		gameStage = GameStages.PLACING
		print("GameStage = ", gameStage)
		cursorSquare.show()
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
		
	var width = (square.rect_size.x - 4)/(56 - 4)
	var height = (square.rect_size.y - 4)/(56 - 4)
	
	var pos_x = (currentSquareToPlace.rect_position.x-rotationFixVector.x)/52
	var pos_y = (currentSquareToPlace.rect_position.y-rotationFixVector.y)/52
	
	if currentSquareToPlace.rect_rotation as int == 90:
		var temp = width
		width = height
		height = temp
		
	for y in range(pos_y, pos_y+height):
		for x in range(pos_x, pos_x+width):
			gridSystem.grid[y][x] = whoPlays+1
	
#	for xy in gridSystem.grid:
#		print(xy)
	
	var squareObj = squareObject.new(Vector2(pos_x,pos_y), Vector2(pos_x+width-1,pos_y+height-1),whoPlays)
	squareObjectList.append(squareObj)
	
	NODE_PlayerSquares.remove_child(currentSquareToPlace)
	
	currentSquareToPlace.get_node("shadowSquare").hide()
	
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
	if square.rect_rotation == 180 or square.rect_rotation == -180:
		square.rect_rotation = 0
	if square.rect_rotation == -90:
		square.rect_rotation = 90 
		
	var size_y = square.get_node("Area2DSquare/square").rect_size.y
	var height = (size_y - 4)/(56 - 4)
	var size_x = square.get_node("Area2DSquare/square").rect_size.x
	var width = (size_x - 4)/(56 - 4)
	
	var positionModification = Vector2(0,0)
	var borderCollidingFix = Vector2(0,0)
	
	if square.rect_rotation as int == 90 or square.rect_rotation as int == -90:
		rotationFixVector.x = 4
		positionModification = Vector2(height, 0)
		
	var pos_x = (square.rect_position.x)/52
	var pos_y = (square.rect_position.y)/52
	if pos_x+height>20:
		borderCollidingFix.x = (20-pos_x-height)*52
	elif pos_x+width>20:
		borderCollidingFix.x = (20-pos_x-width)*52
	if pos_y+height>20:
		borderCollidingFix.y = (20-pos_y-height)*52
	elif pos_y+width>20:
		borderCollidingFix.y = (20-pos_y-width)*52
	rotationFixVector += positionModification*52
	square.rect_position += rotationFixVector + borderCollidingFix

func change_team():
	if whoPlays == 0:
		cursorSquare.modulate(COLOR_TEAM_TWO)
		NODE_MobileMenu_Joystick.modulate = COLOR_TEAM_TWO
		NODE_MobileMenu_placeButton.modulate = COLOR_TEAM_TWO
		NODE_MobileMenu_rotateButton.modulate = COLOR_TEAM_TWO
		whoPlays = 1
	elif whoPlays == 1:
		cursorSquare.modulate(COLOR_TEAM_ONE)
		NODE_MobileMenu_Joystick.modulate = COLOR_TEAM_ONE
		NODE_MobileMenu_placeButton.modulate = COLOR_TEAM_ONE
		NODE_MobileMenu_rotateButton.modulate = COLOR_TEAM_ONE
		whoPlays = 0
	print("Team changed. Now playing: Player ", whoPlays + 1)

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

	var shadow = squareScene.get_node("shadowSquare")
	
	shadow.rect_position = Vector2(-5,-5)
	shadow.rect_size = sizeVector + Vector2(10,10)


	return squareScene

func get_PlayerSquares_node(team):
	if team == 0:
		return NODE_PlayerSquares_1
	elif team == 1:
		return NODE_PlayerSquares_2

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
		NODE_PlayerSquares.add_child(currentSquareToPlace)
		currentSquareToPlace.rect_position = lastMousePosition-FIELD_POSITION
		rotationFixVector = Vector2(0,0)
		start_dice_animation_orSmth()
	elif testingForEnd(width, height) == false:
		gameStage = GameStages.TESTED
		NODE_PlayerSquares.add_child(currentSquareToPlace)
		currentSquareToPlace.rect_position = lastMousePosition-FIELD_POSITION
		rotationFixVector = Vector2(0,0)
		start_dice_animation_orSmth()
	else:
		gameStage = GameStages.END
		print("GameStage = ", gameStage)
		
		NODE_PlayerSquares.add_child(currentSquareToPlace)
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
		NODE_debuggingText.text = string
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
		cursorSquare.modulate(COLOR_TEAM_ONE)
		NODE_MobileMenu_placeButton.modulate = COLOR_TEAM_ONE
	else:
		cursorSquare.modulate(COLOR_TEAM_TWO)
		NODE_MobileMenu_placeButton.modulate = COLOR_TEAM_TWO

func _on_beforeEndTimer_timeout():
	if gameStage == GameStages.PAUSE:
		NODE_beforeEndTimer.start()
		pass
	elif beforeEndSecondsSpent != BEFORE_END_SECONDS-1:
		beforeEndSecondsSpent+=1
		#$beforeEndLabel.text = (BEFORE_END_SECONDS - beforeEndSecondsSpent) as String
		NODE_beforeEndTimer.start()
	else:
		#$beforeEndLabel.hide()
		gameStage = GameStages.END_MENU
		print("GameStage = ", gameStage)
		showEndMenu()
		pass
	pass # Replace with function body.

func _on_pauseButton_button_up():
	if gameStage != GameStages.MENU and gameStage != GameStages.END_MENU:
		if NODE_Menu_pause.visible == false:
			pausePreviousGameStage = gameStage
			gameStage = GameStages.PAUSE
			print("GameStage = ", gameStage)
			cursorSquare.hide()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			NODE_Menu_pause.visible = true
		else:
			_on_pauseMenuContinue_button_up()

func _on_pauseMenuContinue_button_up():
	gameStage = pausePreviousGameStage
	print("GameStage = ", gameStage)
	NODE_Menu_pause.hide()
	cursorSquare.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	pass # Replace with function body.

func _on_pauseMenuSurrender_button_up():
	NODE_Menu_pause.hide()
	#$beforeEndLabel.hide()
	gameStage = GameStages.END_MENU
	print("GameStage = ", gameStage)
	showEndMenu()
	pass # Replace with function body.

func mobile_move_cursor(joy_pos):
	var pos_x = stepify(mobileCursorPosition.x-FIELD_START_POINT.x, 52)/52
	var pos_y = stepify(mobileCursorPosition.y-FIELD_START_POINT.y, 52)/52
		
	print(pos_x, " ",pos_y) 	
	
	var square = currentSquareToPlace.get_node("Area2DSquare/square")
	
	var width = (square.rect_size.x - 4)/(56 - 4)
	var height = (square.rect_size.y - 4)/(56 - 4)
	
	if currentSquareToPlace.rect_rotation as int == 90:
		var temp = width
		width = height
		height = temp
		pass
	
	if joy_pos.x>0.4 and pos_x < 20-width:
		mobileCursorPosition.x += 52
	if joy_pos.y>0.4 and pos_y < 20-height:
		mobileCursorPosition.y += 52
	if joy_pos.x<-0.4 and pos_x > 0:
		mobileCursorPosition.x -= 52
	if joy_pos.y<-0.4 and pos_y > 0:
		mobileCursorPosition.y -= 52
	
	pos_x = stepify(mobileCursorPosition.x-FIELD_START_POINT.x, 52)/52
	pos_y = stepify(mobileCursorPosition.y-FIELD_START_POINT.y, 52)/52
	
	if not (pos_x < 0 or pos_y < 0 or pos_x > 20-width or pos_y > 20-height):		
		if gameStage != GameStages.PAUSE:	
			var x_pos = stepify(mobileCursorPosition.x-FIELD_START_POINT.x, 52)+FIELD_START_POINT.x
			var y_pos = stepify(mobileCursorPosition.y-FIELD_START_POINT.y, 52)+FIELD_START_POINT.y
			var currentSquarePos = Vector2(x_pos, y_pos)				
			currentSquareToPlace.rect_position = currentSquarePos + rotationFixVector
	pass

func _on_PlaceButton_button_up():
	if not placingRules():
		showErrorOnPlacing()
		return
	else:
		place_squareToPlace()
		
		if whoPlays == 0:
			mobileCursorPosition = FIELD_START_POINT
			
		elif whoPlays == 1:
			
			var square = currentSquareToPlace.get_node("Area2DSquare/square")
	
			var width = (square.rect_size.x - 4)/(56 - 4)
			var height = (square.rect_size.y - 4)/(56 - 4)
			
			var pos_x = (20-width)*52+FIELD_START_POINT.x
			var pos_y = (20-height)*52+FIELD_START_POINT.y
						
			mobileCursorPosition = Vector2(pos_x, pos_y)
			
			mobile_move_cursor(Vector2(0,0))
	pass # Replace with function body.

func _on_RotateButton_button_up():
	rotate_square(currentSquareToPlace,-90)
	NODE_MobileMenu_rotateButton.modulate = get_players_color(whoPlays)
	pass # Replace with function body.

func _on_PlaceButton_button_down():
	NODE_MobileMenu_placeButton.modulate = Color("BEBEBE")
	pass # Replace with function body.


func _on_RotateButton_button_down():
	NODE_MobileMenu_rotateButton.modulate = Color("BEBEBE")
	pass # Replace with function body.
