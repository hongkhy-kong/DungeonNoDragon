extends CharacterBody2D

signal died

enum State {
	IDLE,
	CHASE,
	ATTACK,
	DEAD
}

@export var speed: float = 25.0
@export var max_hp: int = 50
@export var attack_cooldown: float = 3.0
@export var projectile_scene: PackedScene

# Extra check so the enemy attacks only when the player is really in front
@export var attack_range: float = 120.0
@export var attack_front_angle_deg: float = 70.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

@onready var detection_shape: CollisionShape2D = $Detection/CollisionShape2D
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var body_shape: CollisionShape2D = $CollisionShape2D

@onready var attack_timer: Timer = $AttackTimer
@onready var shoot_point: Marker2D = $ShootPoint

@onready var attack_sound: AudioStreamPlayer2D = $attacksound
@onready var idle_sound: AudioStreamPlayer2D = $idlesound
@onready var death_sound: AudioStreamPlayer2D = $deathsound

var hp: int
var current_state = State.IDLE

var player: Node2D = null
var player_in_attack_area := false
var facing_dir := Vector2.RIGHT
var is_attacking := false


func _ready():
	hp = max_hp
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	play_idle()


func _physics_process(delta):
	if current_state == State.DEAD:
		return

	match current_state:
		State.IDLE:
			idle_state()
		State.CHASE:
			chase_state()
		State.ATTACK:
			attack_state()

	move_and_slide()


# ========================================================
# STATES
# ========================================================

func idle_state():
	velocity = Vector2.ZERO
	play_idle()

	if player != null and is_instance_valid(player):
		current_state = State.CHASE


func chase_state():
	if player == null or !is_instance_valid(player):
		current_state = State.IDLE
		return

	var dir = player.global_position - global_position
	if dir.length() == 0.0:
		return

	facing_dir = dir.normalized()

	# If player is close and in front, go attack
	if player_in_attack_area and can_attack_player():
		velocity = Vector2.ZERO
		current_state = State.ATTACK
		return

	velocity = facing_dir * speed

	if anim.animation != "walk":
		anim.play("walk")
	anim.flip_h = facing_dir.x < 0


func attack_state():
	if player == null or !is_instance_valid(player):
		current_state = State.IDLE
		is_attacking = false
		return

	velocity = Vector2.ZERO

	# If player leaves the attack area or moves behind the boss, stop attacking
	if !player_in_attack_area or !can_attack_player():
		is_attacking = false
		current_state = State.CHASE
		return

	face_player()

	# Play attack animation only once per attack
	if !is_attacking:
		is_attacking = true
		if anim.animation != "attack":
			anim.play("attack")

		shoot()
		attack_timer.start()


# ========================================================
# ATTACK HELPERS
# ========================================================

func can_attack_player() -> bool:
	if player == null or !is_instance_valid(player):
		return false

	var to_player = player.global_position - global_position
	var dist = to_player.length()

	if dist > attack_range:
		return false

	if dist == 0.0:
		return true

	var forward = facing_dir.normalized()
	if forward == Vector2.ZERO:
		forward = Vector2.RIGHT

	var direction_to_player = to_player.normalized()
	var dot_value = forward.dot(direction_to_player)
	var limit = cos(deg_to_rad(attack_front_angle_deg))

	return dot_value >= limit


func face_player():
	if player == null or !is_instance_valid(player):
		return

	var dir = player.global_position - global_position
	if dir.length() > 0.0:
		facing_dir = dir.normalized()

	anim.flip_h = facing_dir.x < 0


# ========================================================
# SHOOT
# ========================================================

func shoot():
	if projectile_scene == null or player == null:
		return

	var projectile = projectile_scene.instantiate()

	var dir = (player.global_position - shoot_point.global_position).normalized()

	projectile.direction = dir
	projectile.global_position = shoot_point.global_position + dir * 20
	projectile.shooter = self

	get_tree().current_scene.add_child(projectile)

	if attack_sound.stream:
		attack_sound.play()

	# Start the cooldown AFTER shooting
	attack_timer.start()


# ========================================================
# DETECTION
# ========================================================

func _on_detection_body_entered(body):
	if body.is_in_group("player"):
		player = body
		current_state = State.CHASE


func _on_detection_body_exited(body):
	if body == player:
		player = null
		player_in_attack_area = false
		is_attacking = false
		current_state = State.IDLE


func _on_attack_area_body_entered(body):
	if body.is_in_group("player"):
		player_in_attack_area = true
		if current_state == State.IDLE:
			current_state = State.CHASE


func _on_attack_area_body_exited(body):
	if body.is_in_group("player"):
		player_in_attack_area = false
		is_attacking = false
		current_state = State.CHASE


# ========================================================
# TIMER
# ========================================================

func _on_attack_timer_timeout():
	if current_state == State.ATTACK and player != null and is_instance_valid(player):
		is_attacking = false
		if player_in_attack_area and can_attack_player():
			# Start the next attack only when the cooldown ends
			is_attacking = true
			if anim.animation != "attack":
				anim.play("attack")
			shoot()
			attack_timer.start()


# ========================================================
# DAMAGE
# ========================================================

func take_damage(amount: int):
	if current_state == State.DEAD:
		return

	hp -= amount

	if hp <= 0:
		die()


func die():

	if current_state == State.DEAD:
		return

	current_state = State.DEAD
	velocity = Vector2.ZERO

	emit_signal("died")

	body_shape.set_deferred("disabled", true)
	detection_shape.set_deferred("disabled", true)
	attack_shape.set_deferred("disabled", true)

	if death_sound.stream:
		death_sound.play()

	anim.stop()

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)

	await tween.finished

	queue_free()


# ========================================================
# SOUND
# ========================================================

func _on_groan_timer_timeout():
	if current_state == State.DEAD:
		return

	idle_sound.pitch_scale = randf_range(0.9, 1.1)
	idle_sound.play()


# ========================================================
# ANIMATION
# ========================================================

func play_idle():
	if current_state == State.DEAD:
		return

	if anim.animation != "idle_left_right":
		anim.play("idle_left_right")

	anim.flip_h = facing_dir.x < 0
