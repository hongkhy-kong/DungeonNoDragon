extends CanvasLayer

# ======================================================
# PAUSE MENU
# ======================================================

@onready var pause_panel = $PausePanel

@onready var resume_button = $PausePanel/VBoxContainer/ResumeButton
@onready var restart_button = $PausePanel/VBoxContainer/RestartButton
@onready var hub_button = $PausePanel/VBoxContainer/HubButton

# ======================================================
# GAME OVER
# ======================================================

@onready var game_over_panel = $GameOverPanel

@onready var gameover_restart = $GameOverPanel/VBoxContainer/RestartButton
@onready var gameover_hub = $GameOverPanel/VBoxContainer/HubButton


func _ready():

	pause_panel.visible = false
	game_over_panel.visible = false


func _input(event):

	if event.is_action_pressed("ui_cancel"):

		if game_over_panel.visible:
			return

		if get_tree().paused:
			resume_game()
		else:
			pause_game()


func pause_game():

	get_tree().paused = true
	pause_panel.visible = true


func resume_game():

	get_tree().paused = false
	pause_panel.visible = false


func show_game_over():

	get_tree().paused = true
	game_over_panel.visible = true


# ======================================================
# BUTTONS
# ======================================================

func _on_resume_button_pressed():

	resume_game()


func _on_restart_button_pressed():

	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_hub_button_pressed():

	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scence/Map/hub.tscn")


func _on_game_over_restart_button_pressed():

	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_game_over_hub_button_pressed():

	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scence/Map/hub.tscn")
