extends Node2D
## 剑光拖尾 · 挥剑时的蓝色剑气

@onready var sprite: AnimatedSprite2D = $Sprite

func _ready() -> void:
	sprite.animation_finished.connect(_on_anim_finished)
	sprite.play("trail")

func _on_anim_finished() -> void:
	queue_free()
