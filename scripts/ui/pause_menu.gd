extends CanvasLayer
## 暂停菜单 · Esc 触发由 main.gd 处理，本界面只负责显示与按钮逻辑

var _continue_btn: Button
var _settings_btn: Button
var _main_menu_btn: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_continue_btn = $Panel/VBox/ContinueBtn
	_settings_btn = $Panel/VBox/SettingsBtn
	_main_menu_btn = $Panel/VBox/MainMenuBtn
	if _continue_btn:
		_continue_btn.pressed.connect(_on_continue)
	if _settings_btn:
		_settings_btn.pressed.connect(_on_settings)
	if _main_menu_btn:
		_main_menu_btn.pressed.connect(_on_main_menu)

func _on_continue() -> void:
	UIManager.close_top()

func _on_settings() -> void:
	UIManager.open_ui("settings")

func _on_main_menu() -> void:
	UIManager.close_all()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
