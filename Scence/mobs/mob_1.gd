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

var hp := max_hp
var player: Node2D = null
var can_attack := true
var is_chasing := false


# -------------------------
# 👁️ Detection System
# -------------------------
func _on_detection_body_entered(body: Node2D) -> void:
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

		# Stop when close enough to attack
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
		print("Enemy attacked player")

	$Timer.start()


func _on_timer_timeout() -> void:
	can_attack = true

	# Attack again if player still inside area
	if player_in_attack_area and player != null:
		attack(player)

# -------------------------
# 💀 Damage System
# -------------------------
func take_damage(amount: int) -> void:
	hp -= amount
	print("Enemy HP:", hp)

	if hp <= 0:
		die()


func die() -> void:

	if current_state == State.DEAD:
		return

	current_state = State.DEAD

	print("Enemy Died")

	emit_signal("died")

	set_physics_process(false)

	# Disable collisions
	$CollisionShape2D.disabled = true

	# Fade out
	var tween = create_tween()

	tween.tween_property(
		self,
		"modulate:a",
		0.0,
		0.5
	)

	await tween.finished

	queue_free()


func enemy():
	pass
