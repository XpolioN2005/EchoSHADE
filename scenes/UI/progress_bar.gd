extends ProgressBar

var total_time := 60.0  # total duration in seconds
var current_time := 60.0

func _ready() -> void:

	add_to_group("count_down")
	
	value = max_value  # Start full
	max_value = total_time
	min_value = 0

func _process(delta: float) -> void:
	current_time -= delta
	value = current_time

	Global.time_passed = value

	if current_time <= 0:
		current_time = 0
		value = 0
		set_process(false)  # stop updating once timer hits 0
		print("Time's up!")
