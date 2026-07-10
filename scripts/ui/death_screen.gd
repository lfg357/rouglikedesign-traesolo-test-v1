extends CanvasLayer
## 死亡结算屏 · 道陨

@onready var floor_label: Label = $Panel/VBox/StatsContainer/FloorLabel
@onready var kill_label: Label = $Panel/VBox/StatsContainer/KillLabel
@onready var karma_label: Label = $Panel/VBox/StatsContainer/KarmaLabel
@onready var stone_label: Label = $Panel/VBox/StatsContainer/StoneLabel
@onready var restart_btn: Button = $Panel/VBox/BtnContainer/RestartBtn
@onready var menu_btn: Button = $Panel/VBox/BtnContainer/MenuBtn

var _kill_count: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.end_run(false)
	restart_btn.pressed.connect(_on_restart)
	menu_btn.pressed.connect(_on_menu)
	_update_display()

func setup(kill_count: int) -> void:
	_kill_count = kill_count
	if is_inside_tree():
		_update_display()

func _update_display() -> void:
	floor_label.text = "抵达层数: " + str(GameState.current_floor)
	kill_label.text = "击杀数: " + str(_kill_count)
	karma_label.text = "业力获取: +50"
	stone_label.text = "灵石清零"

func _on_restart() -> void:
	GameState.start_run()
	UIManager.close_all()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_menu() -> void:
	get_tree().paused = false
	UIManager.close_all()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
