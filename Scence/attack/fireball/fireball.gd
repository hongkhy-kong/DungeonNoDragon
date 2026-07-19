extends Area2D

@export var speed: float = 220.0
@export var damage: int = 15

var direction: Vector2 = Vector2.RIGHT


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(dir: Vector2, dmg: int) -> void:
	direction = dir.normalized()
	damage = dmg


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	elif body.is_in_group("wall"):
		queue_free()
