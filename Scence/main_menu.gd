extends Control

func _ready():
	$VBoxContainer/Start.grab_focus()

func _on_start_pressed():
	get_tree().change_scene_to_file("res://Map/level_cave.tscn")

func _on_setting_pressed():
	# TODO: Open the settings menu res://Scence/setting.tscn
	get_tree().change_scene_to_file("res://Scence/setting.tscn")
	print("Settings button pressed")

func _on_exit_pressed():
	get_tree().quit()


func _on_hub_pressed():

	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
