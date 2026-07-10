extends CharacterBody2D
## 燕无归 · 身法近战（手感旗舰）
## 资源：Tiny RPG Soldier (100x100 统一帧尺寸)
## 动画：idle(6) / run(8) / light_attack(6) / heavy_attack(9) / hurt(4) / death(4)

class_name PlayerYan

@export var max_hp: int = 100
@export var move_speed: float = 230.0
var current_hp: int = 100

@export var dodge_distance: float = 150.0
@export var dodge_duration: float = 0.25
@export var dodge_iframes: float = 0.5
@export var dodge_cooldown: float = 1.2
var _dodge_cd_timer: float = 0.0
var _is_dodging: bool = false
var _dodge_dir: Vector2 = Vector2.ZERO
var _dodge_timer: float = 0.0

@export var combo_window: float = 2.5
var _combo_step: int = 0
var _combo_timer: float = 0.0
var _is_attacking: bool = false
var _attack_timer: float = 0.0
var _attack_duration: float = 0.3

const DASH_DURATION: float = 0.13
var _dash_timer: float = 0.0

@export var base_damage: float = 12.0
var _facing_dir: Vector2 = Vector2.RIGHT

var _iframes: float = 0.0

const SwordTrailScene: PackedScene = preload("res://scenes/effects/sword_trail.tscn")
const SlashBladeScene: PackedScene = preload("res://scenes/effects/slash_blade.tscn")

# 新素材 Tiny RPG Soldier 所有帧统一 100x100，角色脚底位置一致
# 无需帧间偏移补偿（旧 samurai 素材帧高 22~36 不一致才需要）
# 角色尺寸: 100x100 @ scale 1.5 → 150x150
# 手的位置: 角色中心偏上，约在 (facing_dir.x * 60, -20) 相对于角色原点

signal hp_changed(current: int, max_hp: int)
signal player_died()

@onready var sprite: AnimatedSprite2D = $Visual/AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var hurtbox: Area2D = $Hurtbox
@onready var afterimage_timer: Timer = $AfterimageTimer

func _ready() -> void:
	current_hp = max_hp
	add_to_group("player")
	sprite.play("idle")
	sprite.animation_finished.connect(_on_anim_finished)
	hurtbox.area_entered.connect(_on_enemy_attack_hit)
	hitbox.area_entered.connect(_on_hit_enemy)

func _physics_process(delta: float) -> void:
	_update_timers(delta)

	if _is_dodging:
		_process_dodge(delta)
	elif _dash_timer > 0:
		velocity = _facing_dir * move_speed * 2.0
	elif _is_attacking:
		_process_attack(delta)
		_idle_movement(delta * 0.3)
	else:
		_handle_input()
		_idle_movement(delta)

	move_and_slide()
	_update_anim()
	z_index = int(global_position.y)

func _update_anim() -> void:
	if _is_attacking:
		return
	if _is_dodging:
		return
	if velocity.length() > 30.0:
		_play_anim("run")
	else:
		_play_anim("idle")

func _play_anim(anim: String) -> void:
	if sprite.animation == anim:
		return
	sprite.stop()
	sprite.play(anim)

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

func _handle_input() -> void:
	if Input.is_action_just_pressed("attack"):
		_start_attack()

	if Input.is_action_just_pressed("dodge") and _dodge_cd_timer <= 0:
		_start_dodge()

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

func _start_attack() -> void:
	_is_attacking = true
	_attack_timer = _attack_duration
	_combo_timer = combo_window

	match _combo_step:
		0:
			_attack_duration = 0.32
			_play_anim("light_attack")
			_spawn_sword_trail(0.05)
		1:
			_attack_duration = 0.32
			_play_anim("light_attack")
			_spawn_sword_trail(0.10)
		2:
			_attack_duration = 0.55
			_play_anim("heavy_attack")
			_spawn_sword_trail(0.15)
			_dash_on_third_hit()

	_update_hitbox_position()

func _spawn_sword_trail(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if not is_inside_tree():
		return
	
	var is_right: bool = _facing_dir.x > 0
	var dir_x: float = 1.0 if is_right else -1.0
	
	# 刀光出手位置：角色手的位置，稍偏上
	var hand_pos: Vector2 = global_position + Vector2(dir_x * 45, -25)
	var attack_dir: Vector2 = Vector2(dir_x, 0)
	
	# 生成主刀光（月牙形，有厚度）
	var blade: Node2D = SlashBladeScene.instantiate()
	blade.setup(hand_pos, attack_dir, 110.0, 45.0, 0.22)
	get_parent().add_child(blade)
	
	# 剑光拖尾（刀光末端，强化打击感）
	var trail: Node2D = SwordTrailScene.instantiate()
	trail.global_position = hand_pos + attack_dir * 60 + Vector2(0, -5)
	trail.scale = Vector2(2.5, 2.5)
	if not is_right:
		trail.scale.x *= -1
	get_parent().add_child(trail)

func _process_attack(delta: float) -> void:
	_attack_timer -= delta
	if _attack_timer <= 0:
		_is_attacking = false
		_combo_step = (_combo_step + 1) % 3

func _on_anim_finished() -> void:
	if sprite.animation == "light_attack" or sprite.animation == "heavy_attack":
		if _is_attacking:
			return
		_play_anim("idle")

func _update_hitbox_position() -> void:
	hitbox.position = _facing_dir * 50.0

func _dash_on_third_hit() -> void:
	_dash_timer = DASH_DURATION
	velocity = _facing_dir * move_speed * 2.0

func _start_dodge() -> void:
	_is_dodging = true
	_dodge_timer = dodge_duration
	_dodge_cd_timer = dodge_cooldown
	_iframes = dodge_iframes

	var input_dir: Vector2 = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()

	_dodge_dir = input_dir if input_dir.length() > 0.1 else _facing_dir

	CombatEvents.dodge_success.emit(global_position)

func _process_dodge(delta: float) -> void:
	_dodge_timer -= delta
	var speed: float = dodge_distance / dodge_duration
	velocity = _dodge_dir * speed

	if _dodge_timer <= 0:
		_is_dodging = false
		velocity = Vector2.ZERO

func _on_hit_enemy(area: Area2D) -> void:
	if not _is_attacking:
		return

	var target: Node = area.get_parent()
	if target == self:
		return
	if not target.is_in_group("enemy"):
		return

	var damage: float = base_damage * GameState.stats.damage_mul
	var is_crit: bool = randf() < GameState.stats.crit_chance
	if is_crit:
		damage *= GameState.stats.crit_damage

	# 命中迸发：在命中点生成一个刀光爆发效果
	_spawn_hit_burst(area.global_position, is_crit)

	CombatEvents.trigger_hit(area.global_position, damage, is_crit, "water")

	if GameState.stats.lifesteal > 0:
		heal(int(damage * GameState.stats.lifesteal))

	if target.has_method("take_damage"):
		target.take_damage(damage, is_crit)

func _spawn_hit_burst(pos: Vector2, is_crit: bool) -> void:
	var burst: Node2D = SlashBladeScene.instantiate()
	var burst_dir: Vector2 = _facing_dir
	var burst_len: float = 60.0 if not is_crit else 100.0
	var burst_thick: float = 30.0 if not is_crit else 50.0
	burst.setup(pos, burst_dir, burst_len, burst_thick, 0.15)
	burst.scale *= 1.2 if is_crit else 0.8
	get_parent().add_child(burst)

func _on_enemy_attack_hit(area: Area2D) -> void:
	if _iframes > 0:
		return

	var damage: float = 10.0
	if area.has_method("get_damage"):
		damage = area.get_damage()

	damage *= (1.0 - GameState.stats.damage_reduce)
	take_damage(int(damage))

func take_damage(amount: int) -> void:
	if _iframes > 0:
		return

	current_hp -= amount
	current_hp = max(0, current_hp)
	hp_changed.emit(current_hp, max_hp)
	CombatEvents.player_damaged.emit(amount)

	_iframes = 0.3

	if current_hp <= 0:
		_die()

func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + amount)
	hp_changed.emit(current_hp, max_hp)

func _die() -> void:
	player_died.emit()
	set_physics_process(false)

func _process(delta: float) -> void:
	if GameState.stats.hp_regen > 0 and current_hp > 0:
		heal(int(GameState.stats.hp_regen * delta))
