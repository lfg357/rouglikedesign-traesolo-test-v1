extends Node2D
## 主场景 · 游戏入口
## 负责：初始化迷宫、生成玩家、管理战斗房流程、UI快捷键、房间切换

const PlayerScene: PackedScene = preload("res://scenes/player_yan.tscn")
const EnemyScene: PackedScene = preload("res://scenes/enemy_base.tscn")

const START_ROOM: Vector2i = Vector2i(0, 5)  # 起点：左下角

@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var camera: Camera2D = $Camera2D
@onready var hit_feel: Node = $HitFeelManager
@onready var enemies_layer: Node2D = $EnemiesLayer

var labyrinth: LabyrinthGen = null
var current_grid: Array = []
var current_room: Vector2i = Vector2i.ZERO
var player: Node2D = null
var _kill_count: int = 0

# ─── 房间状态 ───
var _cleared_rooms: Array = []  # Array[Vector2i] 已清理房间
var _is_room_active: bool = false  # 当前房间是否在战斗中
var _is_elite_room: bool = false
var _is_boss_room: bool = false
var _pending_relic_select: bool = false  # 事件 outcome=relic 标志，避免与小地图开屏竞态

func _ready() -> void:
	# PROCESS_MODE_ALWAYS：允许 M 键在暂停时关闭小地图；_process 内有 paused 守卫
	process_mode = Node.PROCESS_MODE_ALWAYS
	$Background.z_index = -100
	hit_feel.setup_camera(camera)
	CombatEvents.enemy_killed.connect(_on_enemy_killed)
	UIManager.ui_closed.connect(_on_ui_closed)
	start_new_run()

# ─── UI 关闭后流程衔接 ───
func _on_ui_closed(ui_name: String) -> void:
	match ui_name:
		"event_ui":
			# 事件后若需开遗物选择则开，否则开小地图
			if _pending_relic_select:
				_pending_relic_select = false
				call_deferred("_open_relic_select")
				return
		"shop_ui", "relic_select":
			pass
		_:
			return
	# 默认：若无 UI 打开且房间已清理，开小地图选择下一房间
	if not UIManager.has_ui_open() and _cleared_rooms.has(current_room) and not _is_room_active:
		call_deferred("_open_minimap")

func _process(_delta: float) -> void:
	# 暂停时不检测房间清理（UI 打开期间）
	if get_tree().paused:
		return
	# 房间清理检测：战斗中且无存活敌人 → 触发清理流程
	if _is_room_active and _count_alive_enemies() == 0:
		_on_room_cleared()

# ─── 击杀计数 ───
func _on_enemy_killed(_enemy: Node) -> void:
	_kill_count += 1

func _count_alive_enemies() -> int:
	var count: int = 0
	for e in enemies_layer.get_children():
		if not is_instance_valid(e):
			continue
		var dead = e.get("_is_dead")
		if dead == null or not dead:
			count += 1
	return count

# ─── 快捷键 ───
func _unhandled_input(event: InputEvent) -> void:
	# 暂停菜单（Esc）
	if event.is_action_pressed("pause") and not get_tree().paused:
		if not UIManager.has_ui_open():
			UIManager.open_ui("pause_menu")
			get_viewport().set_input_as_handled()
	# 背包（I）
	if event.is_action_pressed("open_inventory") and not get_tree().paused:
		UIManager.toggle_ui("inventory")
		get_viewport().set_input_as_handled()
	# 五行盘（Tab）
	if event.is_action_pressed("open_wuxing") and not get_tree().paused:
		UIManager.toggle_ui("wuxing_board")
		get_viewport().set_input_as_handled()
	# 小地图（M）- 打开时再按 M 可关闭（暂停态也可关闭）
	if event.is_action_pressed("open_minimap"):
		if UIManager.is_ui_open("minimap_ui"):
			UIManager.close_ui("minimap_ui")
			get_viewport().set_input_as_handled()
		elif not get_tree().paused:
			_open_minimap()
			get_viewport().set_input_as_handled()

# ─── Run / 迷宫初始化 ───
func start_new_run() -> void:
	GameState.start_run()
	if labyrinth:
		labyrinth.queue_free()
	labyrinth = LabyrinthGen.new()
	add_child(labyrinth)
	current_grid = labyrinth.generate_floor(GameState.current_floor)
	_cleared_rooms.clear()
	_kill_count = 0
	# 释放旧玩家（重开 run 时）
	if player and is_instance_valid(player):
		player.queue_free()
		player = null
	_spawn_player()
	_enter_room(START_ROOM)

func _spawn_player() -> void:
	if player and is_instance_valid(player):
		return
	player = PlayerScene.instantiate()
	player.global_position = player_spawn.global_position
	add_child(player)

# ─── 房间进入 ───
func _enter_room(room_pos: Vector2i) -> void:
	if not _is_valid_room(room_pos):
		return
	var room = current_grid[room_pos.y][room_pos.x]
	if room == null:
		return

	current_room = room_pos
	_clear_enemies()
	_is_room_active = false
	_is_elite_room = false
	_is_boss_room = false

	# 玩家位置重置到房间中心
	if player and is_instance_valid(player):
		player.global_position = player_spawn.global_position

	match room.type:
		LabyrinthGen.NodeType.START:
			# 起点也 spawn 一波初始遭遇战，清理后开放出口
			_spawn_monster_room()
			_is_room_active = true
		LabyrinthGen.NodeType.MONSTER:
			_spawn_monster_room()
			_is_room_active = true
		LabyrinthGen.NodeType.ELITE:
			_spawn_elite_room()
			_is_room_active = true
			_is_elite_room = true
		LabyrinthGen.NodeType.SHOP:
			_setup_shop_room()
			if not _cleared_rooms.has(room_pos):
				_cleared_rooms.append(room_pos)
		LabyrinthGen.NodeType.EVENT:
			# 事件房预先标记清理（Esc 关闭也能正确衔接小地图）
			if not _cleared_rooms.has(room_pos):
				_cleared_rooms.append(room_pos)
			_setup_event_room()
		LabyrinthGen.NodeType.BOSS:
			_spawn_boss_room()
			_is_room_active = true
			_is_boss_room = true

func _is_valid_room(pos: Vector2i) -> bool:
	if pos.y < 0 or pos.y >= current_grid.size():
		return false
	if pos.x < 0 or pos.x >= current_grid[pos.y].size():
		return false
	return current_grid[pos.y][pos.x] != null

func _clear_enemies() -> void:
	for child in enemies_layer.get_children():
		child.queue_free()

# ─── 房间生成 ───
func _spawn_monster_room() -> void:
	var count: int = randi_range(3, 4)
	for i in range(count):
		var enemy: Node2D = EnemyScene.instantiate()
		var angle: float = randf_range(0, TAU)
		var dist: float = randf_range(140, 220)
		enemy.global_position = player_spawn.global_position + Vector2(cos(angle) * dist, sin(angle) * dist * 0.6)
		enemies_layer.add_child(enemy)

func _spawn_elite_room() -> void:
	var elite: Node2D = EnemyScene.instantiate()
	elite.max_hp = 120
	elite.damage = 18.0
	elite.move_speed = 100.0
	elite.global_position = player_spawn.global_position + Vector2(0, -180)
	enemies_layer.add_child(elite)

func _spawn_boss_room() -> void:
	var boss: Node2D = EnemyScene.instantiate()
	boss.max_hp = 400
	boss.damage = 25.0
	boss.move_speed = 70.0
	boss.scale = Vector2(1.6, 1.6)
	boss.global_position = player_spawn.global_position + Vector2(0, -180)
	enemies_layer.add_child(boss)

# ─── 商店房间 ───
func _setup_shop_room() -> void:
	UIManager.open_ui("shop_ui")

# ─── 事件房间 ───
func _setup_event_room() -> void:
	UIManager.open_ui("event_ui")
	var ev: CanvasLayer = UIManager.get_ui("event_ui")
	if ev:
		ev.setup(_generate_event())
		if not ev.event_chosen.is_connected(_on_event_chosen):
			ev.event_chosen.connect(_on_event_chosen)
		if not ev.event_closed.is_connected(_on_event_closed):
			ev.event_closed.connect(_on_event_closed)

func _generate_event() -> Dictionary:
	var events: Array = [
		{
			"title": "古碑奇遇",
			"desc": "你在迷雾中发现一块古碑，碑上刻有晦涩铭文。如何处置？",
			"options": [
				{"text": "参悟碑文（消耗30灵气，获遗物）", "outcome": "relic"},
				{"text": "汲取灵韵（获50灵气）", "outcome": "qi"},
				{"text": "离开", "outcome": "leave"}
			]
		},
		{
			"title": "落难商人",
			"desc": "一位受伤的商人恳求你的帮助。",
			"options": [
				{"text": "赠予50灵石（业力-5）", "outcome": "donate"},
				{"text": "抢夺货物（获80灵石，业力+10）", "outcome": "rob"},
				{"text": "无视离开", "outcome": "leave"}
			]
		},
	]
	return events[randi() % events.size()]

func _on_event_chosen(index: int) -> void:
	var ev: CanvasLayer = UIManager.get_ui("event_ui")
	if not ev:
		return
	var outcome: String = ev.get_outcome(index)
	match outcome:
		"relic":
			if GameState.spend_qi(30):
				# 设置标志，event_ui 关闭后由 _on_ui_closed 衔接 relic_select（避免双 defer 竞态）
				_pending_relic_select = true
		"qi":
			GameState.add_qi(50)
		"donate":
			if GameState.spend_spirit_stone(50):
				GameState.add_karma(-5)
		"rob":
			GameState.add_spirit_stone(80)
			GameState.add_karma(10)
		"leave":
			pass

func _on_event_closed() -> void:
	if not _cleared_rooms.has(current_room):
		_cleared_rooms.append(current_room)

# ─── 房间清理流程 ───
func _on_room_cleared() -> void:
	_is_room_active = false
	if not _cleared_rooms.has(current_room):
		_cleared_rooms.append(current_room)

	if _is_boss_room:
		# Boss 死亡 → 层间结算
		_trigger_floor_clear()
	elif _is_elite_room:
		# 精英死亡 → 遗物选择
		_open_relic_select()
	else:
		# 普通房间清理 → 打开小地图
		_open_minimap()

# ─── 层间结算 ───
func _trigger_floor_clear() -> void:
	UIManager.open_ui("floor_clear")
	var fc: CanvasLayer = UIManager.get_ui("floor_clear")
	if fc:
		if not fc.floor_continued.is_connected(_on_floor_continued):
			fc.floor_continued.connect(_on_floor_continued)
		fc.setup(_kill_count, GameState.current_floor)

func _on_floor_continued() -> void:
	# GameState.on_floor_clear 已在 floor_clear.gd 中调用（current_floor+=1, 灵气清零）
	# 重新生成下一层迷宫
	if labyrinth:
		current_grid = labyrinth.generate_floor(GameState.current_floor)
	else:
		labyrinth = LabyrinthGen.new()
		add_child(labyrinth)
		current_grid = labyrinth.generate_floor(GameState.current_floor)
	_cleared_rooms.clear()
	_kill_count = 0  # 每层击杀数独立统计
	# 玩家位置重置后进入起点
	_enter_room(START_ROOM)

# ─── 遗物选择 ───
func _open_relic_select() -> void:
	UIManager.open_ui("relic_select")
	var rs: CanvasLayer = UIManager.get_ui("relic_select")
	if rs:
		if not rs.relic_chosen.is_connected(_on_relic_chosen):
			rs.relic_chosen.connect(_on_relic_chosen)

func _on_relic_chosen(relic_id: String) -> void:
	# 应用遗物：放入五行盘第一个空槽 + 应用 stats buff
	var relic: Dictionary = RelicDB.get_relic(relic_id)
	if relic.is_empty():
		return
	# 放入五行盘第一个空槽（满则跳过，stats 仍生效）
	var element: String = RelicDB.get_relic_element(relic_id)
	for i in range(5):
		if WuxingBoard.slots[i] == "":
			WuxingBoard.place_relic(i, relic_id, element)
			break
	# 应用 stats buff（无论是否放入五行盘，遗物属性都生效）
	var stats: Dictionary = RelicDB.get_relic_stats(relic_id)
	if not stats.is_empty():
		GameState.apply_buff(stats)
	# 遗物选择关闭后由 _on_ui_closed 自动打开小地图

# ─── 小地图 ───
func _open_minimap() -> void:
	if UIManager.is_ui_open("minimap_ui"):
		var mm: CanvasLayer = UIManager.get_ui("minimap_ui")
		if mm:
			mm.refresh(current_room, _cleared_rooms)
		return
	UIManager.open_ui("minimap_ui")
	var mm: CanvasLayer = UIManager.get_ui("minimap_ui")
	if mm:
		if not mm.room_selected.is_connected(_move_to_room):
			mm.room_selected.connect(_move_to_room)
		mm.setup(current_grid, current_room, _cleared_rooms)

func _toggle_minimap() -> void:
	if UIManager.is_ui_open("minimap_ui"):
		UIManager.close_ui("minimap_ui")
	else:
		_open_minimap()

func _move_to_room(new_room: Vector2i) -> void:
	# 关闭小地图并进入新房间
	UIManager.close_ui("minimap_ui")
	_enter_room(new_room)
