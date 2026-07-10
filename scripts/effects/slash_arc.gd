extends Node2D

@onready var trail: AnimatedSprite2D = $Trail

var _start_pos: Vector2 = Vector2.ZERO
var _arc_center: Vector2 = Vector2.ZERO
var _arc_radius: float = 60.0
var _start_angle: float = 0.0
var _end_angle: float = PI
var _duration: float = 0.3
var _timer: float = 0.0
var _scale_factor: float = 2.5

func setup(start_pos: Vector2, center: Vector2, radius: float, duration: float, is_right: bool, scale_factor: float = 2.5) -> void:
	_start_pos = start_pos
	_arc_center = center
	_arc_radius = radius
	_duration = duration
	_scale_factor = scale_factor
	scale = Vector2(_scale_factor, _scale_factor)
	if not is_right:
		scale.x *= -1
	
	_start_angle = PI * 0.75
	_end_angle = PI * 1.75
	if not is_right:
		_start_angle = PI * 0.25
		_end_angle = PI * 1.25
	
	trail.play("slash")
	
	position = _start_pos + _get_arc_point(0)

func _get_arc_point(t: float) -> Vector2:
	var angle: float = _start_angle + (_end_angle - _start_angle) * t
	return Vector2(cos(angle), sin(angle)) * _arc_radius

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= _duration:
		queue_free()
		return
	
	var t: float = _timer / _duration
	position = _start_pos + _get_arc_point(t)
	
	var angle: float = _start_angle + (_end_angle - _start_angle) * t + PI * 0.5
	rotation = angle
	
	var fade: float = max(0.0, 1.0 - t * 1.5)
	trail.modulate.a = fade
