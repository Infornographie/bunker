extends Node3D
class_name ToolController

signal swing_started
## Émis au point de contact du swing (fin de la phase de frappe). Le système
## d'interaction s'y accroche pour appliquer son effet (dégâts, son...).
signal swing_impact

const ANTICIPATION_OFFSET := Vector3(0.05, 0.08, 0.08)
const ANTICIPATION_ANGLE_DEG: float = 15.0
const STRIKE_ANGLE_DEG: float = -70.0
## Fraction du strike_offset qu'on relâche pendant le petit rebond d'impact,
## avant le retour final au repos — donne le "choc" sans repartir en arrière
## de la position de repos (pas de vrai overshoot, juste un temps de pause).
const RECOIL_RELEASE_RATIO: float = 0.4

@export var default_tool: ToolDef
## Portée par défaut du coup, en mètres, dans l'espace local du controller
## (donc de la caméra). Le swing ne va jamais plus loin que ça même si la
## cible détectée est plus lointaine (portée d'interaction != portée du coup).
## Ne se voit que si un obstacle est plus proche que cette valeur — sinon le
## coup fait toujours son geste par défaut, rien à clamper.
@export var max_reach: float = 0.5

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

## reach_distance : distance réelle (raycast) jusqu'à l'obstacle visé.
## -1 (ou absent) = rien détecté, on utilise MAX_REACH par défaut.
func swing(reach_distance: float = -1.0) -> void:
	if not can_swing():
		return
	_swinging = true
	swing_started.emit()

	var reach: float = max_reach if reach_distance < 0.0 else min(reach_distance, max_reach)
	var rest_transform := _tool_instance.transform

	var anticipation_basis := Basis(Vector3.RIGHT, deg_to_rad(ANTICIPATION_ANGLE_DEG)) * rest_transform.basis
	var anticipation_transform := Transform3D(anticipation_basis, rest_transform.origin + ANTICIPATION_OFFSET)

	# Déplacement avant-bas au point de contact, dans l'espace du
	# ToolController (donc de la caméra) : -Z = vers l'avant, -Y = vers le bas.
	var strike_offset := Vector3(0.0, -0.1, -reach)
	var strike_basis := Basis(Vector3.RIGHT, deg_to_rad(STRIKE_ANGLE_DEG)) * rest_transform.basis
	var strike_transform := Transform3D(strike_basis, rest_transform.origin + strike_offset)

	var recoil_transform := Transform3D(strike_basis, rest_transform.origin + strike_offset * (1.0 - RECOIL_RELEASE_RATIO))

	var d := _current_tool.swing_duration
	var tween := create_tween()
	tween.tween_property(_tool_instance, "transform", anticipation_transform, d * 0.15)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_tool_instance, "transform", strike_transform, d * 0.25)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): swing_impact.emit())
	tween.tween_property(_tool_instance, "transform", recoil_transform, d * 0.15)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_tool_instance, "transform", rest_transform, d * 0.45)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func(): _swinging = false)

func get_equipped_tool() -> ToolDef:
	return _current_tool
