extends CharacterBody2D

signal died

enum State {
	ALIVE,
	DEAD
}

@export var speed: float = 10.0
@export var max_hp: int = 50
@export var damage: int = 10000000
@export var attack_range: float = 24.0

var current_state = State.ALIVE
var hp: int

var player: Node2D = null
var is_chasing := false
var can_attack := true
var facing := "down"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer


func _ready():
	hp = max_hp


# ==================================================
# Detection
# ==================================================

func _on_detection_body_entered(body):
	if body.is_in_group("player"):
		player = body
		is_chasing = true


func _on_detection_body_exited(body):
	if body == player:
		player = null
		is_chasing = false
		velocity = Vector2.ZERO


# ==================================================
# Movement
# ==================================================

func _physics_process(_delta):

	if current_state == State.DEAD:
		return

	if player == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var distance = global_position.distance_to(player.global_position)

	if distance > attack_range:

		var direction = (player.global_position - global_position).normalized()

		velocity = direction * speed

		update_facing(direction)
		play_walk_animation()

	else:

		velocity = Vector2.ZERO

		if can_attack:
			attack()

	move_and_slide()


func update_facing(direction: Vector2):

	if abs(direction.x) > abs(direction.y):
		facing = "right" if direction.x > 0 else "left"
	else:
		facing = "down" if direction.y > 0 else "up"


# ==================================================
# Animations
# ==================================================

func play_walk_animation():

	match facing:
		"right":
			sprite.flip_h = false
			sprite.play("walk_right")

		"left":
			sprite.flip_h = true
			sprite.play("walk_right")

		"up":
			sprite.flip_h = false
			sprite.play("walk_up")

		_:
			sprite.flip_h = false
			sprite.play("walk_down")


func play_attack_animation():

	match facing:
		"right":
			sprite.flip_h = false
			sprite.play("atk_right")

		"left":
			sprite.flip_h = true
			sprite.play("atk_right")

		"up":
			sprite.flip_h = false
			sprite.play("atk_up")

		_:
			sprite.flip_h = false
			sprite.play("atk_down")


func _on_animated_sprite_2d_animation_finished():

	if current_state == State.DEAD:
		return

	if sprite.animation.begins_with("atk") and is_chasing:
		play_walk_animation()


# ==================================================
# Attack
# ==================================================

func attack():

	can_attack = false

	play_attack_animation()

	if player != null and player.has_method("take_damage"):
		player.take_damage(damage)
		print("Enemy attacked player")

	timer.start()


func _on_timer_timeout():

	can_attack = true

	if player == null:
		return

	if global_position.distance_to(player.global_position) <= attack_range:
		attack()


# ==================================================
# Damage
# ==================================================

func take_damage(amount: int):

	hp -= amount
	print("Enemy HP:", hp)

	if hp <= 0:
		die()


func die():

	if current_state == State.DEAD:
		return

	current_state = State.DEAD

	emit_signal("died")

	set_physics_process(false)

	velocity = Vector2.ZERO

	$CollisionShape2D.disabled = true
	$Detection/CollisionShape2D.disabled = true

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)

	await tween.finished

	queue_free()
