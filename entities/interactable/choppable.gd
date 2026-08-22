extends Interactable
class_name Choppable

signal depleted

@export var max_health: int = 3
@export var chop_sound: AudioStream

var _health: int

func _ready() -> void:
	_health = max_health

func can_interact(interactor: Node) -> bool:
	var tool_controller := _get_tool_controller(interactor)
	if tool_controller == null or not tool_controller.can_swing():
		return false
	var tool := tool_controller.get_equipped_tool()
	return tool != null and tool.tool_type == ToolDef.ToolType.CHOP

func interact(interactor: Node) -> void:
	var tool_controller := _get_tool_controller(interactor)
	if tool_controller == null:
		return
	var tool := tool_controller.get_equipped_tool()
	if tool == null:
		return
	tool_controller.swing()
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
