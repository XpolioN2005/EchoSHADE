extends Area2D

@onready var root = get_tree().current_scene
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var path = []
var current_path_index = 0
var speed = 150.0 
var is_hunting : bool = false

func _ready():
	global_position = Vector2((root.COLS-2)*32 +16,(root.ROWS-2)*32+16)
	update_path()  # initial pat%player

func _process(delta):
	if path.is_empty() or current_path_index >= path.size():
		_update_animation(Vector2.ZERO)
		return
	
	if not is_hunting:
		_update_animation(Vector2.ZERO)
		return

	# Get current target waypoint
	var target_grid = path[current_path_index]
	var target_world = Vector2(target_grid.x * 32 + 16, target_grid.y * 32 + 16)
	
	# Move towards target
	var direction = (target_world - global_position)
	var dist = direction.length()
	if dist > 0.001:
		direction = direction.normalized()
		global_position += direction * speed * delta
		_update_animation(direction)
	else:
		_update_animation(Vector2.ZERO)
	
	# Check if reached current waypoint
	if dist < 5.0:
		current_path_index += 1

func update_path():
	if not is_hunting:
		return
	var end = Vector2i(round((%player.global_position.x-16) / 32.0), round((%player.global_position.y-16) / 32.0))
	var start = Vector2i(round((global_position.x-16) / 32.0), round((global_position.y-16) / 32.0))
	path = Pathfinder.find_path(start, end)
	current_path_index = 0

func _on_path_timer_timeout() -> void:
	update_path()

func _on_start_hunt_timer_timeout() -> void:
	is_hunting = true
	%screen_fog.visible = true

# ----------------- ANIMATION -----------------
func _update_animation(move_vec: Vector2) -> void:
	if move_vec == Vector2.ZERO:
		anim.play("idle_down")  # always face down when idle
	else:
		if abs(move_vec.x) > abs(move_vec.y):
			if move_vec.x > 0:
				anim.play("run_right")
			else:
				anim.play("run_left")
		else:
			if move_vec.y > 0:
				anim.play("run_down")
			else:
				anim.play("run_up")


func _on_body_entered(body:Node2D) -> void:
	if body.is_in_group("player"):
		$sound.play()
		Global.is_gameover = true