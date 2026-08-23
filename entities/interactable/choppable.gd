extends Interactable
class_name Choppable

signal depleted

@export var max_health: int = 3
@export var chop_sound: AudioStream

var _health: int

func _ready() -> void:
	_health = max_health

## Contrôle uniquement l'affichage HUD (prompt/réticule) — le déclenchement
## réel du chop passe par receive_tool_hit(), appelé que ce soit interactable
## ou non (voir InteractionController._try_use_tool()).
func can_interact(interactor: Node) -> bool:
	var tool_controller := _get_tool_controller(interactor)
	if tool_controller == null or not tool_controller.can_swing():
		return false
	var tool := tool_controller.get_equipped_tool()
	return tool != null and tool.tool_type == ToolDef.ToolType.CHOP

## Le chop se déclenche au clic (use_tool), cible valide ou non — pas via la
## touche d'interaction générique (E).
func uses_tool_trigger() -> bool:
	return true

func receive_tool_hit(tool: ToolDef) -> void:
	if tool == null or tool.tool_type != ToolDef.ToolType.CHOP:
		return
	if chop_sound:
		SoundManager.play_sfx(chop_sound, global_position)
	_health -= tool.damage
	if _health <= 0:
		depleted.emit()
		queue_free()

func _get_tool_controller(interactor: Node) -> ToolController:
	if interactor is InteractionController:
		return interactor.tool_controller
	return null
