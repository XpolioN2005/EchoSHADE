extends Control

@onready var main = $main_ui
@onready var gameovr = $gameover
@onready var gamewon = $won

func _process(_delta):
	if Global.is_gameover:
		gameovr.visible = true
		main.visible = false
		gamewon.visible = false
	elif  Global.is_gamewon:
		gameovr.visible = false
		main.visible = false
		gamewon.visible = true
	else:
		gameovr.visible = false
		main.visible = true
		gamewon.visible = false
