extends Area2D

@export var hub_scene := "res://Scence/Map/Spawn/hub.tscn"

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		await get_tree().process_frame
		get_tree().change_scene_to_file(hub_scene)
