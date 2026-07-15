extends CharacterBody2D

signal died

enum State {
	IDLE,
	CHASE,
	ATTACK,
	DEAD
}

@export var speed: float = 10.0
@export var max_hp: int = 50
@export var damage: int = 10
@export var attack_distance: float = 10.0
@export var attack_offset: float = 8.0
@export var attack_cooldown: float = 1.0
@export var attack_windup: float = 0.5

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var detection_shape: CollisionShape2D = $Detection/CollisionShape2D
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var timer: Timer = $Timer

var hp: int
var current_state: State = State.IDLE

var player: Node2D = null
var can_attack := true
var preparing_attack := false
var player_in_attack_area := false
var facing_dir: Vector2 = Vector2.DOWN


func _ready() -> void:
	hp = max_hp
	current_state = State.IDLE
	play_idle_animation()


func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	match current_state:
		State.IDLE:
			idle_state()
		State.CHASE:
			chase_state()
		State.ATTACK:
			attack_state()

	update_attack_area()
	move_and_slide()


func idle_state() -> void:
	velocity = Vector2.ZERO
	play_idle_animation()

	if player != null and is_instance_valid(player):
		current_state = State.CHASE


func chase_state() -> void:
	if player == null or !is_instance_valid(player):
		current_state = State.IDLE
		velocity = Vector2.ZERO
		play_idle_animation()
		return

	var dir := player.global_position - global_position
	var distance := dir.length()

	if distance <= attack_distance:
		velocity = Vector2.ZERO
		current_state = State.ATTACK
		return

	facing_dir = dir.normalized()
	velocity = facing_dir * speed
	play_walk_animation()


func attack_state() -> void:
	if player == null or !is_instance_valid(player):
		current_state = State.IDLE
		velocity = Vector2.ZERO
		play_idle_animation()
		return

	var dir := player.global_position - global_position
	var distance := dir.length()

	if distance > attack_distance * 1.25:
		current_state = State.CHASE
		return

	velocity = Vector2.ZERO

	if can_attack and !preparing_attack:
		start_attack()


func _on_detection_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		current_state = State.CHASE
		print("Player detected")


func _on_detection_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		player_in_attack_area = false
		preparing_attack = false
		current_state = State.IDLE
		velocity = Vector2.ZERO
		play_idle_animation()
		print("Player left detection")


func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_attack_area = true
		if current_state != State.DEAD:
			current_state = State.ATTACK


func _on_attack_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		await get_tree().create_timer(0.1).timeout

		for b in attack_area.get_overlapping_bodies():
			if b.is_in_group("player"):
				return

		player_in_attack_area = false


func start_attack() -> void:
	if current_state == State.DEAD:
		return

	if player == null or !is_instance_valid(player):
		return

	preparing_attack = true
	can_attack = false
	current_state = State.ATTACK

	var dir := player.global_position - global_position
	facing_dir = dir.normalized()

	if abs(dir.x) > abs(dir.y):
		anim.flip_h = dir.x < 0
		anim.play("attack_right")
	else:
		anim.flip_h = false
		if dir.y > 0:
			anim.play("attack_down")
		else:
			anim.play("attack_up")

	await get_tree().create_timer(attack_windup).timeout

	if current_state == State.DEAD:
		return

	if player != null \
	and is_instance_valid(player) \
	and global_position.distance_to(player.global_position) <= attack_distance * 1.25:
		attack()

	preparing_attack = false
	timer.start(attack_cooldown)


func attack() -> void:
	if current_state == State.DEAD:
		return

	if player != null \
	and is_instance_valid(player) \
	and player.has_method("take_damage"):
		player.take_damage(damage)
		print("Enemy attacked player!")


func _on_timer_timeout() -> void:
	can_attack = true

	if current_state == State.DEAD:
		return

	if player == null or !is_instance_valid(player):
		current_state = State.IDLE
		return

	var distance := global_position.distance_to(player.global_position)

	if distance <= attack_distance * 1.25:
		current_state = State.ATTACK
	else:
		current_state = State.CHASE


func play_walk_animation() -> void:
	if anim.animation != "walk":
		anim.play("walk")

	if facing_dir.x > 0:
		anim.flip_h = false
	elif facing_dir.x < 0:
		anim.flip_h = true


func play_idle_animation() -> void:
	if anim.animation != "idle_left_right":
		anim.play("idle_left_right")

	if facing_dir.x > 0:
		anim.flip_h = false
	elif facing_dir.x < 0:
		anim.flip_h = true


func update_attack_area() -> void:
	var offset := Vector2.ZERO

	if abs(facing_dir.x) > abs(facing_dir.y):
		if facing_dir.x > 0:
			offset = Vector2(attack_offset, 0)
			anim.flip_h = false
		else:
			offset = Vector2(-attack_offset, 0)
			anim.flip_h = true
	else:
		if facing_dir.y > 0:
			offset = Vector2(0, attack_offset)
		else:
			offset = Vector2(0, -attack_offset)

	attack_area.position = offset


func take_damage(amount: int) -> void:
	if current_state == State.DEAD:
		return

	hp -= amount
	print("Enemy HP:", hp)

	if hp <= 0:
		die()


func die() -> void:
	if current_state == State.DEAD:
		return

	current_state = State.DEAD
	velocity = Vector2.ZERO
	can_attack = false
	preparing_attack = false

	emit_signal("died")

	body_shape.set_deferred("disabled", true)
	attack_shape.set_deferred("disabled", true)
	detection_shape.set_deferred("disabled", true)

	# Stop on the current frame
	anim.pause()

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)

	await tween.finished

	queue_free()
