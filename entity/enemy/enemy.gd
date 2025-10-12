extends Area2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var last_dir: Vector2 = Vector2.DOWN

# ===== CONFIG =====
@export var enemy_speed_walk: float = 60.0
@export var enemy_speed_run: float = 140.0
@export var wander_radius_tiles: int = 5            # random wander radius in tiles
@export var wander_pause_min: float = 0.6
@export var wander_pause_max: float = 2.0
@export var path_recalc_time: float = 0.6           # how often path is recalculated while chasing
@export var fov_distance: float = 300.0
@export var fov_angle_deg: float = 100.0            # angle cone in degrees to see player
@export var reach_threshold: float = 6.0            # world units to consider a waypoint reached

# ===== STATE =====
enum State { WANDER, CHASE, INVESTIGATE }
var state: State = State.WANDER

# ===== INTERNAL =====
@onready var root = get_tree().current_scene
@onready var player = get_tree().get_first_node_in_group("player")
var path: Array = []
var path_index: int = 0
var last_seen_pos: Vector2 = Vector2.ZERO

var _path_timer: Timer
var _wander_timer: Timer
var _is_moving: bool = false

func _ready():
	add_to_group("enemy")
	# timers used for regular path recalcs & wander pauses
	_path_timer = Timer.new()
	_path_timer.wait_time = path_recalc_time
	_path_timer.one_shot = false
	add_child(_path_timer)
	_path_timer.start()

	_wander_timer = Timer.new()
	_wander_timer.one_shot = true
	add_child(_wander_timer)
	_wander_timer.connect("timeout", Callable(self, "_on_wander_timeout"))

	_path_timer.connect("timeout", Callable(self, "_on_path_timer"))

	# start wandering immediately
	_start_wander()

func _physics_process(delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if not player:
			return

	# check senses every frame (fast)
	if _can_see_player():
		last_seen_pos = player.global_position
		if state != State.CHASE:
			state = State.CHASE
			_start_chase()
	else:
		if state == State.CHASE:
			# lost sight: go to last seen and investigate
			state = State.INVESTIGATE
			_go_to_world_position(last_seen_pos)
	
	# movement along path
	if _is_moving and path.size() > 0 and path_index < path.size():
		var target_grid = path[path_index]
		var target_world = Vector2(target_grid.x * 32 + 16, target_grid.y * 32 + 16)
		var dir = (target_world - global_position)
		var dist = dir.length()
		var move_vec = Vector2.ZERO
		if dist > 0.001:
			dir = dir.normalized()
			var speed = enemy_speed_run if (state == State.CHASE) else enemy_speed_walk
			move_vec = dir * speed * delta
			global_position += move_vec
		# update animation
		_update_animation(dir if dist > 0.001 else Vector2.ZERO)
		
		# reached waypoint
		if dist < reach_threshold:
			path_index += 1
			# if finished path
			if path_index >= path.size():
				_on_reached_path_end()
	else:
		# idle
		_update_animation(Vector2.ZERO)


# ---------- SENSING ----------
func _can_see_player() -> bool:
	if not player:
		return false
	var to_player = player.global_position - global_position
	var d = to_player.length()
	if d > fov_distance:
		return false
	# angle check - since enemy has no facing, we use omnidirectional but still allow angle cone:
	# if you want full omnidirectional vision set fov_angle_deg = 360
	var forward = Vector2(0, -1) # arbitrary forward; angle check can be removed if not needed
	var cos_allowed = cos(deg_to_rad(fov_angle_deg * 0.5))
	if fov_angle_deg < 360:
		var dot = forward.dot(to_player.normalized())
		if dot < cos_allowed:
			return false

	# raycast
	var space = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position)
	query.exclude = [self]
	query.collision_mask = 1  # optional: set if you want to limit ray to certain layers
	var result = space.intersect_ray(query)

	if result.is_empty():
		return true  # nothing hit, can see player
	if result["collider"] == player:
		return true
	return false


# ---------- PATH / MOVEMENT HELPERS ----------
func _grid_from_world(world_pos: Vector2) -> Vector2i:
	return Vector2i(round((world_pos.x - 16) / 32.0), round((world_pos.y - 16) / 32.0))

func _go_to_world_position(world_pos: Vector2) -> void:
	var start = _grid_from_world(global_position)
	var end = _grid_from_world(world_pos)
	path = Pathfinder.find_path(start, end)
	path_index = 0
	_is_moving = (path.size() > 0)

func _on_reached_path_end() -> void:
	_is_moving = false
	if state == State.INVESTIGATE:
		# finished going to last seen: small pause then resume wandering
		_start_wander()
	elif state == State.WANDER:
		# reached wander target -> pause a bit then pick new wander
		_start_wander_pause()

# ---------- WANDER ----------
func _start_wander() -> void:
	state = State.WANDER
	_pick_new_wander_target()

func _start_wander_pause() -> void:
	_is_moving = false
	var t = randf_range(wander_pause_min, wander_pause_max)
	_wander_timer.wait_time = t
	_wander_timer.start()

func _on_wander_timeout() -> void:
	_pick_new_wander_target()

func _pick_new_wander_target() -> void:
	# try a few random tiles until a valid path is found
	var attempts = 6
	var found = false
	for i in range(attempts):
		var rx = randi_range(-wander_radius_tiles, wander_radius_tiles)
		var ry = randi_range(-wander_radius_tiles, wander_radius_tiles)
		var target_grid = _grid_from_world(global_position) + Vector2i(rx, ry)
		var start = _grid_from_world(global_position)
		var p = Pathfinder.find_path(start, target_grid)
		if p.size() > 0:
			path = p
			path_index = 0
			_is_moving = true
			found = true
			break
	if not found:
		# fallback: stay idle a bit then retry
		_start_wander_pause()

# ---------- CHASE ----------
func _start_chase() -> void:
	# immediately set path to player's current gridpos
	_go_to_world_position(player.global_position)
	# ensure path recalcs continue while chasing
	if not _path_timer.is_stopped():
		_path_timer.start()

func _on_path_timer() -> void:
	if state == State.CHASE:
		# recalc chase path frequently
		_go_to_world_position(player.global_position)
	# else when not chasing we don't need frequent path recalcs

# ---------- UTIL ----------
func randi_range(a:int, b:int) -> int:
	return int(floor(randf() * (b - a + 1))) + a

# debug
#func _draw():
#    if player:
#        draw_line(Vector2.ZERO, to_local(player.global_position), Color.red)

func _update_animation(move_vec: Vector2) -> void:
	if move_vec == Vector2.ZERO:
		# always idle down
		anim.play("idle_down")
	else:
		# moving
		if abs(move_vec.x) > abs(move_vec.y):
			if move_vec.x > 0:
				anim.play("run_right")
				last_dir = Vector2.RIGHT
			else:
				anim.play("run_left")
				last_dir = Vector2.LEFT
		else:
			if move_vec.y > 0:
				anim.play("run_down")
				last_dir = Vector2.DOWN
			else:
				anim.play("run_up")
				last_dir = Vector2.UP

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		$sound.play()
		Global.is_gameover = true

