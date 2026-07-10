extends Node
## UI 管理器 · 统一管理所有交互式界面
## 职责：界面栈管理、游戏暂停、界面实例化与切换
## 所有界面通过 open_ui / close_ui / toggle_ui 调用

# ─── 界面场景注册 ───
const UI_SCENES: Dictionary = {
	"main_menu": preload("res://scenes/ui/main_menu.tscn"),
	"pause_menu": preload("res://scenes/ui/pause_menu.tscn"),
	"settings": preload("res://scenes/ui/settings.tscn"),
	"death_screen": preload("res://scenes/ui/death_screen.tscn"),
	"floor_clear": preload("res://scenes/ui/floor_clear.tscn"),
	"relic_select": preload("res://scenes/ui/relic_select.tscn"),
	"shop_ui": preload("res://scenes/ui/shop_ui.tscn"),
	"wuxing_board": preload("res://scenes/ui/wuxing_board_ui.tscn"),
	"inventory": preload("res://scenes/ui/inventory_ui.tscn"),
}

# ─── 界面栈 ───
# 栈底=最底层界面，栈顶=当前活动界面
# 每次只显示栈顶，其余隐藏
var _ui_stack: Array = []  # 存 CanvasLayer 实例
var _instances: Dictionary = {}  # name → CanvasLayer 实例缓存

# 哪些界面会暂停游戏
const PAUSING_UIS: Array = ["main_menu", "pause_menu", "settings", "death_screen", "floor_clear", "relic_select", "shop_ui", "wuxing_board", "inventory"]

signal ui_opened(ui_name: String)
signal ui_closed(ui_name: String)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

# ─── 打开界面 ───
func open_ui(ui_name: String) -> void:
	if not UI_SCENES.has(ui_name):
		push_warning("UIManager: 未知界面 " + ui_name)
		return

	# 已在栈中则置顶
	if _instances.has(ui_name):
		var existing: CanvasLayer = _instances[ui_name]
		if is_instance_valid(existing):
			existing.show()
			_ui_stack.erase(ui_name)
			_ui_stack.append(ui_name)
			_apply_pause()
			return

	# 实例化新界面
	var instance: CanvasLayer = UI_SCENES[ui_name].instantiate()
	add_child(instance)
	_instances[ui_name] = instance
	_ui_stack.append(ui_name)
	_apply_pause()
	ui_opened.emit(ui_name)

# ─── 关闭界面 ───
func close_ui(ui_name: String) -> void:
	if not _instances.has(ui_name):
		return
	var instance: CanvasLayer = _instances[ui_name]
	if is_instance_valid(instance):
		instance.queue_free()
	_instances.erase(ui_name)
	_ui_stack.erase(ui_name)
	_apply_pause()
	ui_closed.emit(ui_name)

# ─── 切换界面（开/关） ───
func toggle_ui(ui_name: String) -> void:
	if _instances.has(ui_name) and is_instance_valid(_instances[ui_name]):
		close_ui(ui_name)
	else:
		open_ui(ui_name)

# ─── 关闭栈顶界面 ───
func close_top() -> void:
	if _ui_stack.is_empty():
		return
	close_ui(_ui_stack[-1])

# ─── 关闭所有界面 ───
func close_all() -> void:
	for ui_name in _ui_stack.duplicate():
		close_ui(ui_name)

# ─── 检查界面是否打开 ───
func is_ui_open(ui_name: String) -> bool:
	return _instances.has(ui_name) and is_instance_valid(_instances[ui_name])

# ─── 检查是否有任意界面打开 ───
func has_ui_open() -> bool:
	return not _ui_stack.is_empty()

# ─── 获取界面实例 ───
func get_ui(ui_name: String) -> CanvasLayer:
	if _instances.has(ui_name):
		return _instances[ui_name]
	return null

# ─── 暂停控制 ───
func _apply_pause() -> void:
	var should_pause: bool = false
	for ui_name in _ui_stack:
		if ui_name in PAUSING_UIS:
			should_pause = true
			break
	get_tree().paused = should_pause

# ─── Esc 返回（关闭栈顶） ───
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if has_ui_open():
			close_top()
			get_viewport().set_input_as_handled()
