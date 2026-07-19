extends CanvasLayer

@onready var boss_name: Label = $BossLayer/Label
@onready var hp_bar: ProgressBar = $BossLayer/ProgressBar

func _ready():
	hide()   # Hide when the level starts
func setup(name: String, max_hp: int):
	boss_name.text = name
	hp_bar.max_value = max_hp
	hp_bar.value = max_hp
	show()


func update_hp(current_hp: int):
	hp_bar.value = current_hp


func hide_bar():
	hide()


func show_bar():
	show()
