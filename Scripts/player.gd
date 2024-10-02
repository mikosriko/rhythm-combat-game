extends CharacterBody2D

const SPEED := 100.0
@onready var sprite: Sprite2D = $Sprite2D # Replace when adding animations

func _physics_process(delta: float) -> void:
	movement()

func movement() -> void:
	var direction := Input.get_vector("left", "right", "up", "down")
	velocity = direction * SPEED
	
	if direction.x < 0:
		sprite.flip_h = true
	elif direction.x > 0:
		sprite.flip_h = false
		
	move_and_slide()
