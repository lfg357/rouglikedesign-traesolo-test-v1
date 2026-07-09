extends Node2D
## 主场景 · 游戏入口
## 负责：初始化迷宫、生成玩家、管理战斗房流程

const PlayerScene: PackedScene = preload("res://scenes/player_yan.tscn")
const EnemyScene: PackedScene = preload("res://scenes/enemy_base.tscn")

@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var camera: Camera2D = $Camera2D
@onready var hit_feel: Node = $HitFeelManager
@onready var labyrinth: LabyrinthGen
@onready var enemies_layer: Node2D = $EnemiesLayer

var current_grid: Array = []
var current_room: Vector2i = Vector2i.ZERO
var player: Node2D = null

func _ready() -> void:
	hit_feel.setup_camera(camera)
	start_new_run()
	_spawn_monster_room()

func start_new_run() -> void:
	GameState.start_run()
	labyrinth = LabyrinthGen.new()
	current_grid = labyrinth.generate_floor(GameState.current_floor)
	_spawn_player()
	_enter_room(Vector2i(0, 5))

func _spawn_player() -> void:
	player = PlayerScene.instantiate()
	player.global_position = player_spawn.global_position
	add_child(player)

func _enter_room(room_pos: Vector2i) -> void:
	current_room = room_pos

	if room_pos.y < 0 or room_pos.y >= current_grid.size():
		return
	if room_pos.x < 0 or room_pos.x >= current_grid[0].size():
		return

	var room = current_grid[room_pos.y][room_pos.x]
	if room == null:
		return

	for child in enemies_layer.get_children():
		child.queue_free()

	match room.type:
		LabyrinthGen.NodeType.MONSTER:
			_spawn_monster_room()
		LabyrinthGen.NodeType.ELITE:
			_spawn_elite_room()
		LabyrinthGen.NodeType.SHOP:
			_setup_shop_room()
		LabyrinthGen.NodeType.EVENT:
			_setup_event_room()
		LabyrinthGen.NodeType.BOSS:
			_spawn_boss_room()
		LabyrinthGen.NodeType.START:
			pass

func _spawn_monster_room() -> void:
	var count: int = randi_range(3, 4)
	for i in range(count):
		var enemy: Node2D = EnemyScene.instantiate()
		var angle: float = randf_range(0, TAU)
		var dist: float = randf_range(140, 220)
		enemy.global_position = player_spawn.global_position + Vector2(cos(angle) * dist, sin(angle) * dist * 0.6)
		enemies_layer.add_child(enemy)

func _spawn_elite_room() -> void:
	pass

func _spawn_boss_room() -> void:
	pass

func _setup_shop_room() -> void:
	pass

func _setup_event_room() -> void:
	pass

func _on_room_cleared() -> void:
	pass
