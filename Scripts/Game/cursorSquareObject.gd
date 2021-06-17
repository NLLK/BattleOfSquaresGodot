extends Object

class_name cursorSquareObject
var cursorSquare
var isMobile
func _init(cursorSquare, isMobile):
	self.cursorSquare = cursorSquare
	self.isMobile = isMobile
	pass

func show():
	if !isMobile:
		cursorSquare.show()
	
func hide():
	if !isMobile:
		cursorSquare.hide()
func modulate(color):
	cursorSquare.modulate = color

func rect_position(rect_position):
	cursorSquare.rect_position = rect_position
	
func visible():
	if !isMobile:
		return cursorSquare.visible
	else:
		return false
