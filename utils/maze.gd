extends Node2D

@onready var tilemap: TileMapLayer = $TileMapLayer

# Maze parameters
@export var ROWS := 25
@export var COLS := 25
@export var CELL_SIZE := 1  # tile size in tiles, not pixels
@export var SEED := 0
@export var MIRROR_PERCENT := 0.3

# loop settings
@export var LOOP_PERCENT := 0.025  # fraction of cells to consider for extra openings (0.0 - 1.0)
@export var LOOP_COUNT := 0      # if >0, overrides LOOP_PERCENT and uses this exact count

# Internal data
var maze = []        # 2D grid of 0 = path, 1 = wall
var mirrors = []     # Positions of mirror tiles
var is_mirror_loaded = false
var rng := RandomNumberGenerator.new()

# Tile IDs (assumes atlas with at least 2 tiles: wall=0, path=1, mirror=2)
const TILE_WALL = Vector2i(0, 0)
const TILE_PATH = Vector2i(1, 0)
const TILE_MIRROR = Vector2i(2, 0)


func _ready():
	make_maze()
	

func randomize_seed():
	if SEED != 0:
		rng.seed = SEED
	else:
		rng.randomize()

func initialize_maze():
	maze.clear()
	for y in range(ROWS):
		var row = []
		for x in range(COLS):
			row.append(1)
		maze.append(row)

func generate_maze_iterative():
	initialize_maze()
	var dirs = [Vector2i(-2, 0), Vector2i(2, 0), Vector2i(0, -2), Vector2i(0, 2)]
	var start = Vector2i(1, 1)
	maze[start.y][start.x] = 0

	var stack = [start]
	while stack.size() > 0:
		var current = stack.back()
		var neighbors = []
		for d in dirs:
			var nx = current.x + d.x
			var ny = current.y + d.y
			if nx > 0 and nx < COLS - 1 and ny > 0 and ny < ROWS - 1 and maze[ny][nx] == 1:
				neighbors.append(d)
		if neighbors.size() > 0:
			var dir = neighbors[rng.randi_range(0, neighbors.size() - 1)]
			var mid = current + dir / 2
			var next = current + dir
			maze[mid.y][mid.x] = 0
			maze[next.y][next.x] = 0
			stack.append(next)
		else:
			stack.pop_back()

func add_loops():
	# Build candidate list: wall cells that sit between two path tiles (vertical or horizontal)
	var candidates: Array = []
	for y in range(1, ROWS - 1):
		for x in range(1, COLS - 1):
			if maze[y][x] == 1:
				# check vertical neighbors (path above & below)
				if maze[y - 1][x] == 0 and maze[y + 1][x] == 0:
					candidates.append(Vector2i(x, y))
					continue
				# check horizontal neighbors (path left & right)
				if maze[y][x - 1] == 0 and maze[y][x + 1] == 0:
					candidates.append(Vector2i(x, y))
					continue

	var total_candidates = candidates.size()
	if total_candidates == 0:
		return

	# compute target count (GDScript-friendly)
	var target: int
	if LOOP_COUNT > 0:
		target = min(LOOP_COUNT, total_candidates)
	else:
		target = int(clamp(float(ROWS * COLS) * LOOP_PERCENT, 0.0, float(total_candidates)))

	target = int(clamp(target, 0, total_candidates))

	# shuffle candidates using rng
	for i in range(total_candidates - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var tmp = candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = tmp

	# open selected walls to create loops
	for i in range(target):
		var pos: Vector2i = candidates[i]
		maze[pos.y][pos.x] = 0

func place_mirrors(min_mirrors := 4):
	mirrors.clear()
	is_mirror_loaded = false

	# gather dead-ends
	var dead_ends: Array = []
	for y in range(1, ROWS - 1):
		for x in range(1, COLS - 1):
			if maze[y][x] == 0:
				var open_count = 0
				if maze[y - 1][x] == 0: open_count += 1
				if maze[y + 1][x] == 0: open_count += 1
				if maze[y][x - 1] == 0: open_count += 1
				if maze[y][x + 1] == 0: open_count += 1
				if open_count == 1:
					dead_ends.append(Vector2i(x, y))

	# shuffle dead_ends with rng
	for i in range(dead_ends.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var tmp = dead_ends[i]; dead_ends[i] = dead_ends[j]; dead_ends[j] = tmp

	var choose_from_dead = int(dead_ends.size() * clamp(MIRROR_PERCENT, 0.0, 1.0))
	# ensure we don't pick more than available
	choose_from_dead = min(choose_from_dead, dead_ends.size())

	for i in range(choose_from_dead):
		mirrors.append(dead_ends[i])

	# if we don't have the minimum yet, pick additional path tiles at random
	if mirrors.size() < min_mirrors:
		var path_cells: Array = []
		for y in range(1, ROWS - 1):
			for x in range(1, COLS - 1):
				if maze[y][x] == 0:
					var v = Vector2i(x, y)
					if not mirrors.has(v):
						path_cells.append(v)

		# shuffle path_cells with RNG
		for i in range(path_cells.size() - 1, 0, -1):
			var j = rng.randi_range(0, i)
			var tmp2 = path_cells[i]; path_cells[i] = path_cells[j]; path_cells[j] = tmp2

		var need = min_mirrors - mirrors.size()
		for i in range(min(need, path_cells.size())):
			mirrors.append(path_cells[i])

	# final safety: if we somehow still have zero mirrors (rare), place at random path
	if mirrors.size() == 0:
		for y in range(1, ROWS - 1):
			for x in range(1, COLS - 1):
				if maze[y][x] == 0:
					mirrors.append(Vector2i(x,y))
					return
	is_mirror_loaded = true

func apply_to_tilemap():
	tilemap.clear()
	for y in range(ROWS):
		for x in range(COLS):
			var tile = TILE_WALL if maze[y][x] == 1 else TILE_PATH
			tilemap.set_cell(Vector2i(x, y), 0, tile)
	
	# debug mirror
	for m in mirrors:
		tilemap.set_cell(m, 0, TILE_MIRROR)

func make_maze():
	randomize_seed()
	generate_maze_iterative()
	add_loops()
	place_mirrors()
	apply_to_tilemap()
	Pathfinder.setup(maze)
