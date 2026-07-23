extends CharacterBody2D

signal died

enum State {
	IDLE,
	CHASE,
	MELEE_ATTACK,
	FIREBALL_ATTACK,
	DEAD
}

@export var max_hp: int = 1000

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

@onready var melee_sound: AudioStreamPlayer2D = $melee_attack
@onready var range_sound1: AudioStreamPlayer2D = $range_attack1
@onready var range_sound2: AudioStreamPlayer2D = $range_attack2
@onready var death_sound: AudioStreamPlayer2D = $die

@export var melee_cooldown_phase1 := 2.0
@export var melee_cooldown_phase2 := 1.0

@export var fireball_cooldown := 3.0

var boss_ui

var hp: int
var player: Node2D = null
var state: State = State.IDLE
var phase: int = 1

var attack_in_progress: bool = false
var can_fireball: bool = true
var dead: bool = false
var facing: Vector2 = Vector2.DOWN

var phase2_started: bool = false
var phase2_transitioning: bool = false

var can_melee := true

func set_boss_ui(ui):
	boss_ui = ui
	boss_ui.setup("Red Giant Lizard", max_hp)


func _ready() -> void:
	hp = max_hp

	if not detection_area.body_entered.is_connected(Callable(self, "_on_detection_body_entered")):
		detection_area.body_entered.connect(Callable(self, "_on_detection_body_entered"))

	if not detection_area.body_exited.is_connected(Callable(self, "_on_detection_body_exited")):
		detection_area.body_exited.connect(Callable(self, "_on_detection_body_exited"))

	anim.play("idle")

	if boss_ui:
		boss_ui.update_hp(hp)


func _physics_process(delta: float) -> void:
	if dead:
		return

	if phase2_transitioning:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if hp <= 0:
		die()
		return

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

	if phase == 1 and hp <= 500 and not phase2_started:
		start_phase2()
		return

	if distance <= melee_range:
		_set_state(State.MELEE_ATTACK)
	elif phase == 2 and can_fireball and distance <= fireball_range:
		_set_state(State.FIREBALL_ATTACK)
	else:
		_set_state(State.CHASE)

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
	var cooldown = melee_cooldown_phase1
	attack_in_progress = false
	can_melee = false

	if phase == 2:
		cooldown = melee_cooldown_phase2

	await get_tree().create_timer(cooldown).timeout
	can_melee = true
	
	velocity = Vector2.ZERO
	move_and_slide()

	_play_attack_animation()

	await get_tree().create_timer(melee_windup_time).timeout

	if dead:
		return

	if melee_sound and melee_sound.stream:
		melee_sound.play()

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
	attack_in_progress = false

	await get_tree().create_timer(fireball_cooldown).timeout
	can_fireball = true
	velocity = Vector2.ZERO
	move_and_slide()
	if player != null:
		var dir = (player.global_position - global_position).normalized()
		_update_facing(dir)
	_play_shoot_animation()

	await get_tree().create_timer(fireball_windup_time).timeout

	if dead:
		return

	if range_sound1.stream:
		range_sound1.play()

	await get_tree().create_timer(0.50).timeout

	if fireball_scene != null and player != null:
		var fireball = fireball_scene.instantiate()
		get_tree().current_scene.add_child(fireball)

		fireball.global_position = global_position

		var dir = (player.global_position - global_position).normalized()

		if fireball.has_method("setup"):
			fireball.setup(dir, fireball_damage)
		else:
			fireball.direction = dir
			fireball.damage = fireball_damage

	if range_sound2.stream:
		range_sound2.play()

	await get_tree().create_timer(fireball_recover_time).timeout

	attack_in_progress = false
	can_fireball = true

	if not dead:
		_set_state(State.CHASE)


func start_phase2() -> void:
	if phase2_started or dead:
		return

	phase2_started = true
	phase2_transitioning = true
	attack_in_progress = true
	velocity = Vector2.ZERO
	move_and_slide()

	anim.play("idle")
	print("PHASE 2 START!")

	await get_tree().create_timer(2.0).timeout

	if dead:
		return

	phase = 2
	speed_phase2 = max(speed_phase2, speed_phase1 + 20.0)

	phase2_transitioning = false
	attack_in_progress = false

	if boss_ui:
		boss_ui.update_hp(hp)


func take_damage(amount: int) -> void:
	if dead or phase2_transitioning:
		return

	hp -= amount

	if hp < 0:
		hp = 0

	if boss_ui:
		boss_ui.update_hp(hp)

	if hp <= 500 and phase == 1 and not phase2_started:
		start_phase2()
		return

	if hp <= 0 and phase == 2:
		die()


func die() -> void:
	if dead:
		return

	dead = true
	state = State.DEAD
	velocity = Vector2.ZERO

	if death_sound and death_sound.stream:
		death_sound.play()

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
	pass


func _on_attack_area_body_exited(body: Node2D) -> void:
	pass
