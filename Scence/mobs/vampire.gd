extends CharacterBody2D

signal died

enum State {
	ALIVE,
	DEAD
}

var current_state = State.ALIVE
var player_in_attack_area = false

@export var speed := 10.0
@export var max_hp := 50
@export var damage := 10

var hp : int
var player: Node2D = null
var can_attack := true
var is_chasing := false


func _ready():
	hp = max_hp
	print("Vampire Ready")


# -------------------------
# 👁️ Detection System
# -------------------------
func _on_detection_body_entered(body: Node2D) -> void:
	print("Something entered:", body.name)

	if body.is_in_group("player"):
		player = body
		is_chasing = true
		print("Player detected")


func _on_detection_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		is_chasing = false
		print("Player left detection")


# -------------------------
# 🏃 Movement
# -------------------------
func _physics_process(delta):

	if is_chasing and player != null:

		var distance = global_position.distance_to(player.global_position)

		if distance > 10:
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * speed
		else:
			velocity = Vector2.ZERO

	else:
		velocity = Vector2.ZERO

	move_and_slide()


# -------------------------
# ⚔️ Attack System
# -------------------------
func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_attack_area = true

		if can_attack:
			attack(body)


func _on_attack_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_attack_area = false


func attack(target: Node2D) -> void:
	can_attack = false

	if target.has_method("take_damage"):
		target.take_damage(damage)
		print("Vampire attacked player")

	$Timer.start()


func _on_timer_timeout() -> void:
	can_attack = true

	if player_in_attack_area and player != null:
		attack(player)


# -------------------------
# 💀 Damage System
# -------------------------
func take_damage(amount: int) -> void:
	hp -= amount
	print("Vampire HP:", hp)

	if hp <= 0:
		die()


func die() -> void:

	if current_state == State.DEAD:
		return

	current_state = State.DEAD

	print("Vampire Died")

	emit_signal("died")

	set_physics_process(false)

	$CollisionShape2D.set_deferred("disabled", true)

	var tween = create_tween()

	tween.tween_property(
		self,
		"modulate:a",
		0.0,
		0.5
	)

	await tween.finished

	queue_free()
