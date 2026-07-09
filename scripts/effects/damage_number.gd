extends Node2D
## 伤害飘字 · 弹跳+淡出

@onready var label: Label = $Label

var _pending_dmg: int = 0
var _pending_crit: bool = false
var _setup_done: bool = false

func setup(dmg: int, is_crit: bool) -> void:
	_pending_dmg = dmg
	_pending_crit = is_crit
	_setup_done = true
	if is_inside_tree():
		_apply_setup()

func _ready() -> void:
	if _setup_done:
		_apply_setup()

func _apply_setup() -> void:
	if _pending_crit:
		label.modulate = Color(1, 0.85, 0.2, 1)
		label.add_theme_font_size_override("font_size", 32)
		label.add_theme_color_override("font_outline_color", Color(0.5, 0.2, 0, 1))
		label.text = str(_pending_dmg) + "!"
		scale = Vector2(1.5, 1.5)
	else:
		label.modulate = Color(1, 1, 0.9, 1)
		label.add_theme_font_size_override("font_size", 22)
		label.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.08, 1))
		label.text = str(_pending_dmg)
		scale = Vector2(1.2, 1.2)
	
	label.add_theme_constant_override("outline_size", 5)
	
	var t := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12)
	t.parallel().tween_property(self, "position:y", position.y - 50, 0.5)
	
	var t2 := create_tween().set_trans(Tween.TRANS_LINEAR)
	t2.tween_interval(0.35)
	t2.tween_property(label, "modulate:a", 0, 0.3)
	t2.tween_callback(queue_free)
