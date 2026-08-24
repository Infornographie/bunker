extends Node3D
class_name CarryController

@export var hand_anchor: Node3D

var _carried_item: Node
var _carried_layer: int = 0
var _carried_mask: int = 0

func is_carrying() -> bool:
	return _carried_item != null

func can_carry() -> bool:
	return _carried_item == null

func get_carried_item() -> Node:
	return _carried_item

## item doit être un Interactable (PhysicsBody3D). Freeze/impulsion accédés
## en dynamique (set/call) : voir pattern noté dans STATE.md.
func carry(item: Node3D) -> void:
	if not can_carry() or hand_anchor == null:
		return
	_carried_item = item
	_carried_layer = item.get("collision_layer")
	_carried_mask = item.get("collision_mask")
	item.reparent(hand_anchor)
	item.position = Vector3.ZERO
	item.rotation = Vector3.ZERO
	item.set("collision_layer", 0)
	item.set("collision_mask", 0)
	item.set("freeze", true)

func drop(world_position: Vector3, target_parent: Node) -> void:
	if not is_carrying():
		return
	var item := _carried_item
	_carried_item = null
	item.reparent(target_parent)
	item.global_position = world_position
	item.set("collision_layer", _carried_layer)
	item.set("collision_mask", _carried_mask)
	item.set("freeze", false)
	if item.has_method("apply_central_impulse"):
		item.call("apply_central_impulse", Vector3(0.0, 0.2, 0.0))

## Contrairement à drop(), l'objet porté est détruit plutôt que reposé dans
## le monde — utilisé quand une ressource est livrée à un réceptacle
## (chantier, structure rechargeable...).
func consume() -> void:
	if not is_carrying():
		return
	var item := _carried_item
	_carried_item = null
	item.queue_free()
