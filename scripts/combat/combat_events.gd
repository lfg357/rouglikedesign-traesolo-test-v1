extends Node
## 战斗事件总线
## 解耦打击感系统、伤害系统、UI 反馈
## 所有命中、受伤、暴击都走这里发信号

# 命中事件（打击感系统监听）
signal hit_occurred(position: Vector2, damage: float, is_crit: bool, element: String)

# 玩家受伤
signal player_damaged(damage: float)

# 敌人死亡
signal enemy_killed(enemy_data)

# 暴击触发
signal critical_strike(position: Vector2)

# 闪避成功
signal dodge_success(position: Vector2)

## 触发命中（伤害系统调用，打击感系统监听）
func trigger_hit(position: Vector2, damage: float, is_crit: bool = false, element: String = "none") -> void:
    hit_occurred.emit(position, damage, is_crit, element)
    if is_crit:
        critical_strike.emit(position)
