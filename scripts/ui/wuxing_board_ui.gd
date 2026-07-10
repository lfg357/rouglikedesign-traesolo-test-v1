extends CanvasLayer
## 五行盘界面 · 5 槽位按五边形排列
## 点击空槽位放置测试遗物，点击已填充槽位移除遗物
## 监听 WuxingBoard.board_changed 刷新显示

const _ELEMENT_COLORS: Dictionary = {
	"gold": Color(0.85, 0.75, 0.4, 0.55),
	"water": Color(0.3, 0.5, 0.8, 0.55),
	"wood": Color(0.3, 0.7, 0.4, 0.55),
	"fire": Color(0.8, 0.3, 0.25, 0.55),
	"earth": Color(0.55, 0.45, 0.3, 0.55),
}

var _slots: Array = []
var _summary_label: Label
var _close_btn: Button
var _relic_cursor: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_slots = [
		$Panel/Slot0,
		$Panel/Slot1,
		$Panel/Slot2,
		$Panel/Slot3,
		$Panel/Slot4,
	]
	_summary_label = $Panel/SummaryLabel
	_close_btn = $Panel/CloseBtn
	for i in range(5):
		if _slots[i] != null:
			_slots[i].pressed.connect(_on_slot_pressed.bind(i))
	if _close_btn:
		_close_btn.pressed.connect(_on_close)
	if WuxingBoard and WuxingBoard.has_signal("board_changed"):
		WuxingBoard.board_changed.connect(_refresh)
	_refresh()

func _on_slot_pressed(idx: int) -> void:
	if WuxingBoard == null:
		return
	if idx < 0 or idx >= 5:
		return
	if WuxingBoard.slots[idx] == "":
		_place_next_relic(idx)
	else:
		WuxingBoard.remove_relic(idx)

func _place_next_relic(idx: int) -> void:
	if RelicDB == null or RelicDB.relics.is_empty():
		return
	var placed: Array = []
	for s in WuxingBoard.slots:
		if s != "":
			placed.append(s)
	# 优先选一个未放置的遗物
	var relic_id: String = ""
	for id in RelicDB.relics.keys():
		if not id in placed:
			relic_id = id
			break
	if relic_id == "":
		# 全部已放置时循环放置测试遗物
		var all_ids: Array = RelicDB.relics.keys()
		relic_id = all_ids[_relic_cursor % all_ids.size()]
		_relic_cursor += 1
	var r: Dictionary = RelicDB.get_relic(relic_id)
	var element: String = str(r.get("element", WuxingBoard.SLOT_DEFAULT_ELEMENT[idx]))
	WuxingBoard.place_relic(idx, relic_id, element)

func _refresh() -> void:
	if WuxingBoard == null:
		return
	for i in range(5):
		if i >= _slots.size() or _slots[i] == null:
			continue
		var elem: String = WuxingBoard.SLOT_DEFAULT_ELEMENT[i]
		var elem_cn: String = str(WuxingBoard.ELEMENT_CN.get(elem, elem))
		var relic_id: String = WuxingBoard.slots[i]
		if relic_id == "":
			_slots[i].text = elem_cn + "（空）"
		else:
			var r: Dictionary = RelicDB.get_relic(relic_id) if RelicDB else {}
			var name_str: String = str(r.get("name", relic_id))
			_slots[i].text = elem_cn + " · " + name_str
		_apply_slot_style(_slots[i], elem)
	# 乘数总览
	var summary: Dictionary = WuxingBoard.get_board_summary()
	var filled: int = int(summary.get("filled_slots", 0))
	var sheng: int = int(summary.get("sheng_edges", 0))
	var ke: int = int(summary.get("ke_edges", 0))
	var elems: Array = summary.get("elements", [])
	var elems_cn: String = ""
	for e in elems:
		elems_cn += str(WuxingBoard.ELEMENT_CN.get(e, e)) + " "
	if elems_cn == "":
		elems_cn = "无"
	if _summary_label:
		_summary_label.text = "已填充：%d/5   相生边：%d (×1.5)   相克边：%d (×0.5)\n已激活五行：%s" % [filled, sheng, ke, elems_cn]

func _apply_slot_style(btn: Button, element: String) -> void:
	if btn == null:
		return
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = _ELEMENT_COLORS.get(element, Color(0.5, 0.5, 0.5, 0.5))
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.12, 0.1, 0.08, 0.9)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_right = 6
	sb.corner_radius_bottom_left = 6
	btn.add_theme_stylebox_override("normal", sb)
	var sb_hover: StyleBoxFlat = sb.duplicate()
	sb_hover.border_color = Color(0.75, 0.22, 0.15, 1)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_hover)

func _on_close() -> void:
	UIManager.close_top()
