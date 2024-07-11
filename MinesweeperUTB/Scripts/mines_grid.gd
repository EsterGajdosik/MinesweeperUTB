extends TileMap

class_name MinesGrid

signal flag_changed(number_of_flags)
signal game_lost
signal game_won

const  TILE_ATLAS = {
	"1": Vector2i(0,0),
	"2": Vector2i(1,0),
	"3": Vector2i(2,0),
	"4": Vector2i(3,0),
	"5": Vector2i(4,0),
	"6": Vector2i(0,1),
	"7": Vector2i(1,1),
	"8": Vector2i(2,1),
	"EMPTY": Vector2i(3,1),
	"EXPLODED": Vector2i(4,1),
	"FLAG": Vector2i(0,2),
	"MINE": Vector2i(1,2),
	"DEFAULT": Vector2i(2,2)
}

@export var columns = 16
@export var rows = 16
@export var number_of_mines = 25

const  TILE_SET_ID = 0
const  DEFAULT_LAYER = 0

var cells_with_mines = []
var cells_with_flags = []
var checked_cells = []
var game_finished = false
var placed_flags = 0 

func _ready():
	clear_layer(DEFAULT_LAYER)
	reset_grid()

func reset_grid():
	clear_layer(DEFAULT_LAYER)
	game_finished = false
	cells_with_mines.clear()
	cells_with_flags.clear()
	checked_cells.clear()
	placed_flags = 0
	
	for row in range(rows):
		for column in range(columns):
			var cell_coordinates = Vector2(row - rows / 2, column - columns / 2)
			set_tile_cell(cell_coordinates, "DEFAULT")
	place_mines()		

func _input(event: InputEvent):
	if game_finished:
		return
		
	if !(event is InputEventMouseButton) || !event.pressed:
		return
	var clicked_cell_coord = local_to_map(get_local_mouse_position())
	
	if event.button_index == 1:
		on_cell_clicked(clicked_cell_coord)
	elif event.button_index == 2:
		place_flag(clicked_cell_coord)

func set_tile_cell(cell_coordinates, cell_type):
	set_cell(DEFAULT_LAYER, cell_coordinates, TILE_SET_ID, TILE_ATLAS[cell_type])

func place_mines():
	for mine in number_of_mines:
		var random_cell_coordinates = Vector2(randi_range(-rows/2, rows/2 -1), randi_range(-columns/2, columns/2 -1))
	
		while cells_with_mines.has(random_cell_coordinates):
			random_cell_coordinates = Vector2(randi_range(-rows/2, rows/2 -1), randi_range(-columns/2, columns/2 -1))
		
		cells_with_mines.append(random_cell_coordinates)
		
	for cell in cells_with_mines:
		erase_cell(DEFAULT_LAYER, cell)
		set_cell(DEFAULT_LAYER, cell, TILE_SET_ID, TILE_ATLAS.DEFAULT, 1)

func on_cell_clicked(cell_coord: Vector2i):
	if cells_with_mines.any(func (cell): return cell.x == cell_coord.x && cell.y == cell_coord.y):
		lose(cell_coord)
		return
	
	checked_cells.append(cell_coord)
	handle_cells(cell_coord, true)
	
	if cells_with_flags.has(cell_coord):
		placed_flags -=1
		flag_changed.emit(placed_flags)
		cells_with_flags.erase(cell_coord)

func handle_cells(cell_coord: Vector2i, stops_after_mine: bool = false):
	var tile_data = get_cell_tile_data(DEFAULT_LAYER, cell_coord)
	
	if tile_data == null:
		return
		
	var cell_has_mine = tile_data.get_custom_data("has_mine")
	
	if cell_has_mine && stops_after_mine:
		print("HITTED MINE")
		return
	
	var count_mine = get_surrounding_cells_mine_count(cell_coord)
	
	if count_mine == 0:
		set_tile_cell(cell_coord, "EMPTY")
		var surrounding_cells = get_surrounding_cells(cell_coord)
		for cell in surrounding_cells:
			handle_surrounding_cell(cell)
	else:
		set_tile_cell(cell_coord, "%d" % count_mine)

	if cells_with_flags.has(cell_coord):
		placed_flags -=1
		flag_changed.emit(placed_flags)
		cells_with_flags.erase(cell_coord)

func get_surrounding_cells_mine_count(cell_coord: Vector2i):
	var count_mine = 0
	var surrounding_cells = get_surrounding_cells(cell_coord)
	
	for cell in surrounding_cells:
		var tile_data = get_cell_tile_data(DEFAULT_LAYER, cell)
		if tile_data and tile_data.get_custom_data("has_mine"):
			count_mine += 1
	return count_mine

func handle_surrounding_cell(cell_coord: Vector2i):
	if checked_cells.has(cell_coord):
		return
	
	checked_cells.append(cell_coord)
	handle_cells(cell_coord)

func lose(cell_coord: Vector2i):
	game_lost.emit()
	game_finished = true
	
	for cell in cells_with_mines:
		set_tile_cell(cell, "MINE")
	
	set_tile_cell(cell_coord, "EXPLODED")

func place_flag(cell_coord: Vector2i):
	var tile_data = get_cell_tile_data(DEFAULT_LAYER, cell_coord)
	var atlast_coordinates = get_cell_atlas_coords(DEFAULT_LAYER, cell_coord)
	var is_empty_cell = atlast_coordinates == Vector2i(2,2)
	var is_flag_cell = atlast_coordinates == Vector2i(0,2)
	
	if !is_empty_cell and !is_flag_cell:
		return
	
	if is_flag_cell:
		set_tile_cell(cell_coord, "DEFAULT")
		cells_with_flags.erase(cell_coord)
		placed_flags -=1
	elif is_empty_cell:
		if placed_flags == number_of_mines:
			return
		placed_flags +=1
		set_tile_cell(cell_coord, "FLAG")
		cells_with_flags.append(cell_coord)
	
	flag_changed.emit(placed_flags)
		
	var count = 0
	for flag_cell in cells_with_flags:
		for mine_cell in cells_with_mines:
			if flag_cell.x == mine_cell.x and flag_cell.y == mine_cell.y:
				count +=1
	
	if count == cells_with_mines.size():
		win()

func win():
	game_finished = true
	game_won.emit()
