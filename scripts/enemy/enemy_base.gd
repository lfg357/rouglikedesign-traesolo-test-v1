extends CharacterBody2D
## 敌人基类
## 包含：HP、伤害、AI 巡逻/追击、受击反馈、死亡掉落

class_name EnemyBase

@export var max_hp: int = 30
@export var damage: float = 10.0
@export var move_speed: float = 80.0
@export var detect_range: float = 200.0
@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.5

var current_hp: int
var _attack_cd: float = 0.0
var _player_ref: Node2D = null
var _is_dead: bool = false

@onready var hurtbox: Area2D = $Hurtbox
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var sprite: Sprite2D = $Sprite

signal enemy_died(enemy)

func _ready() -> void:
    current_hp = max_hp
    hurtbox.area_entered.connect(_on_player_hit)

func _physics_process(delta: float) -> void:
    if _is_dead:
        return
    
    if _attack_cd > 0:
        _attack_cd -= delta
    
    if _player_ref == null:
        _find_player()
        _idle_wander(delta)
    else:
        _chase_and_attack(delta)
    
    move_and_slide()

# ─── 寻找玩家 ───
func _find_player() -> void:
    var players: Array = get_tree().get_nodes_in_group("player")
    if players.size() > 0:
        _player_ref = players[0]

# ─── 闲逛 ───
func _idle_wander(delta: float) -> void:
    # 简单左右巡逻
    velocity = Vector2.LEFT * move_speed * 0.3
    sprite.flip_h = true

# ─── 追击 + 攻击 ───
func _chase_and_attack(delta: float) -> void:
    if _player_ref == null:
        return
    
    var dir: Vector2 = (_player_ref.global_position - global_position).normalized()
    var dist: float = global_position.distance_to(_player_ref.global_position)
    
    sprite.flip_h = dir.x < 0
    
    if dist > attack_range:
        # 追击
        velocity = dir * move_speed
    else:
        # 攻击
        velocity = Vector2.ZERO
        if _attack_cd <= 0:
            _do_attack()
            _attack_cd = attack_cooldown

func _do_attack() -> void:
    # 攻击由 attack_hitbox 碰撞检测
    pass

# ─── 被玩家命中 ───
func _on_player_hit(area: Area2D) -> void:
    # 由玩家侧调用 take_damage
    pass

## 玩家调用：造成伤害
func take_damage(amount: float, is_crit: bool = false) -> void:
    if _is_dead:
        return
    
    current_hp -= int(amount)
    
    # 受击击退
    if _player_ref:
        var knockback: Vector2 = (global_position - _player_ref.global_position).normalized() * 50.0
        velocity += knockback
    
    if current_hp <= 0:
        _die()

func _die() -> void:
    _is_dead = true
    queue_free()
    
    # 掉落灵气 + 灵石
    GameState.add_qi(5)
    GameState.add_spirit_stone(5)
    
    enemy_died.emit(self)
    CombatEvents.enemy_killed.emit(self)

## 给玩家伤害查询用
func get_damage() -> float:
    return damage
