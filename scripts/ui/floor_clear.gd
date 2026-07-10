extends CanvasLayer
## 层间结算屏 · 第 X 层通关

signal floor_continued()

@onready var title: Label = $Panel/VBox/Title
@onready var kill_label: Label = $Panel/VBox/ContentHBox/LeftPanel/LeftVBox/KillLabel
@onready var time_label: Label = $Panel/VBox/ContentHBox/LeftPanel/LeftVBox/TimeLabel
@onready var relic_label: Label = $Panel/VBox/ContentHBox/LeftPanel/LeftVBox/RelicLabel
@onready var reaction_label: Label = $Panel/VBox/ContentHBox/LeftPanel/LeftVBox/ReactionLabel
@onready var qi_label: Label = $Panel/VBox/ContentHBox/RightPanel/RightVBox/QiLabel
@onready var stone_label: Label = $Panel/VBox/ContentHBox/RightPanel/RightVBox/StoneLabel
@onready var karma_label: Label = $Panel/VBox/ContentHBox/RightPanel/RightVBox/KarmaLabel
@onready var altar_label: Label = $Panel/VBox/ContentHBox/RightPanel/RightVBox/AltarLabel
@onready var continue_btn: Button = $Panel/VBox/ContinueBtn

var _kill_count: int = 0
var _floor_num: int = 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	continue_btn.pressed.connect(_on_continue)
	_update_display()

func setup(kill_count: int, floor_num: int) -> void:
	_kill_count = kill_count
	_floor_num = floor_num
	if is_inside_tree():
		_update_display()

func _update_display() -> void:
	title.text = "第 " + str(_floor_num) + " 层 · 通关"
	kill_label.text = "本层击杀: " + str(_kill_count)
	time_label.text = "用时: 02:30"
	relic_label.text = "掉落遗物: 青萍剑"
	reaction_label.text = "激活反应: 金生水"
	qi_label.text = "灵气: " + str(GameState.player_qi) + " → 0"
	stone_label.text = "灵石: " + str(GameState.player_spirit_stone) + " (保留)"
	karma_label.text = "业力: +0"
	altar_label.text = "祭坛强化: 清零"

func _on_continue() -> void:
	GameState.on_floor_clear()
	floor_continued.emit()
	UIManager.close_top()
