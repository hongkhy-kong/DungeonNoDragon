extends CharacterBody2D

signal died

enum State {
	IDLE,
	CHASE,
	MELEE_ATTACK,
	FIREBALL_ATTACK,
	DEAD
}

@export var max_hp: int = 500

@export var speed_phase1: float = 45.0
@export var speed_phase2: float = 60.0

@export var melee_range: float = 38.0
@export var fireball_range: float = 180.0

@export var melee_damage: int = 20
@export var fireball_damage: int = 15

@export var melee_windup_time: float = 0.25
@export var melee_recover_time: float = 0.50

@export var fireball_windup_time: float = 0.35
@export var fireball_recover_time: float = 1.00

@export var fireball_scene: PackedScene

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var detection_area: Area2D = $Detection

var hp: int
var player: Node2D = null
var state: State = State.IDLE
var phase: int = 1

var attack_in_progress: bool = false
var can_fireball: bool = true
var dead: bool = false
var facing: Vector2 = Vector2.DOWN


func _ready() -> void:
	hp = max_hp

	# Connect signals safely
	if not detection_area.body_entered.is_connected(Callable(self, "_on_detection_body_entered")):
		detection_area.body_entered.connect(Callable(self, "_on_detection_body_entered"))

	if not detection_area.body_exited.is_connected(Callable(self, "_on_detection_body_exited")):
		detection_area.body_exited.connect(Callable(self, "_on_detection_body_exited"))

	anim.play("idle")


func _physics_process(delta: float) -> void:
	if dead:
		return

	if hp <= 0:
		die()
		return

	# Phase 2 starts at 50% HP
	if phase == 1 and hp <= max_hp / 2:
		phase = 2
		print("PHASE 2")
		speed_phase2 = max(speed_phase2, speed_phase1 + 10.0)

	if player == null:
		_set_state(State.IDLE)
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if attack_in_progress:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var distance := global_position.distance_to(player.global_position)

	# Decide state
	if distance <= melee_range:
		_set_state(State.MELEE_ATTACK)
	elif phase == 2 and can_fireball and distance <= fireball_range:
		_set_state(State.FIREBALL_ATTACK)
	else:
		_set_state(State.CHASE)

	# Execute non-attack movement
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			anim.play("idle")

		State.CHASE:
			_chase_player()

		State.MELEE_ATTACK:
			velocity = Vector2.ZERO

		State.FIREBALL_ATTACK:
			velocity = Vector2.ZERO

		State.DEAD:
			velocity = Vector2.ZERO

	move_and_slide()


func _set_state(new_state: State) -> void:
	if state == new_state:
		return

	state = new_state

	match state:
		State.IDLE:
			anim.play("idle")

		State.CHASE:
			# animation handled in _chase_player()
			pass

		State.MELEE_ATTACK:
			if not attack_in_progress:
				_start_melee_attack()

		State.FIREBALL_ATTACK:
			if not attack_in_progress:
				_start_fireball_attack()

		State.DEAD:
			anim.play("idle")


func _chase_player() -> void:
	if player == null:
		velocity = Vector2.ZERO
		anim.play("idle")
		return

	var dir := (player.global_position - global_position).normalized()
	velocity = dir * (speed_phase2 if phase == 2 else speed_phase1)

	_update_facing(dir)
	_play_movement_animation(dir)


func _start_melee_attack() -> void:
	attack_in_progress = true
	velocity = Vector2.ZERO
	move_and_slide()

	_play_attack_animation()

	await get_tree().create_timer(melee_windup_time).timeout

	if dead:
		return

	# Damage anything inside the attack area, but only player matters here
	if player != null:
		var dist := global_position.distance_to(player.global_position)
		if dist <= melee_range + 8.0:
			if player.has_method("take_damage"):
				player.take_damage(melee_damage)

	await get_tree().create_timer(melee_recover_time).timeout

	attack_in_progress = false

	if not dead:
		_set_state(State.CHASE)


func _start_fireball_attack() -> void:
	print("FIREBALL!")
	attack_in_progress = true
	can_fireball = false
	velocity = Vector2.ZERO
	move_and_slide()

	_play_shoot_animation()

	await get_tree().create_timer(fireball_windup_time).timeout

	if dead:
		return

	if fireball_scene != null and player != null:
		var fireball = fireball_scene.instantiate()
		get_tree().current_scene.add_child(fireball)

		fireball.global_position = global_position

		if fireball.has_method("setup"):
			fireball.setup((player.global_position - global_position).normalized(), fireball_damage)
		else:
			# Fallback if your fireball script uses direct variables
			fireball.direction = (player.global_position - global_position).normalized()
			fireball.damage = fireball_damage

	await get_tree().create_timer(fireball_recover_time).timeout

	attack_in_progress = false
	can_fireball = true

	if not dead:
		_set_state(State.CHASE)


func take_damage(amount: int) -> void:
	if dead:
		return

	hp -= amount

	if hp <= 0:
		die()
	elif phase == 1 and hp <= max_hp / 2:
		phase = 2


func die() -> void:
	if dead:
		return

	dead = true
	state = State.DEAD
	velocity = Vector2.ZERO
	emit_signal("died")
	queue_free()


func _on_detection_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player = body


func _on_detection_body_exited(body: Node) -> void:
	if body == player:
		player = null


func _update_facing(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		facing = Vector2.RIGHT if dir.x >= 0 else Vector2.LEFT
	elif dir.y < 0:
		facing = Vector2.UP
	else:
		facing = Vector2.DOWN


func _play_movement_animation(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		anim.flip_h = dir.x < 0
		anim.play("walk_right")
	elif dir.y < 0:
		anim.flip_h = false
		anim.play("walk_up")
	else:
		anim.flip_h = false
		anim.play("walk_down")


func _play_attack_animation() -> void:
	match facing:
		Vector2.UP:
			anim.flip_h = false
			anim.play("attack_up")
		Vector2.DOWN:
			anim.flip_h = false
			anim.play("attack_down")
		Vector2.LEFT, Vector2.RIGHT:
			anim.flip_h = facing == Vector2.LEFT
			anim.play("attack_right")


func _play_shoot_animation() -> void:
	match facing:
		Vector2.UP:
			anim.flip_h = false
			anim.play("shoot_up")
		Vector2.DOWN:
			anim.flip_h = false
			anim.play("shoot_down")
		Vector2.LEFT, Vector2.RIGHT:
			anim.flip_h = facing == Vector2.LEFT
			anim.play("shoot_right")


func _on_attack_area_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_attack_area_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
