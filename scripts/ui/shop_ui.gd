extends CanvasLayer
## 商店界面 · 卦摊
## 进入 SHOP 房间时弹出，消费灵气/灵石购买商品

var _shop: ShopSystem = null
var _item_rows: Dictionary = {}
var _purchased: Dictionary = {}

@onready var qi_label: Label = $Panel/VBox/CurrencyBar/QiLabel
@onready var stone_label: Label = $Panel/VBox/CurrencyBar/StoneLabel
@onready var karma_label: Label = $Panel/VBox/CurrencyBar/KarmaLabel
@onready var item_list: VBoxContainer = $Panel/VBox/ScrollContainer/ItemList
@onready var msg_label: Label = $Panel/VBox/MsgLabel
@onready var leave_btn: Button = $Panel/VBox/LeaveBtn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_shop = ShopSystem.new()
	add_child(_shop)
	_shop.purchase_successful.connect(_on_purchase_success)
	_shop.purchase_failed.connect(_on_purchase_failed)
	leave_btn.pressed.connect(_on_leave)
	GameState.currency_changed.connect(_update_currency)
	_build_items()
	_update_currency()

func _build_items() -> void:
	for child in item_list.get_children():
		child.queue_free()
	_item_rows.clear()
	var all_items: Array = _shop.qi_items + _shop.stone_items
	for item in all_items:
		var row: Panel = _create_item_row(item)
		item_list.add_child(row)

func _create_item_row(item: Dictionary) -> Panel:
	var panel: Panel = Panel.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.88, 0.84, 0.76, 0.5)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.12, 0.1, 0.08, 0.4)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_bottom_left = 4
	sb.content_margin_left = 10.0
	sb.content_margin_top = 8.0
	sb.content_margin_right = 10.0
	sb.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(820, 72)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	var left_vbox: VBoxContainer = VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(left_vbox)

	var name_label: Label = Label.new()
	name_label.text = item.name
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(0.12, 0.1, 0.08, 1))
	left_vbox.add_child(name_label)

	var desc_label: Label = Label.new()
	desc_label.text = item.desc
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color(0.3, 0.27, 0.22, 1))
	left_vbox.add_child(desc_label)

	var right_vbox: VBoxContainer = VBoxContainer.new()
	right_vbox.custom_minimum_size = Vector2(160, 0)
	right_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	right_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(right_vbox)

	var price: int = _shop.get_price(item.id)
	var price_label: Label = Label.new()
	price_label.text = str(price) + " " + _currency_name(item.currency)
	price_label.add_theme_font_size_override("font_size", 18)
	price_label.add_theme_color_override("font_color", _currency_color(item.currency))
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_vbox.add_child(price_label)

	var buy_btn: Button = Button.new()
	buy_btn.text = "购买"
	buy_btn.add_theme_font_size_override("font_size", 18)
	buy_btn.add_theme_color_override("font_color", Color(0.12, 0.1, 0.08, 1))
	buy_btn.add_theme_color_override("font_hover_color", Color(0.75, 0.22, 0.15, 1))
	buy_btn.pressed.connect(_on_buy.bind(item.id))
	right_vbox.add_child(buy_btn)

	_item_rows[item.id] = {"button": buy_btn}
	return panel

func _currency_name(currency: String) -> String:
	match currency:
		"qi": return "灵气"
		"stone": return "灵石"
		"karma": return "业力"
		_: return ""

func _currency_color(currency: String) -> Color:
	match currency:
		"qi": return Color(0.4, 0.7, 0.95, 1)
		"stone": return Color(0.95, 0.8, 0.3, 1)
		"karma": return Color(0.75, 0.65, 0.45, 1)
		_: return Color(0.12, 0.1, 0.08, 1)

func _on_buy(item_id: String) -> void:
	_shop.buy_item(item_id)

func _on_purchase_success(item_id: String) -> void:
	_purchased[item_id] = true
	if _item_rows.has(item_id):
		var btn: Button = _item_rows[item_id].button
		btn.disabled = true
		btn.text = "已购"
	msg_label.add_theme_color_override("font_color", Color(0.3, 0.7, 0.3, 1))
	msg_label.text = "购买成功"
	_update_currency()

func _on_purchase_failed(reason: String) -> void:
	msg_label.add_theme_color_override("font_color", Color(0.75, 0.22, 0.15, 1))
	msg_label.text = "购买失败: " + reason

func _update_currency() -> void:
	qi_label.text = "灵气: " + str(GameState.player_qi)
	stone_label.text = "灵石: " + str(GameState.player_spirit_stone)
	karma_label.text = "业力: " + str(GameState.player_karma)

func _on_leave() -> void:
	UIManager.close_top()
