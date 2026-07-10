extends Node2D

@onready var blade: Polygon2D = $Blade
@onready var outer_glow: Polygon2D = $OuterGlow
@onready var inner_core: Polygon2D = $InnerCore

var _start_pos: Vector2 = Vector2.ZERO
var _dir: Vector2 = Vector2.RIGHT
var _blade_length: float = 100.0
var _blade_thickness: float = 40.0
var _duration: float = 0.2
var _timer: float = 0.0
var _is_right: bool = true

func setup(start_pos: Vector2, direction: Vector2, length: float, thickness: float, duration: float) -> void:
	_start_pos = start_pos
	_dir = direction.normalized()
	_blade_length = length
	_blade_thickness = thickness
	_duration = duration
	_is_right = _dir.x > 0
	
	position = _start_pos
	rotation = _dir.angle()
	
	_build_blade_shape()

func _build_blade_shape() -> void:
	var half_len: float = _blade_length * 0.5
	var half_thick: float = _blade_thickness * 0.5
	
	var blade_points: PackedVector2Array = PackedVector2Array([
		Vector2(-half_len * 0.3, -half_thick * 0.3),
		Vector2(-half_len * 0.1, -half_thick),
		Vector2(half_len * 0.5, -half_thick * 0.8),
		Vector2(half_len, -half_thick * 0.3),
		Vector2(half_len, half_thick * 0.3),
		Vector2(half_len * 0.5, half_thick * 0.8),
		Vector2(-half_len * 0.1, half_thick),
		Vector2(-half_len * 0.3, half_thick * 0.3)
	])
	blade.polygon = blade_points
	
	var glow_points: PackedVector2Array = PackedVector2Array([
		Vector2(-half_len * 0.2, -half_thick * 1.3),
		Vector2(half_len * 0.6, -half_thick * 1.5),
		Vector2(half_len * 1.1, -half_thick * 0.5),
		Vector2(half_len * 1.1, half_thick * 0.5),
		Vector2(half_len * 0.6, half_thick * 1.5),
		Vector2(-half_len * 0.2, half_thick * 1.3)
	])
	outer_glow.polygon = glow_points
	
	var core_points: PackedVector2Array = PackedVector2Array([
		Vector2(-half_len * 0.2, -half_thick * 0.15),
		Vector2(half_len * 0.4, -half_thick * 0.3),
		Vector2(half_len * 0.9, -half_thick * 0.1),
		Vector2(half_len * 0.9, half_thick * 0.1),
		Vector2(half_len * 0.4, half_thick * 0.3),
		Vector2(-half_len * 0.2, half_thick * 0.15)
	])
	inner_core.polygon = core_points

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= _duration:
		queue_free()
		return
	
	var t: float = _timer / _duration
	
	var move_dist: float = _blade_length * 0.6
	position = _start_pos + _dir * move_dist * t
	
	var grow: float = 1.0
	if t < 0.2:
		grow = t / 0.2
	elif t > 0.7:
		grow = max(0.0, (1.0 - t) / 0.3)
	
	blade.scale = Vector2(1.0, grow)
	outer_glow.scale = Vector2(1.0, grow)
	inner_core.scale = Vector2(1.0, grow)
	
	var fade: float = 1.0
	if t > 0.6:
		fade = max(0.0, (1.0 - t) / 0.4)
	blade.modulate.a = fade * 0.9
	outer_glow.modulate.a = fade * 0.5
	inner_core.modulate.a = fade
