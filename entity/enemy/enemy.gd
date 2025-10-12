extends Area2D

@onready var root = get_tree().current_scene
@onready var player = get_tree().get_first_node_in_group("player")

var path = []
var current_path_index = 0
var speed = 100.0  

func _ready():
	add_to_group("enemy")

	var end = Vector2i(round((player.global_position.x-16) / 32.0), round((player.global_position.y-16) / 32.0))
	path = Pathfinder.find_path(root.mirrors[0], end)
	current_path_index = 0

func _process(delta):
	if path.is_empty() or current_path_index >= path.size():
		return
	
	# Get current target waypoint
	var target_grid = path[current_path_index]
	var target_world = Vector2(target_grid.x * 32 + 16, target_grid.y * 32 + 16)
	
	# Move towards target
	var direction = (target_world - global_position).normalized()
	global_position += direction * speed * delta
	
	# Check if reached current waypoint
	if global_position.distance_to(target_world) < 5.0:
		current_path_index += 1

func update_path():
	var end = Vector2i(round((player.global_position.x-16) / 32.0), round((player.global_position.y-16) / 32.0))
	var start = Vector2i(round((global_position.x-16) / 32.0), round((global_position.y-16) / 32.0))
	path = Pathfinder.find_path(start, end)
	current_path_index = 0

func _on_path_timer_timeout() -> void:
	update_path()
