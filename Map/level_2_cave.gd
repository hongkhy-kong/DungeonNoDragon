extends Node2D

@export var mob1_scene: PackedScene
@export var vampire_scene: PackedScene

# Harder than Level 1
@export var mob_count := 25

@export var map_width := 70
@export var map_height := 100

@export var room_count := 20
@export var room_min_size := 8
@export var room_max_size := 18

@onready var floor_layer = $FloorLayer
@onready var wall_layer = $WallLayer
@onready var player = $player

var floor_cells: Array[Vector2i] = []
var wall_cells: Array[Vector2i] = []

class Room:
	var x: int
	var y: int
	var w: int
	var h: int

	func _init(px, py, pw, ph):
		x = px
		y = py
		w = pw
		h = ph

	func center() -> Vector2i:
		return Vector2i(
			x + w / 2,
			y + h / 2
		)

	func intersects(other) -> bool:
		return (
			x < other.x + other.w
			and x + w > other.x
			and y < other.y + other.h
			and y + h > other.y
		)

func _ready():
	randomize()
	generate_dungeon()

func generate_dungeon():

	floor_layer.clear()
	wall_layer.clear()

	floor_cells.clear()
	wall_cells.clear()

	var rooms = []

	# =====================
	# CREATE ROOMS
	# =====================

	for i in room_count:

		var w = randi_range(room_min_size, room_max_size)
		var h = randi_range(room_min_size, room_max_size)

		var x = randi_range(2, map_width - w - 2)
		var y = randi_range(2, map_height - h - 2)

		var new_room = Room.new(x, y, w, h)

		var overlaps = false

		for room in rooms:
			if new_room.intersects(room):
				overlaps = true
				break

		if overlaps:
			continue

		rooms.append(new_room)

		for rx in range(new_room.x, new_room.x + new_room.w):
			for ry in range(new_room.y, new_room.y + new_room.h):
				floor_cells.append(Vector2i(rx, ry))

	# =====================
	# PLAYER SPAWN
	# =====================

	if rooms.size() > 0:

		var spawn_room = rooms.pick_random()
		var spawn_pos = spawn_room.center()

		player.global_position = Vector2(
			spawn_pos.x * 16 + 8,
			spawn_pos.y * 16 + 8
		)

	# =====================
	# CONNECT ROOMS
	# =====================

	for i in range(rooms.size() - 1):

		var room_a = rooms[i]
		var room_b = rooms[i + 1]

		var start = room_a.center()
		var end = room_b.center()

		for x in range(min(start.x, end.x), max(start.x, end.x) + 1):
			for offset in range(-1, 2):
				floor_cells.append(Vector2i(x, start.y + offset))

		for y in range(min(start.y, end.y), max(start.y, end.y) + 1):
			for offset in range(-1, 2):
				floor_cells.append(Vector2i(end.x + offset, y))

	# =====================
	# GENERATE WALLS
	# =====================

	var dirs = [
		Vector2i.LEFT,
		Vector2i.RIGHT,
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i(-1, -1),
		Vector2i(1, -1),
		Vector2i(-1, 1),
		Vector2i(1, 1)
	]

	for floor_tile in floor_cells:
		for dir in dirs:

			var pos = floor_tile + dir

			if !floor_cells.has(pos):
				if !wall_cells.has(pos):
					wall_cells.append(pos)

	# =====================
	# DRAW FLOORS
	# =====================

	floor_layer.set_cells_terrain_connect(
		floor_cells,
		0,
		0
	)

	# =====================
	# DRAW WALLS
	# =====================

	for wall_pos in wall_cells:
		wall_layer.set_cell(
			wall_pos,
			0,
			Vector2i(1, 4)
		)

	# =====================
	# SPAWN MOBS
	# =====================

	spawn_mobs(rooms)

func spawn_mobs(rooms):

	# More Mob1 than Vampires
	var mob_scenes = [
		mob1_scene,
		mob1_scene,
		mob1_scene,
		vampire_scene
	]

	for i in range(mob_count):

		var room = rooms.pick_random()

		var x = randi_range(
			room.x + 1,
			room.x + room.w - 2
		)

		var y = randi_range(
			room.y + 1,
			room.y + room.h - 2
		)

		var scene = mob_scenes.pick_random()

		if scene == null:
			continue

		var mob = scene.instantiate()

		mob.global_position = Vector2(
			x * 16 + 8,
			y * 16 + 8
		)

		add_child(mob)

	print("LEVEL 2 GENERATED")
	print("Rooms: ", rooms.size())
	print("Enemies: ", mob_count)
