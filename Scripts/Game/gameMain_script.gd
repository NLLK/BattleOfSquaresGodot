extends Node

var haveCursorSquare = false
var cursorSquare = get_colored_square(0)
var currentSquareToPlace
var whoPlays = 0

func _ready():
	pass 
	
func _on_StartGameButton_button_up():
	#добавить удаление кнопки
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)	

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and not event.pressed:
			create_object(1,1, event.position)
	elif event is InputEventMouseMotion:
		move_cursor(event.position)

func init_squareToPlace(width, height):
	
	pass

func create_object(width, height, mouse_position):
	
	var squareScene = get_colored_square(whoPlays)
	var collisionShape = squareScene.get_node("StaticBody2D").get_node("CollisionShape2D")
	var collisionShapeShape = squareScene.get_node("StaticBody2D").get_node("CollisionShape2D").shape
	var square = squareScene.get_node("StaticBody2D").get_node("square")
	
	var sizeVector = Vector2(square.rect_size.x*width,square.rect_size.y*height)

	#var x_pos = 320
	#var y_pos = 0
	var x_pos = stepify(mouse_position.x-320, 52)+320
	var y_pos = stepify(mouse_position.y, 52)+18
	
	var squareScenePos = Vector2(x_pos, y_pos)
	
	square.rect_size = sizeVector
	squareScene.rect_position = squareScenePos
	
	collisionShape.position = (sizeVector/2)
	collisionShapeShape.extents = (sizeVector/2)
	
	add_child(squareScene)
	
	haveCursorSquare = false
	
	pass

func move_cursor(position):
	if haveCursorSquare == false:
		cursorSquare.free()
		cursorSquare = get_colored_square(whoPlays)
		var a = cursorSquare.get_node("StaticBody2D").get_node("square")
		cursorSquare.rect_position = position
		add_child(cursorSquare)
		haveCursorSquare = true
	else:
		cursorSquare.rect_position = position
	

func get_colored_square(team):
	if team == 0:
		return load("res://Scenes/SquarePlayerOne.tscn").instance()
	else:
		return load("res://Scenes/SquarePlayerTwo.tscn").instance()
		


