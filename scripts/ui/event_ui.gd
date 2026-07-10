extends CanvasLayer
## 事件界面 · 奇遇抉择

signal event_chosen(option_index: int)
signal event_closed()

@onready var title_label: Label = $Panel/VBox/Title
@onready var desc_label: Label = $Panel/VBox/DescLabel
@onready var options_container: VBoxContainer = $Panel/VBox/OptionsContainer
@onready var close_btn: Button = $Panel/VBox/CloseBtn

var _event_data: Dictionary = {}
var _is_setup: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_btn.pressed.connect(_on_close)
	if not _is_setup:
		_event_data = _default_event()
		_build()

func setup(event_data: Dictionary) -> void:
	_event_data = event_data
	_is_setup = true
	if is_inside_tree():
		_build()

func _build() -> void:
	for child in options_container.get_children():
		child.queue_free()
	title_label.text = _event_data.get("title", "")
	desc_label.text = _event_data.get("desc", "")
	var options: Array = _event_data.get("options", [])
	for i in range(options.size()):
		var option: Dictionary = options[i]
		var btn: Button = Button.new()
		btn.text = option.get("text", "")
		btn.add_theme_font_size_override("font_size", 20)
		btn.add_theme_color_override("font_color", Color(0.12, 0.1, 0.08, 1))
		btn.add_theme_color_override("font_hover_color", Color(0.75, 0.22, 0.15, 1))
		btn.custom_minimum_size = Vector2(0, 48)
		btn.pressed.connect(_on_option.bind(i))
		options_container.add_child(btn)

func _default_event() -> Dictionary:
	return {
		"title": "古碑奇遇",
		"desc": "你在迷雾中发现一块古碑，碑上刻有晦涩铭文。如何处置？",
		"options": [
			{"text": "参悟碑文（消耗30灵气，获遗物）", "outcome": "relic"},
			{"text": "汲取灵韵（获50灵气）", "outcome": "qi"},
			{"text": "离开", "outcome": "leave"},
		],
	}

## 获取指定选项的 outcome 字符串（供外部调用，避免访问私有 _event_data）
func get_outcome(index: int) -> String:
	var options: Array = _event_data.get("options", [])
	if index < 0 or index >= options.size():
		return ""
	return options[index].get("outcome", "")

func _on_option(index: int) -> void:
	event_chosen.emit(index)
	_on_close()

func _on_close() -> void:
	event_closed.emit()
	UIManager.close_top()
