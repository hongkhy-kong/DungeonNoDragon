extends Area2D

@export var min_coin := 20
@export var max_coin := 100

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		var coin_amount = randi_range(min_coin, max_coin)

		Inventory.add_coins(coin_amount)

		print("Picked up ", coin_amount, " coins!")

		queue_free()
