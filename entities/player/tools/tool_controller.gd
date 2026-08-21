extends Node3D
class_name ToolController

signal swing_started
## Émis à mi-swing — le futur système de récolte/interaction s'y accrochera
## pour faire son propre raycast. Pas de logique de coupe ici : ce controller
## ne gère que le viewmodel et l'anim, volontairement (Jalon 3 pas fini).
signal swing_impact

@export var default_tool: ToolDef

var _current_tool: ToolDef
var _tool_instance: Node3D
var _swinging: bool = false

func _ready() -> void:
	if default_tool:
		equip(default_tool)

func equip(tool_def: ToolDef) -> void:
	if _tool_instance:
		_tool_instance.queue_free()
	_current_tool = tool_def
	if tool_def == null or tool_def.mesh_scene == null:
		return
	_tool_instance = tool_def.mesh_scene.instantiate()
	add_child(_tool_instance)
	_tool_instance.position = tool_def.hand_position
	_tool_instance.rotation_degrees = tool_def.hand_rotation_degrees

func can_swing() -> bool:
	return _current_tool != null and not _swinging

func swing() -> void:
	if not can_swing():
		return
	_swinging = true
	swing_started.emit()
	var rest_transform := _tool_instance.transform
	var swing_transform := rest_transform.rotated_local(Vector3.RIGHT, deg_to_rad(-70.0))

	var tween := create_tween()
	tween.tween_property(_tool_instance, "transform", swing_transform, _current_tool.swing_duration * 0.4)
	tween.tween_callback(func(): swing_impact.emit())
	tween.tween_property(_tool_instance, "transform", rest_transform, _current_tool.swing_duration * 0.6)
	tween.tween_callback(func(): _swinging = false)
