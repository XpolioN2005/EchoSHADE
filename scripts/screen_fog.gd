extends ColorRect


var mat = ShaderMaterial.new()
func _ready():
	mat.shader = load("res://shaders/screen_fog.gdshader")
	material = mat

	mat.set_shader_parameter("rect_size", size)
	