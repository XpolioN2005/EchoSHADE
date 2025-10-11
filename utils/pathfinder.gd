#Pathfinding.gd
extends Node
class_name Pathfinding

# Simple A* Pathfinding for grid-based maps
# AutoLoad script

var grid : Array = []  # 2D array (0 = free, 1 = wall)
var grid_size : Vector2i

func setup(_grid : Array) -> void:
	grid = _grid
	grid_size = Vector2i(len(grid[0]), len(grid))

func is_valid(pos: Vector2i) -> bool:
	return (
		pos.x >= 0 and pos.y >= 0
		and pos.x < grid_size.x
		and pos.y < grid_size.y
		and grid[pos.y][pos.x] == 0
	)

func get_neighbors(pos: Vector2i) -> Array:
	var dirs = [
		Vector2i(0, -1),  # up
		Vector2i(1, 0),   # right
		Vector2i(0, 1),   # down
		Vector2i(-1, 0)   # left
	]
	var result: Array = []
	for d in dirs:
		var n = pos + d
		if is_valid(n):
			result.append(n)
	return result

func heuristic(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array:
	var path: Array = [current]
	while came_from.has(current):
		current = came_from[current]
		path.insert(0, current)
	return path

func find_path(start: Vector2i, goal: Vector2i) -> Array:
	if not is_valid(start) or not is_valid(goal):
		return []

	var open_set: Array = [start]
	var came_from: Dictionary = {}

	var g_score: Dictionary = {}
	var f_score: Dictionary = {}
	g_score[start] = 0
	f_score[start] = heuristic(start, goal)

	while open_set.size() > 0:
		# Get node with lowest f_score
		var current = open_set[0]
		for node in open_set:
			if f_score.get(node, INF) < f_score.get(current, INF):
				current = node

		if current == goal:
			return reconstruct_path(came_from, current)

		open_set.erase(current)
		for neighbor in get_neighbors(current):
			var tentative_g = g_score.get(current, INF) + 1
			if tentative_g < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + heuristic(neighbor, goal)
				if not open_set.has(neighbor):
					open_set.append(neighbor)

	return []
