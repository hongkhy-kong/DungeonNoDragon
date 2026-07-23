extends Area2D

@export var shop_ui: CanvasLayer
@onready var prompt = $Label
var player_in_range := false

func _ready():
	prompt.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		print("press E")
		if shop_ui:
			shop_ui.open_shop()

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		prompt.show()
		print("player_in_range")
func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		prompt.hide()
