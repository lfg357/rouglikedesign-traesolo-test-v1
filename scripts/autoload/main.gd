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
    # 初始化打击感相机
    hit_feel.setup_camera(camera)

    # 开始新 run
    start_new_run()

func start_new_run() -> void:
    GameState.start_run()

    # 生成迷宫
    labyrinth = LabyrinthGen.new()
    current_grid = labyrinth.generate_floor(GameState.current_floor)

    # 生成玩家
    _spawn_player()

    # 生成当前房间敌人
    _enter_room(Vector2i(0, 5))  # 起点

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

    # 清空旧敌人
    for child in enemies_layer.get_children():
        child.queue_free()

    # 根据房间类型生成内容
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
            pass  # 起点房，安全

func _spawn_monster_room() -> void:
    var count: int = randi_range(2, 3)
    for i in range(count):
        var enemy: Node2D = EnemyScene.instantiate()
        enemy.global_position = player_spawn.global_position + Vector2(
            randf_range(-150, 150),
            randf_range(-100, 100)
        )
        enemies_layer.add_child(enemy)

func _spawn_elite_room() -> void:
    # TODO: 生成精英怪 + 小怪
    pass

func _spawn_boss_room() -> void:
    # TODO: 生成 Boss
    pass

func _setup_shop_room() -> void:
    # TODO: 生成商店 NPC + 交互
    pass

func _setup_event_room() -> void:
    # TODO: 随机事件
    pass

# ─── 房间清理完成 → 开门 ───
func _on_room_cleared() -> void:
    # TODO: 显示可通行方向
    pass
