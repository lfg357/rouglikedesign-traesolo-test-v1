extends CharacterBody2D
## 敌人基类 · Demon 像素精灵
## 资源：Tiny RPG Character Asset Pack 02 (Demon_A)

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
var _is_attacking: bool = false

@onready var hurtbox: Area2D = $Hurtbox
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D

signal enemy_died(enemy)

func _ready() -> void:
	current_hp = max_hp
	add_to_group("enemy")
	hurtbox.area_entered.connect(_on_player_hit)
	sprite.play("idle")
	sprite.animation_finished.connect(_on_anim_finished)

func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	if _attack_cd > 0:
		_attack_cd -= delta

	if _player_ref == null:
		_find_player()
		_idle_wander(delta)
	elif _is_attacking:
		velocity = Vector2.ZERO
	else:
		_chase_and_attack(delta)

	move_and_slide()

func _find_player() -> void:
	var players: Array = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player_ref = players[0]

func _idle_wander(delta: float) -> void:
	velocity = Vector2.LEFT * move_speed * 0.3
	sprite.flip_h = true
	if sprite.animation != "walk":
		sprite.play("walk")

func _chase_and_attack(delta: float) -> void:
	if _player_ref == null:
		return

	var dir: Vector2 = (_player_ref.global_position - global_position).normalized()
	var dist: float = global_position.distance_to(_player_ref.global_position)

	sprite.flip_h = dir.x < 0

	if dist > attack_range:
		velocity = dir * move_speed
		if sprite.animation != "walk":
			sprite.play("walk")
	else:
		velocity = Vector2.ZERO
		if sprite.animation != "idle":
			sprite.play("idle")
		if _attack_cd <= 0 and not _is_attacking:
			_do_attack()
			_attack_cd = attack_cooldown

func _do_attack() -> void:
	_is_attacking = true
	sprite.play("attack")

func _on_anim_finished() -> void:
	if sprite.animation == "attack":
		_is_attacking = false
		if sprite.animation != "idle":
			sprite.play("idle")

func _on_player_hit(area: Area2D) -> void:
	pass

func take_damage(amount: float, is_crit: bool = false) -> void:
	if _is_dead:
		return

	current_hp -= int(amount)

	if _player_ref:
		var knockback: Vector2 = (global_position - _player_ref.global_position).normalized() * 50.0
		velocity += knockback

	if current_hp <= 0:
		_die()

func _die() -> void:
	_is_dead = true
	queue_free()

	GameState.add_qi(5)
	GameState.add_spirit_stone(5)

	enemy_died.emit(self)
	CombatEvents.enemy_killed.emit(self)

func get_damage() -> float:
	return damage
