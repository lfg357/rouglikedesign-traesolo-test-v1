extends CanvasLayer
## 遗物选择界面 · 天机赐宝
## 三选一

signal relic_chosen(relic_id: String)

const ELEMENT_COLORS: Dictionary = {
	"gold": Color(0.85, 0.75, 0.3, 1),
	"water": Color(0.3, 0.6, 0.9, 1),
	"wood": Color(0.3, 0.7, 0.3, 1),
	"fire": Color(0.9, 0.4, 0.2, 1),
	"earth": Color(0.6, 0.5, 0.3, 1),
	"none": Color(0.5, 0.5, 0.5, 1),
}

const ELEMENT_NAMES: Dictionary = {
	"gold": "金",
	"water": "水",
	"wood": "木",
	"fire": "火",
	"earth": "土",
	"none": "无",
}

const RARITY_COLORS: Array = [
	Color(0.8, 0.8, 0.8, 1),
	Color(0.4, 0.6, 0.95, 1),
	Color(0.7, 0.4, 0.9, 1),
	Color(0.9, 0.75, 0.3, 1),
]

@onready var card_container: HBoxContainer = $Panel/VBox/CardContainer

var _relic_ids: Array = []
var _is_setup: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not _is_setup:
		_relic_ids = RelicDB.get_relic_choice(3)
	_build_cards()

func setup(relic_ids: Array) -> void:
	_relic_ids = relic_ids
	_is_setup = true
	if is_inside_tree():
		_build_cards()

func _build_cards() -> void:
	for child in card_container.get_children():
		child.queue_free()
	for relic_id in _relic_ids:
		var card: Panel = _create_card(relic_id)
		card_container.add_child(card)

func _create_card(relic_id: String) -> Panel:
	var relic: Dictionary = RelicDB.get_relic(relic_id)
	var panel: Panel = Panel.new()
	panel.custom_minimum_size = Vector2(320, 400)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(_on_card_input.bind(relic_id))

	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.93, 0.9, 0.83, 0.9)
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	var rarity: int = relic.get("rarity", 0)
	sb.border_color = RARITY_COLORS[rarity] if rarity < RARITY_COLORS.size() else Color(0.8, 0.8, 0.8, 1)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left = 8
	sb.content_margin_left = 16.0
	sb.content_margin_top = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_bottom = 16.0
	panel.add_theme_stylebox_override("panel", sb)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var name_label: Label = Label.new()
	name_label.text = relic.get("name", "???")
	name_label.add_theme_font_size_override("font_size", 26)
	name_label.add_theme_color_override("font_color", RARITY_COLORS[rarity] if rarity < RARITY_COLORS.size() else Color(0.8, 0.8, 0.8, 1))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)

	var element: String = relic.get("element", "none")
	var elem_label: Label = Label.new()
	elem_label.text = "五行: " + ELEMENT_NAMES.get(element, "无")
	elem_label.add_theme_font_size_override("font_size", 20)
	elem_label.add_theme_color_override("font_color", ELEMENT_COLORS.get(element, Color(0.5, 0.5, 0.5, 1)))
	elem_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elem_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(elem_label)

	var sep: HSeparator = HSeparator.new()
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sep)

	var desc_label: Label = Label.new()
	desc_label.text = relic.get("desc", "")
	desc_label.add_theme_font_size_override("font_size", 18)
	desc_label.add_theme_color_override("font_color", Color(0.2, 0.18, 0.15, 1))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(desc_label)

	var stats: Dictionary = relic.get("stats", {})
	if not stats.is_empty():
		var stats_label: Label = Label.new()
		var stats_text: String = "属性加成:\n"
		for key in stats:
			stats_text += _format_stat(key, stats[key]) + "\n"
		stats_label.text = stats_text.strip_edges()
		stats_label.add_theme_font_size_override("font_size", 16)
		stats_label.add_theme_color_override("font_color", Color(0.4, 0.35, 0.25, 1))
		stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(stats_label)

	return panel

func _format_stat(key: String, value: float) -> String:
	var pct: String = "%"
	match key:
		"damage_mul": return "攻击力 +" + str(int(value * 100)) + pct
		"move_mul": return "移速 +" + str(int(value * 100)) + pct
		"crit_chance": return "暴击率 +" + str(int(value * 100)) + pct
		"crit_damage": return "暴击伤害 +" + str(int(value * 100)) + pct
		"max_hp_pct": return "最大生命 +" + str(int(value * 100)) + pct
		"damage_reduce": return "减伤 +" + str(int(value * 100)) + pct
		"lifesteal": return "吸血 +" + str(int(value * 100)) + pct
		"hp_regen": return "每秒回血 +" + str(value)
		"qi_mult": return "灵气获取 +" + str(int(value * 100)) + pct
		_: return key + " +" + str(value)

func _on_card_input(event: InputEvent, relic_id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_choose_relic(relic_id)

func _choose_relic(relic_id: String) -> void:
	relic_chosen.emit(relic_id)
	UIManager.close_top()
