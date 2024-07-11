extends CanvasLayer

class_name GUI

signal reset_game_signal

@onready var score_label = %Score
@onready var time_label =%Time
@onready var retry_button = %RetryButton


func _ready():
	retry_button.connect("pressed", Callable(self, "_on_retry_button_pressed"))

func set_mine_score(score: int):
	var mine_score_string = str(score)
	if mine_score_string.length() < 3:
		mine_score_string = mine_score_string.lpad(3, "0")
	
	score_label.text = mine_score_string
	
func set_timer(time: int):
	var mine_time_string = str(time)
	if mine_time_string.length() < 3:
		mine_time_string = mine_time_string.lpad(3, "0")
	
	time_label.text = mine_time_string

func reset_game():
	emit_signal("reset_game_signal")

func _on_retry_button_pressed():
	reset_game()
