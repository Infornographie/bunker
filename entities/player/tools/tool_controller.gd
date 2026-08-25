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

## Portée par défaut du coup, en mètres, dans l'espace local du controller
## (donc de la caméra). Le swing ne va jamais plus loin que ça même si la
## cible détectée est plus lointaine (portée d'interaction != portée du coup).
@export var max_reach: float = 0.5

var _current_tool: ToolDef
var _tool_instance: Node3D
var _swinging: bool = false
var _visible: bool = true


func get_equipped_tool() -> ToolDef:
	return _current_tool


func equip(tool_def: ToolDef) -> void:
	if tool_def == _current_tool and _tool_instance != null:
		return
	_clear_instance()
	_current_tool = tool_def
	if tool_def == null or tool_def.mesh_scene == null:
		return
	_tool_instance = tool_def.mesh_scene.instantiate()
	add_child(_tool_instance)
	_tool_instance.position = tool_def.hand_position
	_tool_instance.rotation_degrees = tool_def.hand_rotation_degrees
	_tool_instance.visible = _visible


func unequip() -> void:
	_clear_instance()
	_current_tool = null


func set_tool_visible(show: bool) -> void:
	_visible = show
	if _tool_instance:
		_tool_instance.visible = show


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
	var strike_offset := Vector3(0.0, -reach * 0.3, -reach * 0.7)
	var strike_basis := Basis(Vector3.RIGHT, deg_to_rad(STRIKE_ANGLE_DEG)) * rest_transform.basis
	var strike_transform := Transform3D(strike_basis, rest_transform.origin + strike_offset)

	var recoil_offset := strike_offset * (1.0 - RECOIL_RELEASE_RATIO)
	var recoil_basis := Basis(Vector3.RIGHT, deg_to_rad(STRIKE_ANGLE_DEG * 0.6)) * rest_transform.basis
	var recoil_transform := Transform3D(recoil_basis, rest_transform.origin + recoil_offset)

	var duration: float = _current_tool.swing_duration
	var tween := create_tween()
	# Phase 1 — anticipation (recul léger vers le haut).
	tween.tween_property(_tool_instance, "transform", anticipation_transform, duration * 0.25) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	# Phase 2 — frappe (descente rapide vers l'avant).
	tween.tween_property(_tool_instance, "transform", strike_transform, duration * 0.35) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(_on_swing_hit)
	# Phase 3a — rebond d'impact (micro-recul).
	tween.tween_property(_tool_instance, "transform", recoil_transform, duration * 0.1) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	# Phase 3b — retour au repos.
	tween.tween_property(_tool_instance, "transform", rest_transform, duration * 0.3) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(_on_swing_end)


func _on_swing_hit() -> void:
	swing_impact.emit()


func _on_swing_end() -> void:
	_swinging = false


func _clear_instance() -> void:
	if _tool_instance:
		_tool_instance.queue_free()
		_tool_instance = null
