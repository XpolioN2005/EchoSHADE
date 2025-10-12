extends Area2D

@export var enemy_scene: PackedScene
var holder: Node
var _is_spawning: bool = false
const SPAWN_ANIM := "break"
const IDLE_ANIM := "idle"

@onready var sound = $glass_break

func _ready() -> void:
    $AnimatedSprite2D.play(IDLE_ANIM)
    $AnimatedSprite2D.connect("animation_finished", Callable(self, "_on_sprite_animation_finished"))

func _on_body_entered(body: Node2D) -> void:
    if not body.is_in_group("player"):
        return
    if _is_spawning:
        return
    _is_spawning = true
    set_deferred("monitoring", false)   # avoid retriggers while spawning
    $AnimatedSprite2D.play(SPAWN_ANIM)  # must be non-looping
    sound.play()

func _on_sprite_animation_finished() -> void:
    if $AnimatedSprite2D.animation != SPAWN_ANIM:
        # some other animation finished — just reset
        _is_spawning = false
        set_deferred("monitoring", true)
        return

    await get_tree().create_timer(3).timeout
    holder = get_tree().get_first_node_in_group("enemy_holder")
    if holder and enemy_scene:
        var inst = enemy_scene.instantiate()
        inst.global_position = global_position
        holder.add_child(inst)

    # needed cant just do Queue_free()... as it need time to set the global pos
    call_deferred("queue_free")
