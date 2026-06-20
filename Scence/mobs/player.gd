extends CharacterBody2D

@export var speed := 120.0
@export var max_health := 100000
@export var damage := 2500

var health := max_health

enum State {
	ALIVE,
	DEAD
}

var current_state = State.ALIVE

@onready var sprite = $AnimatedSprite2D

var is_attacking = false
var facing_direction = Vector2.DOWN
var facing_name = "down"


func _physics_process(_delta):

	if current_state == State.DEAD:
		return

	if is_attacking:
		move_and_slide()
		return

	var input_dir = Vector2.ZERO

	input_dir.x = Input.get_axis("ui_left", "ui_right")
	input_dir.y = Input.get_axis("ui_up", "ui_down")

	input_dir = input_dir.normalized()

	if input_dir != Vector2.ZERO:
		facing_direction = input_dir

	velocity = input_dir * speed

	if Input.is_action_just_pressed("attack"):
		attack()
	else:
		update_animation(input_dir)

	move_and_slide()


func update_animation(direction):

	if direction == Vector2.ZERO:

		if abs(facing_direction.x) > abs(facing_direction.y):

			if facing_direction.x > 0:
				facing_name = "right"
				sprite.flip_h = false
				sprite.play("idle_right")
			else:
				facing_name = "left"
				sprite.flip_h = true
				sprite.play("idle_right")

		else:

			sprite.flip_h = false

			if facing_direction.y > 0:
				facing_name = "down"
				sprite.play("idle_down")
			else:
				facing_name = "up"
				sprite.play("idle_up")

		return

	# WALKING
	if abs(direction.x) > abs(direction.y):

		if direction.x > 0:
			facing_name = "right"
			sprite.flip_h = false
			sprite.play("walk_right")
		else:
			facing_name = "left"
			sprite.flip_h = true
			sprite.play("walk_right")

	else:

		sprite.flip_h = false

		if direction.y > 0:
			facing_name = "down"
			sprite.play("walk_down")
		else:
			facing_name = "up"
			sprite.play("walk_up")


func update_attack_area():

	match facing_name:

		"right":
			$AttackArea.position = Vector2(10, 0)

		"left":
			$AttackArea.position = Vector2(-10, 0)

		"up":
			$AttackArea.position = Vector2(0, -10)

		"down":
			$AttackArea.position = Vector2(0, 10)


func attack():

	print("Facing:", facing_name)
	print("AttackArea:", $AttackArea.position)
	update_attack_area()

	$AttackArea.monitoring = true

	is_attacking = true
	velocity = Vector2.ZERO

	if abs(facing_direction.x) > abs(facing_direction.y):

		if facing_direction.x > 0:
			sprite.flip_h = false
			sprite.play("attack_right")
		else:
			sprite.flip_h = true
			sprite.play("attack_right")

	else:

		sprite.flip_h = false

		if facing_direction.y > 0:
			sprite.play("attack_down")
		else:
			sprite.play("attack_up")


func _on_attack_area_body_entered(body):

	if not is_attacking:
		return

	print("Hit:", body.name)

	if body.has_method("take_damage"):
		body.take_damage(damage)
		print("Damage sent")


func _on_animated_sprite_2d_animation_finished():

	$AttackArea.monitoring = false

	if sprite.animation.begins_with("attack"):
		is_attacking = false


func take_damage(amount):

	if current_state == State.DEAD:
		return

	health -= amount

	print("Player HP:", health)

	if health <= 0:
		die()


func die():

	if current_state == State.DEAD:
		return

	current_state = State.DEAD

	print("PLAYER DIED")

	queue_free()
