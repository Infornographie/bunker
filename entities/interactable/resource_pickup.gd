extends Interactable
class_name ResourcePickup

@export var resource_def: ResourceDef
@export var amount: int = 1
@export var scatter_impulse: float = 1.0

var _fall_direction: Vector3 = Vector3.ZERO

## Appelé par Choppable._spawn_pickup() avant add_child, pour orienter la
## chute vers l'avant du coup plutôt qu'aléatoirement.
func set_fall_direction(direction: Vector3) -> void:
	_fall_direction = direction

func _ready() -> void:
	var node: Node = self
	if not (node is RigidBody3D):
		return
	set("can_sleep", false)
	var base_direction := _fall_direction
	if base_direction == Vector3.ZERO:
		base_direction = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
	var impulse := (base_direction + Vector3(randf_range(-0.2, 0.2), 0.3, randf_range(-0.2, 0.2))).normalized() * scatter_impulse
	call("apply_central_impulse", impulse)

func can_interact(interactor: Node) -> bool:
	if resource_def == null or resource_def.carry_type != ResourceDef.CarryType.HAND:
		return false
	var controller := _get_carry_controller(interactor)
	return controller != null and controller.can_carry()

func interact(interactor: Node) -> void:
	var controller := _get_carry_controller(interactor)
	if controller == null or not controller.can_carry():
		return
	controller.carry(self)

func _get_carry_controller(interactor: Node) -> CarryController:
	if interactor is InteractionController:
		return interactor.carry_controller
	return null
