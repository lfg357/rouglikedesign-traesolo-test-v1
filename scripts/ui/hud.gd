extends CanvasLayer
## HUD 界面 · 血条/灵气/灵石

@onready var hp_bar_fill: Polygon2D = $HpPanel/HpBarFill
@onready var hp_bar_highlight: Polygon2D = $HpPanel/HpBarHighlight
@onready var hp_text: Label = $HpPanel/HpText
@onready var qi_bar_fill: Polygon2D = $QiPanel/QiBarFill
@onready var qi_text: Label = $QiPanel/QiText
@onready var stone_text: Label = $StonePanel/StoneText

var _max_hp_scale: float = 1.0
var _max_qi_scale: float = 1.0

func _ready() -> void:
	_max_hp_scale = hp_bar_fill.scale.x
	_max_qi_scale = qi_bar_fill.scale.x

	if GameState:
		GameState.currency_changed.connect(_on_currency_changed)
		_update_resources()

	var player: Node = get_tree().get_first_node_in_group("player")
	if player and player.has_signal("hp_changed"):
		player.hp_changed.connect(_on_hp_changed)
		_update_hp(player.current_hp, player.max_hp)

func _on_hp_changed(current: int, max_hp: int) -> void:
	_update_hp(current, max_hp)

func _update_hp(current: int, max_hp: int) -> void:
	var ratio: float = float(current) / float(max_hp) if max_hp > 0 else 0.0
	ratio = clamp(ratio, 0.0, 1.0)
	hp_bar_fill.scale.x = _max_hp_scale * ratio
	hp_bar_highlight.scale.x = _max_hp_scale * ratio
	hp_text.text = str(current) + " / " + str(max_hp)

	if ratio > 0.6:
		hp_bar_fill.color = Color(0.3, 0.75, 0.4, 0.95)
		hp_bar_highlight.color = Color(0.6, 0.95, 0.65, 0.3)
	elif ratio > 0.3:
		hp_bar_fill.color = Color(0.95, 0.75, 0.3, 0.95)
		hp_bar_highlight.color = Color(1, 0.9, 0.5, 0.3)
	else:
		hp_bar_fill.color = Color(0.85, 0.25, 0.2, 0.95)
		hp_bar_highlight.color = Color(1, 0.55, 0.45, 0.3)

func _on_currency_changed() -> void:
	_update_resources()

func _update_resources() -> void:
	if not GameState:
		return
	var qi: int = GameState.player_qi
	var max_qi: int = 100
	var ratio: float = float(qi) / float(max_qi) if max_qi > 0 else 0.0
	ratio = clamp(ratio, 0.0, 1.0)
	qi_bar_fill.scale.x = _max_qi_scale * ratio
	qi_text.text = "灵气: " + str(qi)
	stone_text.text = "灵石: " + str(GameState.player_spirit_stone)
