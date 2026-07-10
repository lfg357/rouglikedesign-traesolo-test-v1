extends Node
## 全局游戏状态单例
## 管理：三层货币、当前层数、run 状态、玩家属性 buff 聚合

# ─── 三层货币 ───
var player_qi: int = 0          # 灵气（层内，层末清零）
var player_spirit_stone: int = 0 # 灵石（跨层，run 结束清零）
var player_karma: int = 0        # 业力（meta，跨 run 永久）

# ─── Run 状态 ───
var current_floor: int = 1       # 当前层数 1-5
var is_run_active: bool = false  # 是否在一局中
var player_max_hp_base: int = 100
var player_max_mp_base: int = 60

# ─── 聚合属性（由遗物/反应 buff 叠加） ───
var stats: Dictionary = {
    "damage_mul": 1.0,        # 伤害倍率
    "move_mul": 1.0,          # 移速倍率
    "crit_chance": 0.08,      # 暴击率
    "crit_damage": 1.5,       # 暴击伤害
    "max_hp_pct": 0.0,        # 最大生命百分比加成
    "damage_reduce": 0.0,     # 减伤
    "lifesteal": 0.0,         # 吸血
    "hp_regen": 0.0,          # 每秒回血
    "qi_mult": 1.0,           # 灵气获取倍率
}

# ─── 信号 ───
signal stats_changed()
signal currency_changed()
signal floor_changed(new_floor)

# ─── 货币操作 ───
func add_qi(amount: int) -> void:
    player_qi += int(amount * stats.qi_mult)
    currency_changed.emit()

func spend_qi(amount: int) -> bool:
    if player_qi >= amount:
        player_qi -= amount
        currency_changed.emit()
        return true
    return false

func add_spirit_stone(amount: int) -> void:
    player_spirit_stone += amount
    currency_changed.emit()

func spend_spirit_stone(amount: int) -> bool:
    if player_spirit_stone >= amount:
        player_spirit_stone -= amount
        currency_changed.emit()
        return true
    return false

func add_karma(amount: int) -> void:
    player_karma += amount
    currency_changed.emit()

# ─── 层结束：清零灵气 ───
func on_floor_clear() -> void:
    player_qi = 0
    current_floor += 1
    floor_changed.emit(current_floor)
    currency_changed.emit()

# ─── Run 开始 / 结束 ───
func start_run() -> void:
    current_floor = 1
    player_qi = 0
    player_spirit_stone = 0
    reset_stats()
    is_run_active = true

func end_run(victory: bool) -> void:
    # 幂等保护：同一 run 只结算一次，避免死亡屏被多次打开时重复扣/加业力
    if not is_run_active:
        return
    is_run_active = false
    # 死亡给 50 业力，通关给 200
    add_karma(200 if victory else 50)

# ─── 属性聚合 ───
func reset_stats() -> void:
    stats = {
        "damage_mul": 1.0,
        "move_mul": 1.0,
        "crit_chance": 0.08,
        "crit_damage": 1.5,
        "max_hp_pct": 0.0,
        "damage_reduce": 0.0,
        "lifesteal": 0.0,
        "hp_regen": 0.0,
        "qi_mult": 1.0,
    }
    stats_changed.emit()

## 叠加一组 buff（来自遗物/反应激活）
func apply_buff(buff_dict: Dictionary) -> void:
    for key in buff_dict:
        if stats.has(key):
            stats[key] += buff_dict[key]
    stats_changed.emit()

## 移除一组 buff（遗物/反应失效时）
func remove_buff(buff_dict: Dictionary) -> void:
    for key in buff_dict:
        if stats.has(key):
            stats[key] -= buff_dict[key]
    stats_changed.emit()

## 获取最终玩家最大 HP
func get_player_max_hp() -> int:
    return int(player_max_hp_base * (1.0 + stats.max_hp_pct))
