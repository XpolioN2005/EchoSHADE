extends CharacterBody2D

@export var speed: float = 20000

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	add_to_group("player")
	sprite.play("idle_down") # default animation at start

func _physics_process(delta):
	var input_vector = Vector2.ZERO
	
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()  # prevents faster diagonal movement
		velocity = input_vector * speed * delta
		move_and_slide()
		
		# Determine animation based on movement direction
		if abs(input_vector.x) > abs(input_vector.y):
			if input_vector.x > 0:
				sprite.play("run_right")
			else:
				sprite.play("run_left")
		else:
			if input_vector.y > 0:
				sprite.play("run_down")
			else:
				sprite.play("run_up")
	else:
		velocity = Vector2.ZERO
		move_and_slide()
		# idle animation based on last direction
		
		sprite.play("idle_down")
