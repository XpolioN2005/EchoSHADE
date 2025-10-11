extends CharacterBody2D

@export var speed: float = 20000

func _physics_process(delta):
    var input_vector = Vector2.ZERO
    
    input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
    input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
    
    if input_vector != Vector2.ZERO:
        input_vector = input_vector.normalized()  # prevents faster diagonal movement
        velocity = input_vector * speed *delta
    else:
        velocity = Vector2.ZERO
    
    move_and_slide()
