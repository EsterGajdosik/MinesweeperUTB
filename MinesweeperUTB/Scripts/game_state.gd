extends Node

@export var mines_grid: MinesGrid
@export var gui: GUI
@onready var timer = $Timer

var time_elapsed = 0

func _ready():
	mines_grid.game_lost.connect(on_game_lost)
	mines_grid.game_won.connect(on_game_won)
	mines_grid.flag_changed.connect(on_flag_changed)
	gui.connect("reset_game_signal", Callable(self, "_on_reset_game"))
	gui.set_mine_score(mines_grid.number_of_mines)
	
func _on_timer_timeout():
	time_elapsed += 1
	gui.set_timer(time_elapsed)
	
func on_game_lost():
	timer.stop()
	
func on_game_won():
	timer.stop()
	
func on_flag_changed(number_of_flags: int):
	gui.set_mine_score(mines_grid.number_of_mines - number_of_flags)

func _on_reset_game():
	time_elapsed = 0
	timer.start()
	gui.set_timer(time_elapsed)
	mines_grid.reset_grid()
	gui.set_mine_score(mines_grid.number_of_mines)
