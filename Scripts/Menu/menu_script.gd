extends Node

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	pass # Replace with function body.

func _on_StartGameButton_button_up():
	get_tree().change_scene("res://Scenes/gameScene.tscn")

func _on_HowToPlayButton_button_up():
	get_tree().change_scene("res://Scenes/howToPlayScene.tscn")


func _on_ExitGameButton_button_up():
	get_tree().quit()
