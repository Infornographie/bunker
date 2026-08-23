extends CanvasLayer
class_name PlayerHud

@onready var _crosshair: Crosshair = $Crosshair
@onready var _prompt_label: Label = $PromptLabel

func set_targeting(active: bool) -> void:
	_crosshair.set_active(active)

func show_prompt(text: String) -> void:
	_prompt_label.text = text
	_prompt_label.visible = true

func hide_prompt() -> void:
	_prompt_label.visible = false
