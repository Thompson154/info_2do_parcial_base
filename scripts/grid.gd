extends Node2D

# state machine
enum {WAIT, MOVE}

var state

# grid
@export var width: int
@export var height: int
@export var x_start: int
@export var y_start: int
@export var offset: int
@export var y_offset: int

# piece array
var possible_pieces = [
	preload("res://scenes/blue_piece.tscn"),
	preload("res://scenes/green_piece.tscn"),
	preload("res://scenes/light_green_piece.tscn"),
	preload("res://scenes/pink_piece.tscn"),
	preload("res://scenes/yellow_piece.tscn"),
	preload("res://scenes/orange_piece.tscn"),
]

# consts
const BLUE = "blue"
const GREEN = "green"
const LIGHT_GREEN = "light_green"
const PINK = "pink"
const YELLOW = "yellow"
const ORANGE = "orange"

# special pieces
const col =  "column"
const row =  "row"
const adj = "adjacent"
const nor = "normal"
const rnbw = "rainbow"

var rainbow_piece = preload("res://scenes/rainbow_piece.tscn")

var rows = {
	BLUE: preload("res://scenes/blue_row.tscn"),
	GREEN: preload("res://scenes/green_row.tscn"),
	LIGHT_GREEN: preload("res://scenes/light_green_row.tscn"),
	ORANGE: preload("res://scenes/orange_row.tscn"),
	PINK: preload("res://scenes/pink_row.tscn"),
	YELLOW: preload("res://scenes/yellow_row.tscn")
}

var cols = {
	BLUE: preload("res://scenes/blue_col.tscn"),
	GREEN: preload("res://scenes/green_col.tscn"),
	LIGHT_GREEN: preload("res://scenes/light_green_col.tscn"),
	ORANGE: preload("res://scenes/orange_col.tscn"),
	PINK: preload("res://scenes/pink_col.tscn"),
	YELLOW: preload("res://scenes/yellow_col.tscn")
}

var adjs = {
	BLUE: preload("res://scenes/blue_big.tscn"),
	GREEN: preload("res://scenes/green_big.tscn"),
	LIGHT_GREEN: preload("res://scenes/light_green_big.tscn"),
	ORANGE: preload("res://scenes/orange_big.tscn"),
	PINK: preload("res://scenes/pink_big.tscn"),
	YELLOW: preload("res://scenes/yellow_big.tscn")
}

var all_pieces = []

var piece_one = null
var piece_two = null
var last_place = Vector2.ZERO
var last_direction = Vector2.ZERO
var move_checked = false

var first_touch = Vector2.ZERO
var final_touch = Vector2.ZERO
var is_controlling = false

signal score_updated(points)

signal move_counter()
var moves = 30
var deduct_move = false

func _ready():
	state = MOVE
	randomize()
	all_pieces = make_2d_array()
	spawn_pieces()

func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array

func grid_to_pixel(column, row):
	var new_x = x_start + offset * column
	var new_y = y_start - offset * row
	return Vector2(new_x, new_y)

func pixel_to_grid(pixel_x, pixel_y):
	var new_x = round((pixel_x - x_start) / offset)
	var new_y = round((pixel_y - y_start) / -offset)
	return Vector2(new_x, new_y)
	
func in_grid(column, row):
	return column >= 0 and column < width and row >= 0 and row < height

func spawn_pieces():
	for i in width:
		for j in height:
			var rand = randi_range(0, possible_pieces.size() - 1)
			var piece = possible_pieces[rand].instantiate()
			var max_loops = 100
			var loops = 0
			while (match_at(i, j, piece.color) and loops < max_loops):
				rand = randi_range(0, possible_pieces.size() - 1)
				loops += 1
				piece = possible_pieces[rand].instantiate()
			add_child(piece)
			piece.position = grid_to_pixel(i, j)
			all_pieces[i][j] = piece

func match_at(i, j, color):
	if i > 1:
		if all_pieces[i - 1][j] != null and all_pieces[i - 2][j] != null:
			if all_pieces[i - 1][j].color == color and all_pieces[i - 2][j].color == color:
				return true
	if j> 1:
		if all_pieces[i][j - 1] != null and all_pieces[i][j - 2] != null:
			if all_pieces[i][j - 1].color == color and all_pieces[i][j - 2].color == color:
				return true

func touch_input():
	var mouse_pos = get_global_mouse_position()
	var grid_pos = pixel_to_grid(mouse_pos.x, mouse_pos.y)
	if Input.is_action_just_pressed("ui_touch") and in_grid(grid_pos.x, grid_pos.y):
		first_touch = grid_pos
		is_controlling = true
		
	if Input.is_action_just_released("ui_touch") and in_grid(grid_pos.x, grid_pos.y) and is_controlling:
		is_controlling = false
		final_touch = grid_pos
		touch_difference(first_touch, final_touch)

func swap_pieces(column, row, direction: Vector2):
	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[column + direction.x][row + direction.y]
	
	
	if first_piece == null or other_piece == null:
		return
	var is_first_rainbow = first_piece.type == rnbw
	var is_other_rainbow =  other_piece.type == rnbw
	
	if is_first_rainbow:
		rainbow(column, row, other_piece.color)
		move_checked = true
	if is_other_rainbow:
		rainbow(column + direction.x, row + direction.y, first_piece.color)
		move_checked = true
		
	state = WAIT
	store_info(first_piece, other_piece, Vector2(column, row), direction)
	all_pieces[column][row] = other_piece
	all_pieces[column + direction.x][row + direction.y] = first_piece
	first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
	other_piece.move(grid_to_pixel(column, row))
	
	deduct_move = true
	if not move_checked:
		find_matches()

func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction

func swap_back():
	if piece_one != null and piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	state = MOVE
	move_checked = false

func touch_difference(grid_1, grid_2):
	var difference = grid_2 - grid_1
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(1, 0))
		elif difference.x < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(-1, 0))
	if abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, 1))
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, -1))

func _process(delta):
	if state == MOVE:
		touch_input()

func destroy_matched():
	var was_matched = false
	var number_matched = 0
	# i = col, j = row
	for i in width:
		for j in height:
			var current_piece = all_pieces[i][j]
			if current_piece != null and current_piece.matched:
				was_matched = true
				number_matched += 1
				if current_piece.type == row:
					row_match(j)
				elif current_piece.type == col:
					col_match(i)
				elif current_piece.type == adj:
					col_match(i)
					row_match(j)
					diag_match(i, j)
				elif current_piece.type == rnbw:
					rainbow(i, j, current_piece.color)
				elif current_piece.type == nor:
					all_pieces[i][j].queue_free()
					all_pieces[i][j] = null
				
	move_checked = true
	if was_matched:
		get_parent().get_node("collapse_timer").start()
		emit_signal("score_updated", number_matched * 10)        
		if deduct_move:
			emit_signal("move_counter")
			deduct_move = false
		if moves == 0:
			game_over()
	else:
		swap_back()

func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				print(i, j)
				for k in range(j + 1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i, j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	get_parent().get_node("refill_timer").start()

func refill_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				var rand = randi_range(0, possible_pieces.size() - 1)
				var piece = possible_pieces[rand].instantiate()
				var max_loops = 100
				var loops = 0
				while (match_at(i, j, piece.color) and loops < max_loops):
					rand = randi_range(0, possible_pieces.size() - 1)
					loops += 1
					piece = possible_pieces[rand].instantiate()
				add_child(piece)
				piece.position = grid_to_pixel(i, j - y_offset)
				piece.move(grid_to_pixel(i, j))
				all_pieces[i][j] = piece
				
	check_after_refill()

func check_after_refill():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and match_at(i, j, all_pieces[i][j].color):
				find_matches()
				get_parent().get_node("destroy_timer").start()
				return
	state = MOVE
	
	move_checked = false

func replace_with_special_piece(i, j, color, type):
	var special_piece
	if type == row:
		special_piece = rows[color].instantiate()
	elif type == col:
		special_piece = cols[color].instantiate()
	elif type == adj:
		special_piece = adjs[color].instantiate()
	elif type == rnbw:
		special_piece = rainbow_piece.instantiate()
	
	if type == row or type == col:
		for k in range(-1, 3):
			if type == row and in_grid(i + k, j):
				if all_pieces[i + k][j]:
					all_pieces[i + k][j].queue_free()
					all_pieces[i + k][j] = null
			elif type == col and in_grid(i, j + k):
				if all_pieces[i][j + k]:
					all_pieces[i][j + k].queue_free()
					all_pieces[i][j + k] = null
	elif type == adj or type == rnbw:
		for di in range(-1, 2):
			for dj in range(-1, 2):
				if in_grid(i + di, j + dj) and all_pieces[i + di][j + dj]:
					all_pieces[i + di][j + dj].queue_free()
					all_pieces[i + di][j + dj] = null
	
	if all_pieces[i][j]:
		all_pieces[i][j].queue_free()
	all_pieces[i][j] = special_piece
	all_pieces[i][j].type = type
	add_child(special_piece)
	special_piece.position = grid_to_pixel(i, j)
	get_parent().get_node("collapse_timer").start()

func remove_pieces(i, j, is_horizontal):
	if is_horizontal:
		for k in range(0, 3):
			if in_grid(i + k, j):
				all_pieces[i + k][j].matched = true
				all_pieces[i + k][j].dim()
	else:
		for k in range(0, 3):
			if in_grid(i, j + k):
				all_pieces[i][j + k].matched = true
				all_pieces[i][j + k].dim()

func row_match(row):
	for col in range(width):
		if all_pieces[col][row] != null:
			all_pieces[col][row].matched = true
			all_pieces[col][row].dim()
			all_pieces[col][row].queue_free()
			all_pieces[col][row] = null

func col_match(col):
	for row in range(height):
		if all_pieces[col][row] != null:
			all_pieces[col][row].matched = true
			all_pieces[col][row].dim()
			all_pieces[col][row].queue_free()
			all_pieces[col][row] = null

func diag_match(col, row):
	for offset in range(-min(width, height), min(width, height)):
		if (
			in_grid(col + offset, row + offset)
			and all_pieces[col + offset][row + offset] != null
		):
			all_pieces[col + offset][row + offset].matched = true
			all_pieces[col + offset][row + offset].dim()
			all_pieces[col + offset][row + offset].queue_free()
			all_pieces[col + offset][row + offset] = null

		if (
			in_grid(col + offset, row - offset) 
			and all_pieces[col + offset][row - offset] != null
		):
			all_pieces[col + offset][row - offset].matched = true
			all_pieces[col + offset][row - offset].dim()
			all_pieces[col + offset][row - offset].queue_free()
			all_pieces[col + offset][row - offset] = null

func rainbow(curr_col, curr_row, color):
	
	for col in range(width):
		for row in range(height):
			var curr_piece = all_pieces[col][row] 
			if curr_piece.color == color:
				all_pieces[col][row].matched = true
				all_pieces[col][row].dim()
				all_pieces[col][row].queue_free()
				all_pieces[col][row] = null
	all_pieces[curr_col][curr_row].matched = true
	all_pieces[curr_col][curr_row].dim()
	all_pieces[curr_col][curr_row].queue_free()
	all_pieces[curr_col][curr_row] = null
	get_parent().get_node("collapse_timer").start()

func find_matches():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color
				
				if matchType1(i, j) or matchType2(i, j):
					replace_with_special_piece(i, j, current_color, adj)
				if i <= width - 5:
					if is_match(i, j, Vector2(1, 0), 5):
						replace_with_special_piece(i + 2, j, current_color, rnbw)
						continue
					elif is_match(i, j, Vector2(1, 0), 4):
						replace_with_special_piece(i + 1, j, current_color, row)
						continue
				elif i <= width - 4:
					if is_match(i, j, Vector2(1, 0), 4):
						replace_with_special_piece(i + 1, j, current_color, row)
						continue
				
				if j <= height - 5:
					if is_match(i, j, Vector2(0, 1), 5):
						replace_with_special_piece(i, j + 2, current_color, rnbw)
						continue
					elif is_match(i, j, Vector2(0, 1), 4):
						replace_with_special_piece(i, j + 1, current_color, col)
						continue
				elif j <= height - 4:
					if is_match(i, j, Vector2(0, 1), 4):
						replace_with_special_piece(i, j + 1, current_color, col)
						continue
				if i > 0 and i < width - 1 and is_match(i, j, Vector2(1, 0), 3):
					remove_pieces(i, j, true)
				if j > 0 and j < height - 1 and is_match(i, j, Vector2(0, 1), 3):
					remove_pieces(i, j, false)

	get_parent().get_node("destroy_timer").start()

func is_match(i, j, direction: Vector2, length: int) -> bool:
	for k in range(1, length):
		var x = i + k * direction.x
		var y = j + k * direction.y
		if not in_grid(x, y) or all_pieces[x][y] == null or all_pieces[x][y].color != all_pieces[i][j].color:
			return false
	return true

func matchType1(i, j) -> bool:
	if is_match(i, j, Vector2(1, 0), 3) and (
		(j > 0 and all_pieces[i + 1][j - 1] != null and all_pieces[i + 1][j - 1].color == all_pieces[i][j].color) or
		(j < height - 1 and all_pieces[i + 1][j + 1] != null and all_pieces[i + 1][j + 1].color == all_pieces[i][j].color)
	):
		return true

	if is_match(i, j, Vector2(0, 1), 3) and (
		(i > 0 and all_pieces[i - 1][j + 1] != null and all_pieces[i - 1][j + 1].color == all_pieces[i][j].color) or
		(i < width - 1 and all_pieces[i + 1][j + 1] != null and all_pieces[i + 1][j + 1].color == all_pieces[i][j].color)
	):
		return true

	return false

func matchType2(i, j) -> bool:
	if is_match(i, j, Vector2(1, 0), 3):
		if ((
			j > 0 
			and all_pieces[i + 2][j - 1] != null
			and all_pieces[i + 2][j - 1].color == all_pieces[i][j].color) 
			or (
			j < height - 1 
			and all_pieces[i + 2][j + 1] != null 
			and all_pieces[i + 2][j + 1].color == all_pieces[i][j].color)
		):
			return true

	if is_match(i, j, Vector2(0, 1), 3):
		if ((
			i > 0
			and all_pieces[i - 1][j + 2] != null
			and all_pieces[i - 1][j + 2].color == all_pieces[i][j].color) 
			or (
			i < width - 1
			and all_pieces[i + 1][j + 2] != null 
			and all_pieces[i + 1][j + 2].color == all_pieces[i][j].color)
		):
			return true

	return false


func _on_destroy_timer_timeout():
	print("destroy")
	destroy_matched()

func _on_collapse_timer_timeout():
	print("collapse")
	collapse_columns()

func _on_refill_timer_timeout():
	refill_columns()
	
func game_over():
	state = WAIT
	print("game over")
