extends Node

func _ready():
	pass # Replace with function body.

func _on_BackToMenuButton_button_up():
	get_tree().change_scene("res://Scenes/startMenuScene.tscn")
