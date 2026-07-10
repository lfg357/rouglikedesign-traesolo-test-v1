extends Node
## 打击感管理器 · 落墨即杀
## 监听 CombatEvents，统一处理命中反馈：
## 1. Hit Stop（命中顿帧）
## 2. 屏幕震动
## 3. 水墨迸发粒子
## 4. 伤害飘字

@onready var camera: Camera2D
var _hit_stop_end_msec: int = 0
var _shake_intensity: float = 0.0
var _shake_timer: float = 0.0

const HitInkEffect: PackedScene = preload("res://scenes/effects/hit_ink_effect.tscn")
const DamageNumber: PackedScene = preload("res://scenes/effects/damage_number.tscn")

func _ready() -> void:
	CombatEvents.hit_occurred.connect(_on_hit)
	CombatEvents.critical_strike.connect(_on_crit)
	CombatEvents.player_damaged.connect(_on_player_damaged)

func _process(delta: float) -> void:
	var now: int = Time.get_ticks_msec()
	if now < _hit_stop_end_msec:
		Engine.time_scale = 0.01
	else:
		Engine.time_scale = 1.0

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

func setup_camera(cam: Camera2D) -> void:
	camera = cam

func _on_hit(position: Vector2, damage: float, is_crit: bool, element: String) -> void:
	var stop_duration: float = 0.08
	if is_crit:
		stop_duration = 0.18
	_trigger_hit_stop(stop_duration)
	
	var shake: float = 5.0
	if is_crit:
		shake = 12.0
	_trigger_shake(shake, 0.2)
	
	_spawn_ink_burst(position, element, is_crit)
	_spawn_damage_number(position, damage, is_crit)
	_flash_screen(is_crit)

func _on_crit(position: Vector2) -> void:
	pass

func _on_player_damaged(damage: float) -> void:
	_trigger_shake(5.0, 0.2)

func _trigger_hit_stop(duration: float) -> void:
	var end_msec: int = Time.get_ticks_msec() + int(duration * 1000)
	if end_msec > _hit_stop_end_msec:
		_hit_stop_end_msec = end_msec

func _trigger_shake(intensity: float, duration: float) -> void:
	if intensity > _shake_intensity:
		_shake_intensity = intensity
	_shake_timer = max(_shake_timer, duration)

func _flash_screen(is_crit: bool) -> void:
	var flash: ColorRect = ColorRect.new()
	flash.color = Color(1.0, 1.0, 1.0, 0.15 if not is_crit else 0.3)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if camera and camera.get_parent():
		camera.get_parent().add_child(flash)
		var tween: Tween = flash.create_tween()
		tween.tween_property(flash, "modulate:a", 0.0, 0.08)
		tween.tween_callback(flash.queue_free)

func _spawn_ink_burst(position: Vector2, element: String, is_crit: bool) -> void:
	var effect: Node2D = HitInkEffect.instantiate()
	effect.global_position = position
	if is_crit:
		effect.scale = Vector2(2.5, 2.5)
	else:
		effect.scale = Vector2(1.5, 1.5)
	if camera and camera.get_parent():
		camera.get_parent().add_child(effect)
	elif get_tree().current_scene:
		get_tree().current_scene.add_child(effect)

func _spawn_damage_number(position: Vector2, damage: float, is_crit: bool) -> void:
	var dmg: Node2D = DamageNumber.instantiate()
	dmg.global_position = position + Vector2(randf_range(-10, 10), randf_range(-20, -10))
	if dmg.has_method("setup"):
		dmg.setup(int(damage), is_crit)
	if camera and camera.get_parent():
		camera.get_parent().add_child(dmg)
	elif get_tree().current_scene:
		get_tree().current_scene.add_child(dmg)
