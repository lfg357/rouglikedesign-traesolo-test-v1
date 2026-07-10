extends CanvasLayer
## 小地图界面 · 楼层布局

# NodeType 常量（与 LabyrinthGen.NodeType 整数值对应，避免依赖外部 enum）
const NT_START: int = 0
const NT_MONSTER: int = 1
const NT_ELITE: int = 2
const NT_SHOP: int = 3
const NT_EVENT: int = 4
const NT_BOSS: int = 5

signal room_selected(room_pos: Vector2i)

@onready var grid_container: GridContainer = $Panel/VBox/GridContainer
@onready var title_label: Label = $Panel/VBox/Title
@onready var close_btn: Button = $Panel/VBox/CloseBtn
@onready var legend_label: Label = $Panel/VBox/LegendLabel

var _grid: Array = []
var _current_room: Vector2i = Vector2i.ZERO
var _cleared_rooms: Array = []  # Array[Vector2i]
var _cell_buttons: Dictionary = {}  # Vector2i → Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_btn.pressed.connect(_on_close)
	legend_label.text = "起=起点 战=战斗 精=精英 商=商店 事=事件 王=Boss\n点击金色高亮房间移动"
	_refresh()

## 初始化小地图数据；若已在场景树中则立即构建网格并刷新
func setup(grid: Array, current_room: Vector2i, cleared_rooms: Array) -> void:
	_grid = grid
	_current_room = current_room
	_cleared_rooms = cleared_rooms
	if is_inside_tree():
		_build_grid()
		_refresh()

## 更新当前房间与已清理房间，并刷新显示
func refresh(current_room: Vector2i, cleared_rooms: Array) -> void:
	_current_room = current_room
	_cleared_rooms = cleared_rooms
	_refresh()

## 构建网格：grid[y][x] 中 y=0(Boss) 在顶部，y=5(起点) 在底部
## GridContainer 按行从上到下填充，故按 y=0..5 顺序填入
func _build_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	_cell_buttons.clear()
	grid_container.columns = 5
	for y in range(6):
		for x in range(5):
			var pos: Vector2i = Vector2i(x, y)
			var room_data = null
			if y < _grid.size() and x < _grid[y].size():
				room_data = _grid[y][x]
			var btn: Button = _create_cell_button(room_data, pos)
			grid_container.add_child(btn)
			_cell_buttons[pos] = btn

## 创建单个格子按钮（56×56），空格子也创建以保持网格对齐
func _create_cell_button(room_data, pos: Vector2i) -> Button:
	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(56, 56)
	btn.gui_input.connect(_on_cell_input.bind(pos))
	return btn

## 刷新所有格子的外观与可点击状态
func _refresh() -> void:
	if _cell_buttons.is_empty():
		return
	var conns: Array = _current_connections()
	for pos in _cell_buttons:
		var btn: Button = _cell_buttons[pos]
		var room_data = null
		if pos.y < _grid.size() and pos.x < _grid[pos.y].size():
			room_data = _grid[pos.y][pos.x]
		var is_current: bool = (pos == _current_room)
		var is_cleared: bool = _cleared_rooms.has(pos)
		var is_adjacent: bool = conns.has(pos)
		_apply_cell_style(btn, room_data, is_current, is_cleared, is_adjacent)

## 应用单个格子的样式（颜色 / 边框 / 文字 / 状态）
func _apply_cell_style(btn: Button, room_data, is_current: bool, is_cleared: bool, is_adjacent: bool) -> void:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	var symbol: String = ""
	var bg: Color = Color(0, 0, 0, 0)
	if room_data != null:
		var t: int = int(room_data.get("type", -1))
		match t:
			NT_START:
				symbol = "起"
				bg = Color(0.3, 0.7, 0.3, 0.9)
			NT_MONSTER:
				symbol = "战"
				bg = Color(0.75, 0.25, 0.2, 0.9)
			NT_ELITE:
				symbol = "精"
				bg = Color(0.95, 0.55, 0.2, 0.9)
			NT_SHOP:
				symbol = "商"
				bg = Color(0.95, 0.8, 0.3, 0.9)
			NT_EVENT:
				symbol = "事"
				bg = Color(0.7, 0.4, 0.9, 0.9)
			NT_BOSS:
				symbol = "王"
				bg = Color(0.55, 0.1, 0.1, 0.95)
			_:
				symbol = ""
				bg = Color(0, 0, 0, 0)
	sb.bg_color = bg
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_right = 6
	sb.corner_radius_bottom_left = 6
	# 边框：当前=白3px，相邻=金2px，其余=墨色1px
	var border_color: Color = Color(0.12, 0.1, 0.08, 0.4)
	var border_w: int = 1
	if is_current:
		border_color = Color(1, 1, 1, 1)
		border_w = 3
	elif is_adjacent:
		border_color = Color(0.95, 0.8, 0.3, 1)
		border_w = 2
	sb.border_color = border_color
	sb.border_width_left = border_w
	sb.border_width_top = border_w
	sb.border_width_right = border_w
	sb.border_width_bottom = border_w
	sb.content_margin_left = 4.0
	sb.content_margin_top = 4.0
	sb.content_margin_right = 4.0
	sb.content_margin_bottom = 4.0
	# 同一 StyleBox 用于四种状态，避免 disabled 默认变灰
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("disabled", sb)
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", Color(0.12, 0.1, 0.08, 1))
	btn.add_theme_color_override("font_hover_color", Color(0.12, 0.1, 0.08, 1))
	btn.add_theme_color_override("font_pressed_color", Color(0.12, 0.1, 0.08, 1))
	btn.add_theme_color_override("font_disabled_color", Color(0.12, 0.1, 0.08, 1))
	# 文字：当前房间显示“你”，其余显示类型符号
	btn.text = "你" if is_current else symbol
	# 已清理（非当前）房间半透明
	btn.modulate.a = 0.4 if (is_cleared and not is_current) else 1.0
	# 仅相邻且未清理的非当前房间可点击（防止重复进入刷奖励）
	btn.disabled = (not is_adjacent) or (is_cleared and not is_current)

## 获取当前房间的连接列表（越界 / 空房间时返回空数组）
func _current_connections() -> Array:
	if _current_room.y < 0 or _current_room.y >= _grid.size():
		return []
	if _current_room.x < 0 or _current_room.x >= _grid[_current_room.y].size():
		return []
	var cell = _grid[_current_room.y][_current_room.x]
	if cell == null:
		return []
	return cell.get("connections", [])

## 格子输入：左键点击且该格在当前房间 connections 中时发出移动信号
func _on_cell_input(event: InputEvent, pos: Vector2i) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 已清理房间不可进入（防止重复刷奖励）
		if _cleared_rooms.has(pos):
			return
		if _current_connections().has(pos):
			room_selected.emit(pos)

func _on_close() -> void:
	UIManager.close_top()
