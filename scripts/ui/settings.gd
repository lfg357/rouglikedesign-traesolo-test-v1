extends CanvasLayer
## 设置界面 · 主音量/音效滑块 + 键位说明
## P0 使用静态变量在会话内保存音量

static var master_volume: int = 80
static var sfx_volume: int = 80

var _master_slider: HSlider
var _sfx_slider: HSlider
var _back_btn: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_master_slider = $Panel/VBox/MasterSlider
	_sfx_slider = $Panel/VBox/SfxSlider
	_back_btn = $Panel/VBox/BackBtn
	if _master_slider:
		_master_slider.value = master_volume
		_master_slider.value_changed.connect(_on_master_changed)
	if _sfx_slider:
		_sfx_slider.value = sfx_volume
		_sfx_slider.value_changed.connect(_on_sfx_changed)
	if _back_btn:
		_back_btn.pressed.connect(_on_back)

func _on_master_changed(value: float) -> void:
	master_volume = int(value)

func _on_sfx_changed(value: float) -> void:
	sfx_volume = int(value)

func _on_back() -> void:
	UIManager.close_top()
