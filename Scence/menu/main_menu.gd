extends Control

func _ready():
	$VBoxContainer/Start.grab_focus()

func _on_start_pressed():
	get_tree().change_scene_to_file("res://Scence/Map/hub.tscn")

func _on_setting_pressed():
	# TODO: Open the settings menu res://Scence/setting.tscn
	get_tree().change_scene_to_file("res://Scence/setting/setting.tscn")
	print("Settings button pressed")

func _on_exit_pressed():
	get_tree().quit()
