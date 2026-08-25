extends CanvasLayer
class_name PlayerHud

@onready var _crosshair: Crosshair = $Crosshair
@onready var _prompt_label: Label = $PromptLabel
@onready var _hotbar: Hotbar = $Hotbar


func set_targeting(active: bool) -> void:
	_crosshair.set_active(active)


func show_prompt(text: String) -> void:
	_prompt_label.text = text
	_prompt_label.visible = true


func hide_prompt() -> void:
	_prompt_label.visible = false


## Appelé par EquipmentController à chaque changement de slot ou de contenu.
func update_hotbar(active_slot: int, belt: Array[ToolDef], backpack_data: BackpackData) -> void:
	if _hotbar:
		_hotbar.update(active_slot, belt, backpack_data)


## Grise le hotbar quand les mains sont occupées par un objet lourd.
func set_hotbar_dimmed(dimmed: bool) -> void:
	if _hotbar:
		_hotbar.set_dimmed(dimmed)
