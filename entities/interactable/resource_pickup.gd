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
	# Prompt automatique depuis le nom de la ressource si non surchargé.
	if resource_def and prompt_key == "interact.prompt.interact":
		prompt_key = resource_def.name_key

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
	if resource_def == null:
		return false
	# Tous les types exigent les mains libres (E est verrouillé par
	# InteractionController quand on porte déjà quelque chose).
	var cc := _get_carry_controller(interactor)
	if cc == null or not cc.can_carry():
		return false
	return true


func interact(interactor: Node) -> void:
	match resource_def.carry_type:
		ResourceDef.CarryType.HAND:
			_carry_physical(interactor)
		ResourceDef.CarryType.SMALL:
			_absorb_small(interactor)
		ResourceDef.CarryType.TOOL:
			_absorb_tool(interactor)


## --- Routage par carry type -------------------------------------------

## HAND : portage physique en main (comportement existant).
func _carry_physical(interactor: Node) -> void:
	var controller := _get_carry_controller(interactor)
	if controller == null or not controller.can_carry():
		return
	controller.carry(self)


## SMALL : poches → sac → débordement en main.
func _absorb_small(interactor: Node) -> void:
	var eq := _get_equipment_controller(interactor)
	if eq and eq.try_store_small(resource_def):
		queue_free()
		return
	# Pas de sac ou sac plein → portage physique comme un objet lourd.
	_carry_physical(interactor)


## TOOL : ceinture → débordement en main.
func _absorb_tool(interactor: Node) -> void:
	var eq := _get_equipment_controller(interactor)
	if eq and resource_def.tool_def and eq.try_store_tool(resource_def.tool_def):
		queue_free()
		return
	_carry_physical(interactor)


## --- Accesseurs interactor --------------------------------------------

func _get_carry_controller(interactor: Node) -> CarryController:
	if interactor is InteractionController:
		return interactor.carry_controller
	return null


func _get_equipment_controller(interactor: Node) -> EquipmentController:
	if interactor is InteractionController:
		return interactor.equipment_controller
	return null
