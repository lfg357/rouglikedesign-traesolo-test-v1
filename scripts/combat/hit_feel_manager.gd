extends Node
## 打击感管理器 · 落墨即杀
## 监听 CombatEvents，统一处理命中反馈：
## 1. Hit Stop（命中顿帧）
## 2. 屏幕震动
## 3. 水墨迸发粒子
## 4. 伤害飘字

@onready var camera: Camera2D
# Hit Stop 用墙钟时间避免 time_scale 自锁
var _hit_stop_end_msec: int = 0
var _shake_intensity: float = 0.0
var _shake_timer: float = 0.0

# 飘字场景（预加载，实际项目中换成 PackedScene）
# var damage_number_scene: PackedScene = preload("res://scenes/effects/damage_number.tscn")

func _ready() -> void:
    CombatEvents.hit_occurred.connect(_on_hit)
    CombatEvents.critical_strike.connect(_on_crit)
    CombatEvents.player_damaged.connect(_on_player_damaged)

func _process(delta: float) -> void:
    # Hit Stop：用墙钟时间判定，不受 time_scale 影响
    var now: int = Time.get_ticks_msec()
    if now < _hit_stop_end_msec:
        Engine.time_scale = 0.01  # 近乎暂停
    else:
        Engine.time_scale = 1.0

    # 震屏
    if _shake_timer > 0:
        _shake_timer -= delta
        if camera:
            var shake: Vector2 = Vector2(
                randf_range(-_shake_intensity, _shake_intensity),
                randf_range(-_shake_intensity, _shake_intensity)
            )
            camera.offset = shake
    else:
        if camera:
            camera.offset = Vector2.ZERO

## 设置相机引用（由主场景调用）
func setup_camera(cam: Camera2D) -> void:
    camera = cam

# ─── 命中反馈 ───
func _on_hit(position: Vector2, damage: float, is_crit: bool, element: String) -> void:
    # Hit Stop 时长
    var stop_duration: float = 0.06  # 默认 60ms
    if is_crit:
        stop_duration = 0.12  # 暴击双倍顿帧
    _trigger_hit_stop(stop_duration)
    
    # 震屏
    var shake: float = 3.0
    if is_crit:
        shake = 8.0
    _trigger_shake(shake, 0.15)
    
    # 水墨迸发（粒子效果，占位）
    _spawn_ink_burst(position, element, is_crit)
    
    # 飘字
    _spawn_damage_number(position, damage, is_crit)

func _on_crit(position: Vector2) -> void:
    # 暴击额外特效
    pass

func _on_player_damaged(damage: float) -> void:
    _trigger_shake(5.0, 0.2)

# ─── Hit Stop ───
func _trigger_hit_stop(duration: float) -> void:
    # 取较长的那个，避免连续命中被覆盖
    var end_msec: int = Time.get_ticks_msec() + int(duration * 1000)
    if end_msec > _hit_stop_end_msec:
        _hit_stop_end_msec = end_msec

# ─── 震屏 ───
func _trigger_shake(intensity: float, duration: float) -> void:
    if intensity > _shake_intensity:
        _shake_intensity = intensity
    _shake_timer = max(_shake_timer, duration)

# ─── 水墨迸发（占位，后续接 GPUParticles2D） ───
func _spawn_ink_burst(position: Vector2, element: String, is_crit: bool) -> void:
    # TODO: 实例化水墨粒子特效
    # 颜色按元素：金=白、水=青、木=绿、火=朱、土=褐
    # 暴击时粒子数 ×2，范围 ×1.5
    pass

# ─── 伤害飘字（占位） ───
func _spawn_damage_number(position: Vector2, damage: float, is_crit: bool) -> void:
    # TODO: 实例化飘字 Label
    # 普通=白色小字，暴击=金色大字 + 弹跳动画
    pass
