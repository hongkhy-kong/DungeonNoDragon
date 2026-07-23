extends CanvasLayer

@export var hp_price := 50
@export var buff_price := 100

@onready var coin_label = $Control/CoinLabel

@onready var hp_button = $Control/HPPotion
@onready var buff_button = $Control/BuffPotion

@onready var close_button = $Control/Close
@onready var click_sound: AudioStreamPlayer = $Control/Playsound/AudioStreamPlayer2D
@onready var play_sound_button = $Control/Playsound

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	hide()
	update_ui()
	
	play_sound_button.pressed.connect(_on_play_sound_pressed)
	hp_button.pressed.connect(_buy_hp_potion)
	buff_button.pressed.connect(_buy_buff_potion)
	close_button.pressed.connect(close_shop)

func open_shop():
	update_ui()
	visible = true
	get_tree().paused = true

func close_shop():
	visible = false
	get_tree().paused = false

func update_ui():
	coin_label.text = "Coins : %d" % Inventory.coins

func _buy_hp_potion():
	if Inventory.coins < hp_price:
		print("Not enough coins!")
		return

	Inventory.coins -= hp_price
	Inventory.hp_potions += 1

	print("Bought HP Potion")
	update_ui()

func _buy_buff_potion():
	if Inventory.coins < buff_price:
		print("Not enough coins!")
		return

	Inventory.coins -= buff_price
	Inventory.buff_potions += 1

	print("Bought Buff Potion")
	update_ui()

func _on_play_sound_pressed():
	click_sound.play()
