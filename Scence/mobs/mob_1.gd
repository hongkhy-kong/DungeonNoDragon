extends CharacterBody2D

signal died

enum State {
	ALIVE,
	DEAD
}

@export var speed: float = 10.0
@export var max_hp: int = 50
@export var damage: int = 10
@export var attack_distance: float = 12.0
@export var attack_offset: float = 18.0
@export var attack_windup := 0.5

var hp: int
var current_state := State.ALIVE

var player: Node2D = null
var is_chasing := false
var player_in_attack_area := false
var can_attack := true
var preparing_attack := false
var facing_dir := Vector2.DOWN


func _ready() -> void:
	hp = max_hp


# =====================================================
# Detection
# =====================================================

func _on_detection_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		is_chasing = true
		print("Player detected")


func _on_detection_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		is_chasing = false
		player_in_attack_area = false
		velocity = Vector2.ZERO
		print("Player left detection")


# =====================================================
# Movement
# =====================================================

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	if player == null or !is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var dir := player.global_position - global_position
	var distance := dir.length()

	if distance > attack_distance:
		facing_dir = dir.normalized()
		velocity = facing_dir * speed
	else:
		velocity = Vector2.ZERO

	update_attack_area()
	move_and_slide()


func update_attack_area() -> void:
	var offset := Vector2.ZERO

	if abs(facing_dir.x) > abs(facing_dir.y):
		if facing_dir.x > 0:
			offset = Vector2(attack_offset, 0)
			$AnimatedSprite2D.flip_h = true
		else:
			offset = Vector2(-attack_offset, 0)
			$AnimatedSprite2D.flip_h = false
	else:
		$AnimatedSprite2D.flip_h = false
		if facing_dir.y > 0:
			offset = Vector2(0, attack_offset)
		else:
			offset = Vector2(0, -attack_offset)

	$AttackArea.position = offset


# =====================================================
# Attack
# =====================================================

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_attack_area = true

		if can_attack and !preparing_attack:
			start_attack()


func _on_attack_area_body_exited(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return

	await get_tree().create_timer(1.0).timeout

	for b in $AttackArea.get_overlapping_bodies():
		if b.is_in_group("player"):
			return

	player_in_attack_area = false


func _process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	if player_in_attack_area \
	and can_attack \
	and !preparing_attack \
	and player != null \
	and is_instance_valid(player):

		start_attack()


func start_attack() -> void:
	if current_state == State.DEAD:
		return

	preparing_attack = true

	var dir := player.global_position - global_position

	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			$AnimatedSprite2D.flip_h = true
			$AnimatedSprite2D.play("attack_left")
		else:
			$AnimatedSprite2D.flip_h = false
			$AnimatedSprite2D.play("attack_left")
	else:
		$AnimatedSprite2D.flip_h = false
		if dir.y > 0:
			$AnimatedSprite2D.play("attack_down")
		else:
			$AnimatedSprite2D.play("attack_up")

	await get_tree().create_timer(attack_windup).timeout

	preparing_attack = false

	if player_in_attack_area \
	and player != null \
	and is_instance_valid(player):
		attack()


func attack() -> void:
	if current_state == State.DEAD:
		return

	can_attack = false

	if player != null \
	and is_instance_valid(player) \
	and player.has_method("take_damage"):

		player.take_damage(damage)
		print("Enemy attacked player!")

	$Timer.start()


func _on_timer_timeout() -> void:
	can_attack = true

	if player_in_attack_area \
	and !preparing_attack \
	and player != null \
	and is_instance_valid(player):

		start_attack()


# =====================================================
# Damage
# =====================================================

func take_damage(amount: int) -> void:
	if current_state == State.DEAD:
		return

	print("take_damage called!")
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
	set_process(false)

	$CollisionShape2D.set_deferred("disabled", true)
	$AttackArea/CollisionShape2D.set_deferred("disabled", true)
	$Detection/CollisionShape2D.set_deferred("disabled", true)

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)

	await tween.finished
	queue_free()
