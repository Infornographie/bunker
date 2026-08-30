extends CanvasLayer
class_name PlayerHud

## Le HUD est redevenu purement informatif depuis que les panneaux vivent
## dans le monde en 3D : réticule, prompt, hotbar. Plus aucune interface
## manipulable ici.

@onready var _crosshair: Crosshair = $Crosshair
@onready var _prompt_label: Label = $PromptLabel
@onready var _hotbar: Hotbar = $Hotbar


func set_targeting(active: bool) -> void:
	_crosshair.set_active(active)


func show_prompt(key: String) -> void:
	_prompt_label.text = tr(key)
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
