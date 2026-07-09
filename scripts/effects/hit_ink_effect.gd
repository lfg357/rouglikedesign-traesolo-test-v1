extends Node2D
## 命中特效 · 使用像素美术帧动画

@onready var sprite: AnimatedSprite2D = $Sprite

func _ready() -> void:
	sprite.animation_finished.connect(_on_anim_finished)
	sprite.play("hit")

func _on_anim_finished() -> void:
	queue_free()
