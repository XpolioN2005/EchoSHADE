extends ColorRect


var mat = ShaderMaterial.new()
func _ready():
	mat.shader = load("res://shaders/cutout.gdshader")
	material = mat

	mat.set_shader_parameter("rect_size", size)
	mat.set_shader_parameter("base_color", color)


	# Example points
	mat.set_shader_parameter("num_points", 1)
	mat.set_shader_parameter("points", [%player.global_position])
	mat.set_shader_parameter("radius", 50)

func _physics_process(_delta):
	
	mat.set_shader_parameter("points", [%player.global_position])
