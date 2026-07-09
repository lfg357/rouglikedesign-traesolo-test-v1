extends CharacterBody2D
## 燕无归 · 身法近战（手感旗舰）
## 操作：WASD 移动 / 左键 三段连击 / Space 瞬移闪避
## 核心手感：连击起承转合 + 瞬移残影 + 命中顿帧

class_name PlayerYan

# ─── 属性 ───
@export var max_hp: int = 100
@export var move_speed: float = 230.0
var current_hp: int = 100

# 闪避
@export var dodge_distance: float = 150.0
@export var dodge_duration: float = 0.25
@export var dodge_iframes: float = 0.5
@export var dodge_cooldown: float = 1.2
var _dodge_cd_timer: float = 0.0
var _is_dodging: bool = false
var _dodge_dir: Vector2 = Vector2.ZERO
var _dodge_timer: float = 0.0

# 连击
@export var combo_window: float = 2.5
var _combo_step: int = 0  # 0-2 三段
var _combo_timer: float = 0.0
var _is_attacking: bool = false
var _attack_timer: float = 0.0
var _attack_duration: float = 0.3

# 第三段突进（锁定 velocity 约 8 帧）
const DASH_DURATION: float = 0.13  # ~8 帧 @60fps
var _dash_timer: float = 0.0

# 伤害
@export var base_damage: float = 12.0
var _facing_dir: Vector2 = Vector2.RIGHT

# 无敌帧
var _iframes: float = 0.0

# 信号
signal hp_changed(current: int, max_hp: int)
signal player_died()

# ─── 子节点引用 ───
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox
@onready var sprite: Sprite2D = $Sprite
@onready var afterimage_timer: Timer = $AfterimageTimer

func _ready() -> void:
    current_hp = max_hp
    add_to_group("player")
    hurtbox.area_entered.connect(_on_enemy_attack_hit)
    hitbox.area_entered.connect(_on_hit_enemy)

# ─── 主循环 ───
func _physics_process(delta: float) -> void:
    _update_timers(delta)

    if _is_dodging:
        _process_dodge(delta)
    elif _dash_timer > 0:
        # 第三段突进期间：锁定 velocity，不读输入
        velocity = _facing_dir * move_speed * 2.0
    elif _is_attacking:
        _process_attack(delta)
        _idle_movement(delta * 0.3)  # 攻击中减速移动
    else:
        _handle_input()
        _idle_movement(delta)

    move_and_slide()

# ─── 计时器更新 ───
func _update_timers(delta: float) -> void:
    if _dodge_cd_timer > 0:
        _dodge_cd_timer -= delta
    if _dash_timer > 0:
        _dash_timer -= delta
    if _combo_timer > 0:
        _combo_timer -= delta
        if _combo_timer <= 0:
            _combo_step = 0
    if _iframes > 0:
        _iframes -= delta

# ─── 输入处理 ───
func _handle_input() -> void:
    # 攻击
    if Input.is_action_just_pressed("attack"):
        _start_attack()
    
    # 闪避
    if Input.is_action_just_pressed("dodge") and _dodge_cd_timer <= 0:
        _start_dodge()

# ─── 移动 ───
func _idle_movement(delta: float) -> void:
    var input_dir: Vector2 = Vector2(
        Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
        Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
    ).normalized()
    
    var speed_mult: float = GameState.stats.move_mul
    velocity = input_dir * move_speed * speed_mult
    
    if input_dir.length() > 0.1:
        _facing_dir = input_dir
        sprite.flip_h = input_dir.x < 0

# ─── 三段连击 ───
func _start_attack() -> void:
    _is_attacking = true
    _attack_timer = _attack_duration
    _combo_timer = combo_window
    
    # 根据连击段数调整伤害和手感
    match _combo_step:
        0:
            _attack_duration = 0.25
        1:
            _attack_duration = 0.28
        2:
            _attack_duration = 0.4  # 第三段最重，突进
            _dash_on_third_hit()
    
    # 更新 hitbox 位置
    _update_hitbox_position()

func _process_attack(delta: float) -> void:
    _attack_timer -= delta
    if _attack_timer <= 0:
        _is_attacking = false
        _combo_step = (_combo_step + 1) % 3

func _update_hitbox_position() -> void:
    hitbox.position = _facing_dir * 40.0

func _dash_on_third_hit() -> void:
    # 第三段附带小突进：锁定 velocity 约 8 帧
    _dash_timer = DASH_DURATION
    velocity = _facing_dir * move_speed * 2.0

# ─── 瞬移闪避 ───
func _start_dodge() -> void:
    _is_dodging = true
    _dodge_timer = dodge_duration
    _dodge_cd_timer = dodge_cooldown
    _iframes = dodge_iframes
    
    # 闪避方向：有输入按输入方向，无输入按朝向
    var input_dir: Vector2 = Vector2(
        Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
        Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
    ).normalized()
    
    _dodge_dir = input_dir if input_dir.length() > 0.1 else _facing_dir
    
    # 触发闪避事件
    CombatEvents.dodge_success.emit(global_position)
    
    # 残影效果（由打击感系统监听实现）

func _process_dodge(delta: float) -> void:
    _dodge_timer -= delta
    var speed: float = dodge_distance / dodge_duration
    velocity = _dodge_dir * speed
    
    if _dodge_timer <= 0:
        _is_dodging = false
        velocity = Vector2.ZERO

# ─── 命中敌人 ───
func _on_hit_enemy(area: Area2D) -> void:
    if not _is_attacking:
        return
    
    # 计算伤害
    var damage: float = base_damage * GameState.stats.damage_mul
    var is_crit: bool = randf() < GameState.stats.crit_chance
    if is_crit:
        damage *= GameState.stats.crit_damage
    
    # 发送命中事件（打击感系统监听）
    CombatEvents.trigger_hit(area.global_position, damage, is_crit, "water")
    
    # 吸血
    if GameState.stats.lifesteal > 0:
        heal(int(damage * GameState.stats.lifesteal))

    # 通知敌人受伤（area 是敌人 Hurtbox，take_damage 在父节点 CharacterBody2D 上）
    var target: Node = area.get_parent()
    if target.has_method("take_damage"):
        target.take_damage(damage, is_crit)

# ─── 受伤 ───
func _on_enemy_attack_hit(area: Area2D) -> void:
    if _iframes > 0:
        return
    
    var damage: float = 10.0  # 默认值，实际由敌人提供
    if area.has_method("get_damage"):
        damage = area.get_damage()
    
    # 减伤
    damage *= (1.0 - GameState.stats.damage_reduce)
    take_damage(int(damage))

func take_damage(amount: int) -> void:
    if _iframes > 0:
        return
    
    current_hp -= amount
    current_hp = max(0, current_hp)
    hp_changed.emit(current_hp, max_hp)
    CombatEvents.player_damaged.emit(amount)
    
    # 受击无敌帧
    _iframes = 0.3
    
    if current_hp <= 0:
        _die()

func heal(amount: int) -> void:
    current_hp = min(max_hp, current_hp + amount)
    hp_changed.emit(current_hp, max_hp)

func _die() -> void:
    player_died.emit()
    set_physics_process(false)

# ─── 回血（每秒） ───
func _process(delta: float) -> void:
    if GameState.stats.hp_regen > 0 and current_hp > 0:
        heal(int(GameState.stats.hp_regen * delta))
