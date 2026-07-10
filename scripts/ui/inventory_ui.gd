extends CanvasLayer
## 背包界面 · 持有遗物列表 + 选中遗物详情
## P0：GameState.inventory 暂未定义，用本地变量列出 RelicDB 全部遗物作为演示

var _relic_list: ItemList
var _detail_label: Label
var _close_btn: Button

var _relic_ids: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_relic_list = $Panel/HBox/LeftPanel/RelicList
	_detail_label = $Panel/HBox/RightPanel/DetailLabel
	_close_btn = $Panel/CloseBtn
	if _relic_list:
		_relic_list.item_selected.connect(_on_item_selected)
	if _close_btn:
		_close_btn.pressed.connect(_on_close)
	if WuxingBoard and WuxingBoard.has_signal("board_changed"):
		WuxingBoard.board_changed.connect(_on_board_changed)
	_populate_list()

func _populate_list() -> void:
	if _relic_list == null:
		return
	_relic_list.clear()
	_relic_ids = []
	if RelicDB and RelicDB.relics.size() > 0:
		for relic_id in RelicDB.relics.keys():
			_relic_ids.append(relic_id)
			var r: Dictionary = RelicDB.relics[relic_id]
			_relic_list.add_item(str(r.get("name", relic_id)))
	if _relic_ids.size() > 0:
		_relic_list.select(0)
		_show_detail(0)
	elif _detail_label:
		_detail_label.text = "行囊空空如也"

func _on_item_selected(index: int) -> void:
	_show_detail(index)

func _show_detail(index: int) -> void:
	if _detail_label == null:
		return
	if index < 0 or index >= _relic_ids.size():
		_detail_label.text = ""
		return
	var relic_id: String = _relic_ids[index]
	var r: Dictionary = RelicDB.get_relic(relic_id) if RelicDB else {}
	if r.is_empty():
		_detail_label.text = "无信息"
		return
	var element_str: String = "无"
	if WuxingBoard:
		element_str = str(WuxingBoard.ELEMENT_CN.get(r.get("element", "none"), "无"))
	var rarity_str: String = _rarity_name(int(r.get("rarity", 0)))
	var stats_str: String = _format_stats(r.get("stats", {}))
	var placed: bool = false
	if WuxingBoard and relic_id in WuxingBoard.slots:
		placed = true
	var text: String = "【%s】\n\n" % str(r.get("name", relic_id))
	text += "描述：%s\n" % str(r.get("desc", ""))
	text += "五行：%s\n" % element_str
	text += "稀有度：%s\n" % rarity_str
	text += "属性：%s" % stats_str
	if placed:
		text += "\n\n（已放置于五行盘）"
	_detail_label.text = text

func _rarity_name(rarity: int) -> String:
	match rarity:
		0:
			return "凡品（白）"
		1:
			return "灵品（蓝）"
		2:
			return "玄品（紫）"
		3:
			return "仙品（金）"
		_:
			return "未知"

func _format_stats(stats: Dictionary) -> String:
	if stats.is_empty():
		return "无"
	var names: Dictionary = {
		"damage_mul": "伤害倍率",
		"move_mul": "移速",
		"crit_chance": "暴击率",
		"crit_damage": "暴伤",
		"max_hp_pct": "最大生命",
		"damage_reduce": "减伤",
		"lifesteal": "吸血",
		"hp_regen": "回血",
		"qi_mult": "灵气获取",
	}
	var pct_keys: Array = ["damage_mul", "move_mul", "crit_chance", "crit_damage", "max_hp_pct", "damage_reduce", "qi_mult"]
	var parts: Array = []
	for key in stats:
		var label: String = names.get(key, key)
		var val = stats[key]
		if key in pct_keys:
			parts.append("%s +%.0f%%" % [label, float(val) * 100.0])
		else:
			parts.append("%s +%s" % [label, str(val)])
	return "，".join(parts)

func _on_board_changed() -> void:
	if _relic_list == null:
		return
	var selected: Array = _relic_list.get_selected_items()
	if selected.size() > 0:
		_show_detail(selected[0])

func _on_close() -> void:
	UIManager.close_top()
