extends Node

var is_gameover := false
var is_gamewon := false

var time_passed = 60
func _process(_delta):
	if time_passed == 0:
		is_gamewon = true

	
