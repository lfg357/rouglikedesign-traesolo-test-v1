extends CanvasLayer
## 主菜单 · 游戏入口界面

@onready var start_btn: Button = $Panel/VBox/StartBtn
@onready var settings_btn: Button = $Panel/VBox/SettingsBtn
@onready var quit_btn: Button = $Panel/VBox/QuitBtn

func _ready() -> void:
	start_btn.pressed.connect(_on_start)
	settings_btn.pressed.connect(_on_settings)
	quit_btn.pressed.connect(_on_quit)

func _on_start() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_settings() -> void:
	UIManager.open_ui("settings")

func _on_quit() -> void:
	get_tree().quit()
