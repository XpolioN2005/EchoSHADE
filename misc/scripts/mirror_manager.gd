extends Node2D

@export var mirror_scene: PackedScene

@onready var root = get_tree().current_scene

func _ready():
	while !root.is_mirror_loaded:
		await get_tree().create_timer(0.1).timeout
	if mirror_scene and root.mirrors:
		for mirror in root.mirrors:
			var inst = mirror_scene.instantiate()
			inst.global_position = Vector2((mirror.x)*32 +16,(mirror.y)*32+16)
			$holder.add_child(inst)
